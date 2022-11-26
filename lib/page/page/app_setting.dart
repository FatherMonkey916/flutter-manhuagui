import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';

/// 设置页-高级设置

class AppSetting {
  const AppSetting({
    required this.timeoutBehavior,
    required this.dlTimeoutBehavior,
    required this.enableLogger,
    required this.usingDownloadedPage,
    required this.defaultMangaOrder,
    required this.defaultAuthorOrder,
  });

  final TimeoutBehavior timeoutBehavior; // 网络请求超时时间
  final TimeoutBehavior dlTimeoutBehavior; // 漫画下载超时时间
  final bool enableLogger; // 记录调试日志
  final bool usingDownloadedPage; // 阅读时载入已下载的页面
  final MangaOrder defaultMangaOrder; // 漫画默认排序方式
  final AuthorOrder defaultAuthorOrder; // 漫画作者默认排序方式

  AppSetting.defaultSetting()
      : this(
          timeoutBehavior: TimeoutBehavior.normal,
          dlTimeoutBehavior: TimeoutBehavior.normal,
          enableLogger: false,
          usingDownloadedPage: true,
          defaultMangaOrder: MangaOrder.byPopular,
          defaultAuthorOrder: AuthorOrder.byPopular,
        );

  AppSetting copyWith({
    TimeoutBehavior? timeoutBehavior,
    TimeoutBehavior? dlTimeoutBehavior,
    bool? enableLogger,
    bool? usingDownloadedPage,
    MangaOrder? defaultMangaOrder,
    AuthorOrder? defaultAuthorOrder,
  }) {
    return AppSetting(
      timeoutBehavior: timeoutBehavior ?? this.timeoutBehavior,
      dlTimeoutBehavior: dlTimeoutBehavior ?? this.dlTimeoutBehavior,
      enableLogger: enableLogger ?? this.enableLogger,
      usingDownloadedPage: usingDownloadedPage ?? this.usingDownloadedPage,
      defaultMangaOrder: defaultMangaOrder ?? this.defaultMangaOrder,
      defaultAuthorOrder: defaultAuthorOrder ?? this.defaultAuthorOrder,
    );
  }

  static AppSetting global = AppSetting.defaultSetting(); // TODO 将 static global 为 AppSetting instance

  static updateGlobalSetting(AppSetting s) {
    global = s;
    if (!s.enableLogger) {
      LogConsolePage.finalize();
    } else if (!LogConsolePage.initialized) {
      LogConsolePage.initialize(globalLogger, bufferSize: LOG_CONSOLE_BUFFER);
      globalLogger.i('initialize LogConsolePage');
    }
  }
}

enum TimeoutBehavior {
  normal,
  long,
  disable,
}

extension TimeoutBehaviorExtension on TimeoutBehavior {
  int toInt() {
    if (this == TimeoutBehavior.normal) {
      return 0;
    }
    if (this == TimeoutBehavior.long) {
      return 1;
    }
    if (this == TimeoutBehavior.disable) {
      return 2;
    }
    return 0;
  }

  static TimeoutBehavior fromInt(int i) {
    if (i == 0) {
      return TimeoutBehavior.normal;
    }
    if (i == 1) {
      return TimeoutBehavior.long;
    }
    if (i == 2) {
      return TimeoutBehavior.disable;
    }
    return TimeoutBehavior.normal;
  }

  Duration? determineDuration({required Duration normal, required Duration long}) {
    if (this == TimeoutBehavior.normal) {
      return normal;
    }
    if (this == TimeoutBehavior.long) {
      return long;
    }
    if (this == TimeoutBehavior.disable) {
      return null;
    }
    return normal;
  }
}

class AppSettingSubPage extends StatefulWidget {
  const AppSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final AppSetting setting;
  final void Function(AppSetting) onSettingChanged;

  @override
  State<AppSettingSubPage> createState() => _AppSettingSubPageState();
}

class _AppSettingSubPageState extends State<AppSettingSubPage> with SettingSubPageStateMixin<AppSetting, AppSettingSubPage> {
  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;
  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;

  @override
  AppSetting get newestSetting => AppSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        usingDownloadedPage: _usingDownloadedPage,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
      );

  @override
  List<Widget> get settingLines => [
        SettingComboBoxView<TimeoutBehavior>(
          title: '网络请求超时时间',
          hint: '当前设置对应的网络连接、发送请求、获取响应的超时时间为：' +
              (_timeoutBehavior == TimeoutBehavior.normal
                  ? '${CONNECT_TIMEOUT / 1000}s + ${SEND_TIMEOUT / 1000}s + ${RECEIVE_TIMEOUT / 1000}s'
                  : _timeoutBehavior == TimeoutBehavior.long
                      ? '${CONNECT_LTIMEOUT / 1000}s + ${SEND_LTIMEOUT / 1000}s + ${RECEIVE_LTIMEOUT / 1000}s'
                      : '无超时时间设置'),
          width: 75,
          value: _timeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _timeoutBehavior = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
          title: '漫画下载超时时间',
          hint: '当前设置对应的漫画下载超时时间为：' +
              (_dlTimeoutBehavior == TimeoutBehavior.normal
                  ? '${DOWNLOAD_HEAD_TIMEOUT / 1000}s + ${DOWNLOAD_IMAGE_TIMEOUT / 1000}s'
                  : _dlTimeoutBehavior == TimeoutBehavior.long
                      ? '${DOWNLOAD_HEAD_LTIMEOUT / 1000}s + ${DOWNLOAD_IMAGE_LTIMEOUT / 1000}s'
                      : '无超时时间设置'),
          width: 75,
          value: _dlTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _dlTimeoutBehavior = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '记录调试日志',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '阅读时载入已下载的页面',
          hint: '部分安卓系统可能会因为文件访问权限的问题而出现无法阅读漫画的情况。\n\n若存在上述问题，请将此选项关闭，从而在阅读漫画时禁用文件访问。',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<MangaOrder>(
          title: '漫画默认排序方式',
          value: _defaultMangaOrder,
          values: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
          builder: (s) => Text(s.toTitle()),
          onChanged: (s) {
            _defaultMangaOrder = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AuthorOrder>(
          title: '漫画作者默认排序方式',
          value: _defaultAuthorOrder,
          values: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
          builder: (s) => Text(s.toTitle()),
          onChanged: (s) {
            _defaultAuthorOrder = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ];
}
