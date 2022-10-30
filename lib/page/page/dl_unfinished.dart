import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/view/download_chapter_line.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';

/// 章节下载管理页-未完成

class DlUnfinishedSubPage extends StatefulWidget {
  const DlUnfinishedSubPage({
    Key? key,
    required this.innerController,
    required this.outerController,
    required this.injectorHandler,
    required this.mangaEntity,
    required this.downloadTask,
    required this.invertOrder,
    required this.history,
    required this.onChapterPressed,
  }) : super(key: key);

  final ScrollController innerController;
  final ScrollController outerController;
  final SliverOverlapAbsorberHandle injectorHandler;
  final DownloadedManga mangaEntity;
  final DownloadMangaQueueTask? downloadTask;
  final bool invertOrder;
  final MangaHistory? history;
  final void Function(int cid) onChapterPressed;

  @override
  State<DlUnfinishedSubPage> createState() => _DlUnfinishedSubPageState();
}

class _DlUnfinishedSubPageState extends State<DlUnfinishedSubPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var unfinished = widget.mangaEntity.downloadedChapters.where((el) => !el.succeeded);
    // TODO Line，加进度条，长按弹出选项（目前与上面完全一样）
    return Scaffold(
      body: ScrollbarWithMore(
        controller: widget.innerController,
        interactive: true,
        crossAxisMargin: 2,
        child: CustomScrollView(
          controller: widget.innerController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: widget.injectorHandler,
            ),
            if (unfinished.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  child: Center(
                    child: Text(
                      '暂无章节',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
              ),
            if (unfinished.isNotEmpty)
              SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    for (var chapter in unfinished)
                      Container(
                        color: Colors.white,
                        child: DownloadChapterLineView(
                          chapterEntity: chapter,
                          downloadTask: widget.downloadTask,
                          onPressed: () => widget.onChapterPressed.call(chapter.chapterId),
                          onLongPressed: () => Fluttertoast.showToast(msg: 'TODO ${chapter.chapterId}'), // TODO
                        ),
                      )
                  ].separate(
                    Divider(height: 0, thickness: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: ScrollAnimatedFab(
        scrollController: widget.innerController,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => widget.outerController.scrollToTop(),
        ),
      ),
    );
  }
}
