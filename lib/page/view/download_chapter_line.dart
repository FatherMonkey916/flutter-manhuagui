import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/storage/download_manga.dart';

class DownloadChapterLineView extends StatelessWidget {
  const DownloadChapterLineView({
    Key? key,
    required this.chapterEntity,
    required this.downloadTask,
    required this.onPressed,
    required this.onLongPressed,
  }) : super(key: key);

  final DownloadedChapter chapterEntity;
  final DownloadMangaQueueTask? downloadTask;
  final void Function() onPressed;
  final void Function()? onLongPressed;

  Widget _buildGeneral({
    required BuildContext context,
    required String title,
    required String subTitle,
    required double? progress,
    required IconData icon,
    required bool disabled,
  }) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title),
                      Text(subTitle),
                    ],
                  ),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress,
                    color: disabled
                        ? Colors.grey // chapter downloading is unavailable
                        : Theme.of(context).progressIndicatorTheme.color,
                    backgroundColor: disabled
                        ? Colors.grey[300] // chapter downloading is unavailable
                        : Theme.of(context).progressIndicatorTheme.linearTrackColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(
                icon,
                size: 20,
                color: !disabled ? Theme.of(context).iconTheme.color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      onTap: !disabled ? onPressed : null,
      onLongPress: !disabled ? onLongPressed : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    var progress = DownloadChapterLineProgress.fromEntityAndTask(entity: chapterEntity, task: downloadTask);

    // !!!
    final title = '【${chapterEntity.chapterGroup}】${chapterEntity.chapterTitle}';
    String subTitle;
    final progressText = '${progress.triedPageCount}/${progress.totalPageCount}';
    double? progressValue = progress.totalPageCount == 0 ? 0.0 : progress.triedPageCount / progress.totalPageCount;
    IconData icon;
    switch (progress.status) {
      case DownloadChapterLineStatus.waiting:
        subTitle = '$progressText (等待下载中)';
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.preparing:
        subTitle = '$progressText (正在获取章节信息)';
        progressValue = null;
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.downloading:
        subTitle = '下载中，$progressText';
        icon = Icons.pause;
        break;
      case DownloadChapterLineStatus.pausing:
        subTitle = '$progressText (暂停中)';
        progressValue = null;
        icon = Icons.block;
        break;
      case DownloadChapterLineStatus.paused:
        subTitle = '$progressText (已暂停)';
        icon = Icons.play_arrow;
        break;
      case DownloadChapterLineStatus.succeeded:
        subTitle = '已完成，$progressText';
        icon = Icons.file_download_done;
        break;
      case DownloadChapterLineStatus.failed:
        subTitle = '$progressText (${progress.failedPageCount} 页未完成)';
        icon = Icons.priority_high;
        break;
    }

    return _buildGeneral(
      context: context,
      title: title,
      subTitle: subTitle,
      progress: progressValue,
      icon: !progress.isMangaDownloading ? Icons.block : icon,
      disabled: !progress.isMangaDownloading || progress.status == DownloadChapterLineStatus.pausing,
    );
  }
}

enum DownloadChapterLineStatus {
  // 队列中
  waiting, // useEntity
  preparing, // useEntity
  downloading, // useTask
  pausing, // preparing (useEntity) / downloading (useTask)

  // 已结束
  paused, // useEntity
  succeeded, // useEntity
  failed, // useEntity
}

class DownloadChapterLineProgress {
  const DownloadChapterLineProgress({
    required this.status,
    required this.isMangaDownloading,
    required this.totalPageCount,
    required this.triedPageCount,
    required this.failedPageCount,
  });

  final DownloadChapterLineStatus status;
  final bool isMangaDownloading;
  final int totalPageCount;
  final int triedPageCount;
  final int failedPageCount;

  // !!!
  static DownloadChapterLineProgress fromEntityAndTask({required DownloadedChapter entity, required DownloadMangaQueueTask? task}) {
    assert(task == null || task.mangaId == entity.mangaId);
    DownloadChapterLineStatus status;

    var isMangaDownloading = task != null && !task.succeeded && task.mangaId == entity.mangaId && !task.canceled;
    if (task != null && !task.succeeded && task.mangaId == entity.mangaId && task.progress.startedChapters != null) {
      if (task.canceled) {
        if (task.progress.currentChapterId == entity.chapterId) {
          status = DownloadChapterLineStatus.pausing; // pause when preparing or downloading
        } else {
          status = DownloadChapterLineStatus.paused; // >>>
        }
      } else {
        if (task.progress.currentChapterId == entity.chapterId) {
          if (task.progress.currentChapter == null) {
            status = DownloadChapterLineStatus.preparing;
          } else {
            status = DownloadChapterLineStatus.downloading;
          }
        } else if (task.progress.startedChapters!.any((el) => el?.cid == entity.chapterId)) {
          status = DownloadChapterLineStatus.waiting;
        } else {
          status = DownloadChapterLineStatus.paused; // >>>
        }
      }
    } else {
      status = DownloadChapterLineStatus.paused; // >>>
    }
    if (status == DownloadChapterLineStatus.paused) {
      if (entity.triedPageCount != entity.totalPageCount) {
        status = DownloadChapterLineStatus.paused;
      } else if (entity.successPageCount == entity.totalPageCount) {
        status = DownloadChapterLineStatus.succeeded;
      } else {
        status = DownloadChapterLineStatus.failed;
      }
    }

    var useTask = false;
    if (status == DownloadChapterLineStatus.downloading) {
      useTask = true;
    } else if (status == DownloadChapterLineStatus.pausing && task!.progress.currentChapterId == entity.chapterId && task.progress.currentChapter != null) {
      useTask = true;
    }
    if (useTask) {
      return DownloadChapterLineProgress(
        status: status,
        isMangaDownloading: isMangaDownloading,
        totalPageCount: task!.progress.currentChapter!.pageCount,
        triedPageCount: task.progress.triedChapterPageCount ?? 0,
        failedPageCount: (task.progress.triedChapterPageCount ?? 0) - (task.progress.successChapterPageCount ?? 0),
      );
    }
    return DownloadChapterLineProgress(
      status: status,
      isMangaDownloading: isMangaDownloading,
      totalPageCount: entity.totalPageCount,
      triedPageCount: entity.triedPageCount,
      failedPageCount: entity.triedPageCount - entity.successPageCount,
    );
  }
}
