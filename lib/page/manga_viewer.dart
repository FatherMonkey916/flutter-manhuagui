import 'dart:async' show Timer;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:battery_info/battery_info_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/comments.dart';
import 'package:manhuagui_flutter/page/page/view_extra.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/page/view_toc.dart';
import 'package:manhuagui_flutter/page/view/manga_gallery.dart';
import 'package:manhuagui_flutter/service/db/history.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/natives/share.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:wakelock/wakelock.dart';

// TODO

/// 漫画章节阅读页
class MangaViewerPage extends StatefulWidget {
  const MangaViewerPage({
    Key? key,
    required this.mid,
    required this.cid,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
    required this.chapterGroups,
    this.initialPage = 1, // starts from 1
  }) : super(key: key);

  final int mid;
  final int cid;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;
  final List<MangaChapterGroup> chapterGroups;
  final int initialPage;

  @override
  _MangaViewerPageState createState() => _MangaViewerPageState();
}

const _kSlideWidthRatio = 0.2; // 点击跳转页面的区域比例
const _kViewportFraction = 1.08; // 页面间隔
const _kAnimationDuration = Duration(milliseconds: 150); // 动画时长
const _kOverlayAnimationDuration = Duration(milliseconds: 300); // SystemUI 动画时长

class _MangaViewerPageState extends State<MangaViewerPage> with AutomaticKeepAliveClientMixin {
  final _mangaGalleryViewKey = GlobalKey<MangaGalleryViewState>();
  var _setting = ViewSetting.defaultSetting();
  Timer? _timer;
  var _currentTime = '00:00';
  var _networkInfo = 'WIFI';
  var _batteryInfo = '0%';

  @override
  void initState() {
    super.initState();

    // data related
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());

    // setting and screen related
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      // initialize in async manner
      _ScreenHelper.initialize(
        context: context,
        setState: () => mountedSetState(() {}),
      );

      // setting
      _setting = await ViewSettingPrefs.getSetting();
      if (mounted) setState(() {});

