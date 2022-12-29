import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/general_line.dart';

/// 漫画阅读历史行，在 [HistorySubPage] 使用
class MangaHistoryLineView extends StatelessWidget {
  const MangaHistoryLineView({
    Key? key,
    required this.history,
    required this.onLongPressed,
  }) : super(key: key);

  final MangaHistory history;
  final Function()? onLongPressed;

  @override
  Widget build(BuildContext context) {
    void onPressed() {
      Navigator.of(context).push(
        CustomPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: history.mangaId,
            title: history.mangaTitle,
            url: history.mangaUrl,
          ),
        ),
      );
    }

    if (!history.read) {
      return GeneralLineView(
        imageUrl: history.mangaCover,
        title: history.mangaTitle,
        icon1: null,
        text1: null,
        icon2: Icons.notes,
        text2: '未开始阅读',
        icon3: Icons.access_time,
        text3: '浏览于 ${history.formattedLastTime}',
        onPressed: onPressed,
        onLongPressed: onLongPressed,
      );
    }
    return GeneralLineView(
      imageUrl: history.mangaCover,
      title: history.mangaTitle,
      icon1: null,
      text1: null,
      icon2: Icons.import_contacts,
      text2: '阅读至 ${history.chapterTitle} 第${history.chapterPage}页',
      icon3: Icons.access_time,
      text3: '阅读于 ${history.formattedLastTime}',
      onPressed: onPressed,
      onLongPressed: onLongPressed,
    );
  }
}
