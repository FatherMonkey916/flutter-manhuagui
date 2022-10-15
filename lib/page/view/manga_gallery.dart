import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/extended_gallery.dart';
import 'package:photo_view/photo_view.dart';

// TODO

/// 漫画画廊展示，在 [MangaViewerPage] 使用
class MangaGalleryView extends StatefulWidget {
  const MangaGalleryView({
    Key? key,
    required this.imageCount,
    required this.imageUrls,
    required this.preloadPagesCount,
    required this.reverseScroll,
    required this.viewportFraction,
    required this.slideWidthRatio,
    required this.onPageChanged, // without extra pages, starts from 1
    this.initialImageIndex = 1, // without extra pages, starts from 1
    this.onCenterAreaTapped,
    required this.firstPageBuilder,
    required this.lastPageBuilder,
    required this.onSaveImage, // without extra pages, starts from 1
    required this.onShareImage, // without extra pages, starts from 1
  }) : super(key: key);

  final int imageCount;
  final List<String> imageUrls;
  final int preloadPagesCount;
  final bool reverseScroll;
  final double viewportFraction;
  final double slideWidthRatio;
  final void Function(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) onPageChanged;
  final int initialImageIndex;
  final void Function()? onCenterAreaTapped;
  final Widget Function(BuildContext) firstPageBuilder;
  final Widget Function(BuildContext) lastPageBuilder;
  final void Function(int imageIndex) onSaveImage;
  final void Function(int imageIndex) onShareImage;

  @override
  State<MangaGalleryView> createState() => MangaGalleryViewState();
}

class MangaGalleryViewState extends State<MangaGalleryView> {
  final _galleryKey = GlobalKey<ExtendedPhotoGalleryViewState>();
  late var _controller = PageController(
    initialPage: widget.initialImageIndex - 1 + 1, // without extra pages, starts from 0
    viewportFraction: widget.viewportFraction,
  );

  // current page index, with extra pages, starts from 0.
  var _currentPageIndex = 0;

  // current image index, without extra pages, starts from 0.
  int get _currentImageIndex => (_currentPageIndex - 1).clamp(0, widget.imageCount - 1);