      // apply settings
      await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
      await _ScreenHelper.setSystemUIWhenEnter(fullscreen: _setting.fullscreen);
    });

    // timer related
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Future<void> getInfo() async {
        var now = DateTime.now();
        _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        var conn = await Connectivity().checkConnectivity();
        _networkInfo = conn == ConnectivityResult.wifi ? 'WIFI' : (conn == ConnectivityResult.mobile ? '移动网络' : '无网络');
        var battery = await BatteryInfoPlugin().androidBatteryInfo;
        _batteryInfo = '电源${(battery?.batteryLevel ?? 0).clamp(0, 100)}%';
        if (mounted) setState(() {});
      }

      getInfo();
      var now = DateTime.now();
      var nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
      if (mounted && (_timer == null || !_timer!.isActive)) {
        Timer(nextMinute.difference(now), () {
          _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
            if (_timer != null && _timer!.isActive) {
              await getInfo();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  var _loading = true;
  MangaChapter? _data;
  int? _initialPage;
  var _error = '';

  Future<void> _loadData() async {
    _loading = true;
    if (mounted) setState(() {});

    final client = RestClient(DioManager.instance.dio);

    // 1. 异步更新章节阅读记录
    if (AuthManager.instance.logined) {
      Future.microtask(() async {
        try {
          await client.recordManga(token: AuthManager.instance.token, mid: widget.mid, cid: widget.cid);
        } catch (_) {}
      });
    }

    try {
      // 2. 获取章节数据
      var result = await client.getMangaChapter(mid: widget.mid, cid: widget.cid);
      _data = null;
      _error = '';
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = result.data;

      // 3. 指定起始页
      _initialPage = widget.initialPage.clamp(1, _data!.pageCount);
      _currentPage = _initialPage!;
      _progressValue = _initialPage!;

      // 4. 异步更新浏览历史
      _updateHistory();
    } catch (e, s) {
      _data = null;
      _error = wrapError(e, s).text;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateHistory() async {
    if (_data != null) {
      await HistoryDao.addOrUpdateHistory(
        username: AuthManager.instance.username,
        history: MangaHistory(
          mangaId: widget.mid,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          chapterId: _data!.cid,
          chapterTitle: _data!.title,
          chapterPage: _currentPage,
          lastTime: DateTime.now(),
        ),
      );
      EventBusManager.instance.fire(HistoryUpdatedEvent());
    }
  }

  var _currentPage = 1; // image page only, starts from 1
  var _progressValue = 1; // image page only, starts from 1
  var _inExtraPage = true;

  void _onPageChanged(int imageIndex, bool inFirstExtraPage, bool inLastExtraPage) {
    _currentPage = imageIndex;
    _progressValue = imageIndex;
    var inExtraPage = inFirstExtraPage || inLastExtraPage;
    if (inExtraPage != _inExtraPage) {
      _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
      _inExtraPage = inExtraPage;
    }
    if (mounted) setState(() {});
  }

  void _onSliderChanged(double p) {
    _progressValue = p.toInt();
    _mangaGalleryViewKey.currentState?.jumpToImage(_progressValue);
    if (mounted) setState(() {});
  }

  void _gotoChapter({required bool gotoPrevious}) {
    if ((gotoPrevious && _data!.prevCid == 0) || (!gotoPrevious && _data!.nextCid == 0)) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(gotoPrevious ? '上一章节' : '下一章节'),
          content: Text(gotoPrevious ? '没有上一章节了。' : '没有下一章节了。'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // pop this page, should not use maybePop
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => MangaViewerPage(
          mid: widget.mid,
          mangaTitle: widget.mangaTitle,
          mangaCover: widget.mangaCover,
          mangaUrl: widget.mangaUrl,
          chapterGroups: widget.chapterGroups,
          cid: gotoPrevious ? _data!.prevCid : _data!.nextCid,
          initialPage: 1,
        ),
      ),
    );
  }

  var _showHelpRegion = false; // 显示区域提示

  Future<void> _onSettingPressed() {
    var setting = _setting.copyWith();
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('阅读设置'),
        content: ViewSettingSubPage(
          setting: setting,
          onSettingChanged: (s) => setting = s,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: Text('操作'),
            onPressed: () {
              Navigator.of(c).pop();
              _showHelpRegion = true;
              if (mounted) setState(() {});
              _ScreenHelper.toggleAppBarVisibility(show: false, fullscreen: _setting.fullscreen);
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text('确定'),
                onPressed: () async {
                  Navigator.of(c).pop();
                  _setting = setting;
                  if (mounted) setState(() {});
                  await ViewSettingPrefs.setSetting(_setting);

                  // apply settings
                  await _ScreenHelper.toggleWakelock(enable: _setting.keepScreenOn);
                  await _ScreenHelper.setSystemUIWhenSettingChanged(fullscreen: _setting.fullscreen);
                },
              ),
              TextButton(
                child: Text('取消'),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTocPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: ViewTocSubPage(
            mid: widget.mid,
            mangaTitle: widget.mangaTitle,
            mangaCover: widget.mangaCover,
            mangaUrl: widget.mangaUrl,
            groups: widget.chapterGroups,
            highlightedChapter: widget.cid,
            predicate: (cid) {
              if (cid == _data!.cid) {
                Fluttertoast.showToast(msg: '当前正在阅读 ${_data!.title}');
                return false;
              }
              Navigator.of(c).pop(); // bottom sheet
              Navigator.of(context).pop(); // this page, should not use maybePop
              return true;
            },
          ),
        ),
      ),
    );
  }

  void _onCommentsPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - Theme.of(context).appBarTheme.toolbarHeight!,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: CommentsPage(
            mid: _data!.mid,
            title: _data!.mangaTitle,
          ),
        ),
      ),
    );
  }

  Widget _buildAction({required String text, required IconData icon, required void Function() action, double? rotateAngle}) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: IconText(
          icon: rotateAngle == null
              ? Icon(icon, color: Colors.white)
              : Transform.rotate(
                  angle: rotateAngle,
                  child: Icon(icon, color: Colors.white),
                ),
          text: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
          alignment: IconTextAlignment.t2b,
          space: 2,
        ),
      ),
      onTap: action,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        // 全部都异步执行
        _updateHistory();
        _ScreenHelper.restoreWakelock();
        _ScreenHelper.restoreSystemUI();
        _ScreenHelper.restoreAppBarVisibility();
        return true;
      },
      child: SafeArea(
        top: _ScreenHelper.safeAreaTop,
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(Theme.of(context).appBarTheme.toolbarHeight!),
            child: AnimatedSwitcher(
              duration: _kAnimationDuration,
              child: !(!_loading && _data != null && _ScreenHelper.showAppBar)
                  ? SizedBox(height: 0)
                  : AppBar(
                      backgroundColor: Colors.black.withOpacity(0.65),
                      elevation: 0,
                      title: Text(
                        _data!.title,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                      ),
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back),
                        tooltip: '返回',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
            ),
          ),
          body: PlaceholderText(
            onRefresh: () => _loadData(),
            state: _loading
                ? PlaceholderState.loading
                : _data == null
                    ? PlaceholderState.error
                    : PlaceholderState.normal,
            errorText: _error,
            setting: PlaceholderSetting(
              iconColor: Colors.grey[400]!,
              showLoadingText: false,
              textStyle: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.grey[400]!),
              buttonTextStyle: TextStyle(color: Colors.grey[400]!),
              buttonStyle: ButtonStyle(
                side: MaterialStateProperty.all(BorderSide(color: Colors.grey[400]!)),
              ),
            ).copyWithChinese(),
            childBuilder: (c) => Stack(
              children: [
                // ****************************************************************
                // 漫画显示
                // ****************************************************************
                Positioned.fill(
                  child: MangaGalleryView(
                    key: _mangaGalleryViewKey,
                    imageCount: _data!.pages.length,
                    imageUrls: _data!.pages,
                    preloadPagesCount: _setting.preloadCount,
                    verticalScroll: _setting.viewDirection == ViewDirection.topToBottom,
                    reverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                    viewportFraction: _setting.enablePageSpace ? _kViewportFraction : 1,
                    slideWidthRatio: _kSlideWidthRatio,
                    initialImageIndex: _initialPage ?? 1,
                    onPageChanged: _onPageChanged,
                    onSaveImage: (imageIndex) => Fluttertoast.showToast(msg: '第$imageIndex页') /* TODO save image */,
                    onShareImage: (imageIndex) => shareText(
                      title: '【漫画柜】《${_data!.title}》 第$imageIndex页', // TODO without test
                      link: _data!.pages[imageIndex - 1],
                    ),
                    onCenterAreaTapped: () {
                      _ScreenHelper.toggleAppBarVisibility(show: !_ScreenHelper.showAppBar, fullscreen: _setting.fullscreen);
                      if (mounted) setState(() {});
                    },
                    firstPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: true,
                      reverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                      chapter: _data!,
                      mangaCover: widget.mangaCover,
                      chapterGroups: widget.chapterGroups,
                      onJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, anim),
                      onGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      onShowToc: _onTocPressed,
                      onShowComments: _onCommentsPressed,
                      onPop: () => Navigator.of(context).maybePop(),
                    ),
                    lastPageBuilder: (c) => ViewExtraSubPage(
                      isHeader: false,
                      reverseScroll: _setting.viewDirection == ViewDirection.rightToLeft,
                      chapter: _data!,
                      mangaCover: widget.mangaCover,
                      chapterGroups: widget.chapterGroups,
                      onJumpToImage: (idx, anim) => _mangaGalleryViewKey.currentState?.jumpToImage(idx, anim),
                      onGotoChapter: (prev) => _gotoChapter(gotoPrevious: prev),
                      onShowToc: _onTocPressed,
                      onShowComments: _onCommentsPressed,
                      onPop: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                // ****************************************************************
                // 右下角的提示文字
                // ****************************************************************
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: _kAnimationDuration,
                    child: !(_data != null && !_ScreenHelper.showAppBar && !_inExtraPage && _setting.showPageHint)
                        ? SizedBox(height: 0)
                        : Container(
                            color: Colors.black.withOpacity(0.65),
                            padding: EdgeInsets.only(left: 8, right: 8, top: 1.5, bottom: 1.5),
                            child: Text(
                              [
                                _data!.title,
                                '$_currentPage/${_data!.pageCount}页',
                                if (_setting.showNetwork) _networkInfo,
                                if (_setting.showBattery) _batteryInfo,
                                if (_setting.showClock) _currentTime,
                              ].join(' '),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
                // ****************************************************************
                // 最下面的滚动条和按钮
                // ****************************************************************
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _ScreenHelper.bottomPanelDistance,
                  child: AnimatedSwitcher(
                    duration: _kAnimationDuration,
                    child: !(_data != null && _ScreenHelper.showAppBar)
                        ? SizedBox(height: 0)
                        : Container(
                            color: Colors.black.withOpacity(0.75),
                            padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 6),
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Directionality(
                                        textDirection: _setting.viewDirection == ViewDirection.rightToLeft ? TextDirection.rtl : TextDirection.ltr,
                                        child: SliderTheme(
                                          data: Theme.of(context).sliderTheme.copyWith(
                                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                                overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
                                              ),
                                          child: Slider(
                                            value: _progressValue.toDouble(),
                                            min: 1,
                                            max: _data!.pageCount.toDouble(),
                                            onChanged: (p) {
                                              _progressValue = p.toInt();
                                              if (mounted) setState(() {});
                                            },
                                            onChangeEnd: _onSliderChanged,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 4, right: 18),
                                      child: Text(
                                        '$_progressValue/${_data!.pageCount}页',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildAction(
                                        text: _setting.viewDirection == ViewDirection.leftToRight ? '上一章节' : '下一章节',
                                        icon: Icons.arrow_right_alt,
                                        rotateAngle: math.pi,
                                        action: () => _gotoChapter(gotoPrevious: _setting.viewDirection == ViewDirection.leftToRight),
                                      ),
                                      _buildAction(
                                        text: _setting.viewDirection == ViewDirection.leftToRight ? '下一章节' : '上一章节',
                                        icon: Icons.arrow_right_alt,
                                        action: () => _gotoChapter(gotoPrevious: _setting.viewDirection == ViewDirection.rightToLeft),
                                      ),
                                      _buildAction(
                                        text: '阅读设置',
                                        icon: Icons.settings,
                                        action: () => _onSettingPressed(),
                                      ),
                                      _buildAction(
                                        text: '漫画目录',
                                        icon: Icons.menu,
                                        action: () => _onTocPressed(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // ****************************************************************
                // 帮助区域显示
                // ****************************************************************
                if (_showHelpRegion)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _showHelpRegion = false;
                        if (mounted) setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                            color: Colors.yellow[800]!.withOpacity(0.75),
                            child: Center(
                              child: Text(
                                _setting.viewDirection == ViewDirection.leftToRight ? '上\n一\n页' : '下\n一\n页',
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * (1 - 2 * _kSlideWidthRatio),
                            color: Colors.blue[300]!.withOpacity(0.75),
                            child: Center(
                              child: Text(
                                '菜单',
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * _kSlideWidthRatio,
                            color: Colors.pink[300]!.withOpacity(0.75),
                            child: Center(
                              child: Text(
                                _setting.viewDirection == ViewDirection.leftToRight ? '下\n一\n页' : '上\n一\n页',
                                style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ****************************************************************
                // Stack children 结束
                // ****************************************************************
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenHelper {
  static late BuildContext _context;
  static void Function() _setState = () {};

  static void initialize({required BuildContext context, required void Function() setState}) {
    _context = context;
    _setState = setState;
  }

  static bool? __lowerThanAndroidQ;

  static Future<bool> _lowerThanAndroidQ() async {
    __lowerThanAndroidQ ??= Platform.isAndroid && (await DeviceInfoPlugin().androidInfo).version.sdkInt! < 29; // SDK 29 => Android 10
    return __lowerThanAndroidQ!;
  }

  static Future<void> toggleWakelock({required bool enable}) {
    return Wakelock.toggle(enable: enable);
  }

  static Future<void> restoreWakelock() {
    return Wakelock.toggle(enable: false);
  }

  @protected
  static bool _showAppBar = false; // default to hide

  static bool get showAppBar => _showAppBar;

  static Future<void> toggleAppBarVisibility({required bool show, required bool fullscreen}) async {
    if (_showAppBar == true && show == false) {
      _showAppBar = show;
      _setState();
      if (fullscreen) {
        await Future.delayed(_kAnimationDuration + Duration(milliseconds: 50));
        await _ScreenHelper.setSystemUIWhenAppbarChanged(fullscreen: fullscreen, isAppbarShown: false);
      }
    } else if (_showAppBar == false && show == true) {
      if (fullscreen) {
        await _ScreenHelper.setSystemUIWhenAppbarChanged(fullscreen: fullscreen, isAppbarShown: true);
        await Future.delayed(_kOverlayAnimationDuration + Duration(milliseconds: 50));
      }
      _showAppBar = show;
      _setState();
    }
    await WidgetsBinding.instance?.endOfFrame;
  }

  static Future<void> restoreAppBarVisibility() async {
    _showAppBar = false;
    _safeAreaTop = true;
    _bottomPanelDistance = 0;
    // no setState
  }

  static bool _safeAreaTop = true; // defaults to non-fullscreen

  static bool get safeAreaTop => _safeAreaTop;

  static double _bottomPanelDistance = 0; // defaults to non-fullscreen

  static double get bottomPanelDistance => _bottomPanelDistance;

  static Future<void> setSystemUIWhenEnter({required bool fullscreen}) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: !fullscreen || await _lowerThanAndroidQ() ? Colors.black : Colors.black.withOpacity(0.75),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    await setSystemUIWhenAppbarChanged(fullscreen: fullscreen);
  }

  static Future<void> setSystemUIWhenSettingChanged({required bool fullscreen}) async {
    await setSystemUIWhenEnter(fullscreen: fullscreen);
  }

  static Future<void> setSystemUIWhenAppbarChanged({required bool fullscreen, bool? isAppbarShown}) async {
    // https://hiyoko-programming.com/953/
    if (!fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      _safeAreaTop = true;
      _bottomPanelDistance = 0;
    } else {
      if (isAppbarShown ?? _showAppBar) {
        if (!(await _lowerThanAndroidQ())) {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
          _safeAreaTop = false;
          await Future.delayed(_kOverlayAnimationDuration + Duration(milliseconds: 50), () => _bottomPanelDistance = MediaQuery.of(_context).padding.bottom);
        } else {
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
          _safeAreaTop = false;
          _bottomPanelDistance = 0;
        }
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        _safeAreaTop = false;
        _bottomPanelDistance = 0;
      }
    }
    _setState();
    await WidgetsBinding.instance?.endOfFrame;
  }

  static Future<void> restoreSystemUI() async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color.fromRGBO(250, 250, 250, 1.0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }
}
