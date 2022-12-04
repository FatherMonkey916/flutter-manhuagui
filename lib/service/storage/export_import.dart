import 'dart:convert';
import 'dart:io' show File, Directory;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/service/db/db_manager.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:manhuagui_flutter/service/prefs/search_history.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';
import 'package:sqflite/sqflite.dart';

// ====
// path
// ====

Future<String> _getDataDirectoryPath([String? name]) async {
  var directoryPath = await lowerThanAndroidR()
      ? await getPublicStorageDirectoryPath() // /storage/emulated/0/Manhuagui/manhuagui_data/...
      : await getPrivateStorageDirectoryPath(); // /storage/emulated/0/android/com.aoihosizora.manhuagui/files/manhuagui_data/...
  if (name != null) {
    return PathUtils.joinPath([directoryPath, 'manhuagui_data', name]);
  }
  return PathUtils.joinPath([directoryPath, 'manhuagui_data']);
}

Future<String> _getDataFilePath(String name, {bool isDB = false, bool isPrefs = false}) async {
  if (isDB) {
    return PathUtils.joinPath([await _getDataDirectoryPath(name), 'data.db']);
  }
  if (isPrefs) {
    return PathUtils.joinPath([await _getDataDirectoryPath(name), 'data.json']);
  }
  throw ArgumentError('Invalid usage for _getDataFilePath');
}

Future<List<String>> getImportDataNames() async {
  try {
    var directory = Directory(await _getDataDirectoryPath()); // /storage/emulated/0/.../manhuagui_data
    if (!(await directory.exists())) {
      return [];
    }
    var directories = await directory.list().toList();
    var names = directories.map((d) => PathUtils.getBasename(d.path)).toList();
    names.sort((i, j) => i.compareTo(j));
    return names;
  } catch (e, s) {
    globalLogger.e('getImportDataNames', e, s);
    return [];
  }
}

// ======
// export
// ======

Future<String?> exportData(List<ExportDataType> types) async {
  try {
    var timeToken = getTimestampTokenForFilename(DateTime.now(), 'yyyy-MM-dd-HH-mm-ss-SSS');
    var dbFilePath = await _getDataFilePath(timeToken, isDB: true);
    var prefsFilePath = await _getDataFilePath(timeToken, isPrefs: true);
    var dbFile = File(dbFilePath);
    var prefsFile = File(prefsFilePath);

    var ok1 = await _exportDB(dbFile, types);
    var ok2 = await _exportPrefs(prefsFile, types);
    if (!ok1 || !ok2) {
      var dataDirectory = Directory(await _getDataDirectoryPath());
      if (await dataDirectory.exists()) {
        await dataDirectory.delete(recursive: true);
      }
      globalLogger.w('exportData, exportDB: $ok1, exportPrefs: $ok2');
      return null;
    }

    return PathUtils.getDirname(dbFilePath);
  } catch (e, s) {
    globalLogger.e('exportData', e, s);
    return null;
  }
}

Future<bool> _exportDB(File dbFile, List<ExportDataType> types) async {
  final db = await DBManager.instance.getDB();
  var anotherDB = await DBManager.instance.getAnotherDB(dbFile.path);

  var ok = await db.safeTransaction(
    (txn, rollback) async {
      // read histories
      if (types.contains(ExportDataType.readHistories)) {
        var rows = await txn.copyTo(anotherDB, HistoryDao.tableName, HistoryDao.columns);
        if (rows == null) {
          return false;
        }
      }
      // download records
      if (types.contains(ExportDataType.downloadRecords)) {
        var rows = await txn.copyTo(anotherDB, DownloadDao.mangaTableName, DownloadDao.mangaColumns);
        if (rows == null) {
          return false;
        }
        rows = await txn.copyTo(anotherDB, DownloadDao.chapterTableName, DownloadDao.chapterColumns);
        if (rows == null) {
          return false;
        }
      }
      return true;
    },
    exclusive: true,
  );
  ok ??= false;

  await anotherDB.close();
  return ok;
}

Future<bool> _exportPrefs(File prefsFile, List<ExportDataType> types) async {
  final prefs = await PrefsManager.instance.loadPrefs();
  var anotherMap = <String, dynamic>{};

  var ok = await () async {
    // search histories
    if (types.contains(ExportDataType.searchHistories)) {
      var rows = await prefs.copyTo(anotherMap, SearchHistoryPrefs.keys);
      if (rows == null) {
        return false;
      }
    }
    // app setting
    if (types.contains(ExportDataType.appSetting)) {
      var rows = await prefs.copyTo(anotherMap, AppSettingPrefs.keys);
      if (rows == null) {
        return false;
      }
    }
    return true;
  }();

  if (ok) {
    var encoder = JsonEncoder.withIndent('  ');
    prefsFile.writeAsString(encoder.convert(anotherMap));
  }
  return ok;
}

// ======
// import
// ======

Future<List<ExportDataType>?> importData(String name) async {
  try {
    var dbFilePath = await _getDataFilePath(name, isDB: true);
    var prefsFilePath = await _getDataFilePath(name, isPrefs: true);
    var dbFile = File(dbFilePath);
    var prefsFile = File(prefsFilePath);

    final db = await DBManager.instance.getDB();
    var types = await db.safeTransaction<List<ExportDataType>?>(
      (txn, rollback) async {
        var types1 = await _importDB(dbFile, txn);
        var types2 = await _importPrefs(prefsFile);
        if (types1 == null || types2 == null) {
          globalLogger.w('importData, importDB: ${types1 != null}, importPrefs: ${types2 != null}');
          rollback(msg: 'importData');
          return null;
        }
        return [...types1, ...types2];
      },
      exclusive: true,
    );

    return types;
  } catch (e, s) {
    globalLogger.e('importData', e, s);
    return null;
  }
}

Future<List<ExportDataType>?> _importDB(File dbFile, Transaction txn) async {
  if (!(await dbFile.exists())) {
    return [];
  }

  var anotherDB = await DBManager.instance.getAnotherDB(dbFile.path);
  var historyRows = await anotherDB.copyTo(txn, HistoryDao.tableName, HistoryDao.columns) ?? 0;
  var downloadMangaRows = await anotherDB.copyTo(txn, DownloadDao.mangaTableName, DownloadDao.mangaColumns) ?? 0;
  var _ = await anotherDB.copyTo(txn, DownloadDao.chapterTableName, DownloadDao.chapterColumns);

  return [
    if (historyRows > 0) ExportDataType.readHistories,
    if (downloadMangaRows > 0) ExportDataType.downloadRecords,
  ];
}

Future<List<ExportDataType>?> _importPrefs(File prefsFile) async {
  if (!(await prefsFile.exists())) {
    return [];
  }

  final prefs = await PrefsManager.instance.loadPrefs();
  Map<String, dynamic> anotherMap;
  try {
    var content = await prefsFile.readAsString();
    anotherMap = json.decode(content) as Map<String, dynamic>;
  } catch (e, s) {
    globalLogger.e('_importPrefs', e, s);
    return null;
  }

  var historyRows = await anotherMap.copyTo(prefs, SearchHistoryPrefs.keys) ?? 0;
  var settingRows = await anotherMap.copyTo(prefs, AppSettingPrefs.keys) ?? 0;
  if (settingRows > 0) {
    await AppSettingPrefs.loadAllSettings();
  }

  return [
    if (historyRows > 0) ExportDataType.searchHistories,
    if (settingRows > 0) ExportDataType.appSetting,
  ];
}