  @override
  void didUpdateWidget(covariant MangaGalleryView oldWidget) {
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      var oldController = _controller;
      _controller = PageController(
        initialPage: _currentPageIndex, // initial to current page
        viewportFraction: widget.viewportFraction,
      );
      WidgetsBinding.instance?.addPostFrameCallback((_) => oldController.dispose());
    }
    super.didUpdateWidget(oldWidget);
  }

  Offset? _pointerDownPosition;
  bool _pointerMoved = false;
  var _longPressed = false;

  void _onPointerDown(Offset pos) {
    _pointerDownPosition = pos;
    _longPressed = false;

    Future.delayed(Duration(milliseconds: 500), () async {
      if (_pointerDownPosition != null && !_pointerMoved) {
        // tapped down, no swiped
        _longPressed = true;
        await _onLongPressed();

        // restore
        _pointerDownPosition = null;
        _pointerMoved = false;
        _longPressed = false;
      }
    });
  }

  void _onPointerMove(Offset pos) {
    _pointerMoved = true; // _pointerDownPosition != pos
  }

  void _onPointerUp(Offset pos) {
    if (_pointerDownPosition != null && !_pointerMoved && !_longPressed) {
      // tapped down, no swiped, no long pressed
      var width = MediaQuery.of(context).size.width;
      if (pos.dx < width * widget.slideWidthRatio) {
        _jumpToPage(!widget.reverseScroll ? _currentPageIndex - 1 : _currentPageIndex + 1); // 上一页 / 下一页(反)
      } else if (pos.dx > width * (1 - widget.slideWidthRatio)) {
        _jumpToPage(!widget.reverseScroll ? _currentPageIndex + 1 : _currentPageIndex - 1); // 下一页 / 上一页(反)
      } else {
        widget.onCenterAreaTapped?.call();
      }
    }

    // restore
    _pointerDownPosition = null;
    _pointerMoved = false;
    _longPressed = false;
  }

  Future<void> _onLongPressed() async {
    await showPopupListMenu(
      context: context,
      title: Text('第${_currentImageIndex + 1}页'),
      barrierDismissible: true,
      items: [
        IconTextMenuItem(
          iconText: IconText.simple(Icons.refresh, '重新加载'),
          action: () => _galleryKey.currentState?.reload(_currentImageIndex), // without extra pages, starts from 0
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.download, '保存该页'),
          action: () => widget.onSaveImage.call(_currentImageIndex + 1),
        ),
        IconTextMenuItem(
          iconText: IconText.simple(Icons.share, '分享该页'),
          action: () => widget.onShareImage.call(_currentImageIndex + 1),
        ),
      ],
    );
  }

  void _jumpToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= widget.imageCount + 1) {
      _controller.jumpToPage(pageIndex);
    }
  }

  // jump to image page, without extra pages, starts from 1.
  void jumpToImage(int imageIndex) {
    if (imageIndex >= 1 && imageIndex <= widget.imageCount) {
      _controller.jumpToPage(imageIndex + 1 - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedPhotoGalleryView(
      key: _galleryKey,
      pageController: _controller,
      imageCount: widget.imageCount,
      preloadPagesCount: widget.preloadPagesCount,
      reverse: widget.reverseScroll,
      backgroundDecoration: BoxDecoration(color: Colors.black),
      scrollPhysics: BouncingScrollPhysics(),
      keepViewportWidth: true,
      onPageChanged: (idx) {
        _currentPageIndex = idx;
        widget.onPageChanged.call(_currentImageIndex + 1, idx == 0, idx == widget.imageCount + 1);
      },
      // ****************************************************************
      // 漫画页
      // ****************************************************************
      imagePageBuilder: (c, idx) => ReloadablePhotoViewGalleryPageOptions(
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained / 2,
        maxScale: PhotoViewComputedScale.covered * 2,
        filterQuality: FilterQuality.high,
        onTapDown: (c, d, v) => _onPointerDown(d.globalPosition),
        onTapUp: (c, d, v) => _onPointerUp(d.globalPosition),
        imageProviderBuilder: (_) => LocalOrCachedNetworkImageProvider.fromNetwork(
          url: widget.imageUrls[idx],
          headers: {
            'User-Agent': USER_AGENT,
            'Referer': REFERER,
          },
        ),
        loadingBuilder: (_, ev) => Listener(
          onPointerDown: (e) => _onPointerDown(e.position),
          onPointerMove: (e) => _onPointerMove(e.position),
          onPointerUp: (e) => _onPointerUp(e.position),
          child: ImageLoadingView(
            title: (_currentImageIndex + 1).toString(),
            event: ev,
          ),
        ),
        errorBuilder: (_, __, ___) => Listener(
          onPointerDown: (e) => _onPointerDown(e.position),
          onPointerMove: (e) => _onPointerMove(e.position),
          onPointerUp: (e) => _onPointerUp(e.position),
          child: ImageLoadFailedView(
            title: (_currentImageIndex + 1).toString(),
          ),
        ),
      ),
      onPointerMove: (e) => _onPointerMove(e.position) /* <<< */,
      // ****************************************************************
      // 首页和尾页
      // ****************************************************************
      firstPageBuilder: (c) => Container(
        color: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.firstPageBuilder.call(c),
      ),
      lastPageBuilder: (c) => Container(
        color: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
          maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
        ),
        child: widget.lastPageBuilder.call(c),
      ),
    );
  }
}

class ImageLoadingView extends StatelessWidget {
  const ImageLoadingView({
    Key? key,
    required this.title,
    required this.event,
  }) : super(key: key);

  final String title;
  final ImageChunkEvent? event;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 45, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Container(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: (event == null || (event!.expectedTotalBytes ?? 0) == 0) ? null : event!.cumulativeBytesLoaded / event!.expectedTotalBytes!,
              ),
            ),
          ),
          Text(
            event == null
                ? ''
                : (event!.expectedTotalBytes ?? 0) == 0
                    ? filesize(event!.cumulativeBytesLoaded)
                    : '${filesize(event!.cumulativeBytesLoaded)} / ${filesize(event!.expectedTotalBytes!)}',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ImageLoadFailedView extends StatelessWidget {
  const ImageLoadFailedView({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical,
        maxWidth: MediaQuery.of(context).size.width - MediaQuery.of(context).padding.horizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 45, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Container(
              width: 50,
              height: 50,
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
