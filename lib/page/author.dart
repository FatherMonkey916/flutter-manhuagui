import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/page/view/option_popup.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga_line.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 漫画家
/// Page for [Author].
class AuthorPage extends StatefulWidget {
  const AuthorPage({
    Key key,
    @required this.id,
    @required this.name,
    @required this.url,
  })  : assert(id != null),
        assert(name != null),
        assert(url != null),
        super(key: key);

  final int id;
  final String name;
  final String url;

  @override
  _AuthorPageState createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  ScrollMoreController _controller;
  ScrollFabController _fabController;
  var _loading = true;
  Author _data;
  var _error = '';
  var _mangas = <SmallManga>[];
  var _total = 0;
  var _order = MangaOrder.byNew;
  var _lastOrder = MangaOrder.byNew;
  var _disableOption = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
    _fabController = ScrollFabController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() {
    _loading = true;
    if (mounted) setState(() {});

    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    return client.getAuthor(aid: widget.id).then((r) async {
      _error = '';
      _data = null;
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _data = r.data;
    }).catchError((e) {
      _data = null;
      _error = wrapError(e).text;
    }).whenComplete(() {
      _loading = false;
      if (mounted) setState(() {});
    });
  }

  Future<List<SmallManga>> _getMangas({int page}) async {
    var dio = DioManager.instance.dio;
    var client = RestClient(dio);
    ErrorMessage err;
    var result = await client.getAuthorMangas(aid: widget.id, page: page, order: _order).catchError((e) {
      err = wrapError(e);
    });
    if (err != null) {
      return Future.error(err.text);
    }
    _total = result.data.total;
    if (mounted) setState(() {});
    return result.data.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(_data?.name ?? widget.name),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '打开浏览器',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.url,
            ),
          ),
        ],
      ),
      body: PlaceholderText.from(
        isLoading: _loading,
        errorText: _error,
        isEmpty: _data == null,
        setting: PlaceholderSetting().toChinese(),
        onRefresh: () => _loadData(),
        childBuilder: (c) => NestedScrollView(
          headerSliverBuilder: (c, o) => [
            // ****************************************************************
            // 头部框
            // ****************************************************************
            SliverContainer(
              width: MediaQuery.of(context).size.width,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0, 0.5, 1],
                  colors: [
                    Colors.blue[100],
                    Colors.orange[100],
                    Colors.purple[100],
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ****************************************************************
                  // 封面
                  // ****************************************************************
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: NetworkImageView(
                      url: DEFAULT_AUTHOR_COVER_URL,
                      height: 130,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // ****************************************************************
                  // 信息
                  // ****************************************************************
                  Container(
                    width: MediaQuery.of(context).size.width - 14 * 3 - 100, // | ▢ ▢ |
                    margin: EdgeInsets.only(top: 14, bottom: 14, right: 14),
                    child: Wrap(
                      direction: Axis.vertical,
                      children: [
                        IconText(
                          icon: Icon(Icons.person, size: 20, color: Colors.orange),
                          text: Text('别名 ${_data.alias}'),
                          space: 8,
                        ),
                        IconText(
                          icon: Icon(Icons.place, size: 20, color: Colors.orange),
                          text: Text(_data.zone),
                          space: 8,
                        ),
                        IconText(
                          icon: Icon(Icons.trending_up, size: 20, color: Colors.orange),
                          text: Text('平均评分 ${_data.averageScore}'),
                          space: 8,
                        ),
                        IconText(
                          icon: Icon(Icons.edit, size: 20, color: Colors.orange),
                          text: Text('共收录 ${_data.mangaCount} 部漫画'),
                          space: 8,
                        ),
                        IconText(
                          icon: Icon(Icons.fiber_new_outlined, size: 20, color: Colors.orange),
                          text: Text('最新收录 ${_data.newestMangaTitle}'),
                          space: 8,
                        ),
                        IconText(
                          icon: Icon(Icons.access_time, size: 20, color: Colors.orange),
                          text: Text('更新于 ${_data.newestDate}'),
                          space: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ****************************************************************
            // 介绍
            // ****************************************************************
            SliverContainer(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Text(
                _data.introduction.trim().isEmpty ? '暂无介绍' : _data.introduction.trim(),
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            SliverContainer(height: 12),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(c),
              sliver: SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: SliverAppBarSizedDelegate(
                  minHeight: 26.0 + 5 * 2 + 1,
                  maxHeight: 26.0 + 5 * 2 + 1,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 26,
                                padding: EdgeInsets.only(left: 5),
                                child: Center(
                                  child: Text('全部漫画 (共 $_total 部)'),
                                ),
                              ),
                              // ****************************************************************
                              // 漫画排序
                              // ****************************************************************
                              if (_total > 0)
                                OptionPopupView<MangaOrder>(
                                  title: _order.toTitle(),
                                  top: 4,
                                  value: _order,
                                  items: [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
                                  onSelect: (o) {
                                    if (_order != o) {
                                      _lastOrder = _order;
                                      _order = o;
                                      if (mounted) setState(() {});
                                      _controller.refresh();
                                    }
                                  },
                                  optionBuilder: (c, v) => v.toTitle(),
                                  enable: !_disableOption,
                                ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          controller: _controller,
          // ****************************************************************
          // 漫画
          // ****************************************************************
          body: Builder(
            builder: (c) => PaginationSliverListView<SmallManga>(
              outerController: _controller,
              controller: PrimaryScrollController.of(c),
              hasOverlapAbsorber: true,
              data: _mangas,
              strategy: PaginationStrategy.offsetBased,
              getDataByOffset: _getMangas,
              initialPage: 1,
              onStartLoading: () => mountedSetState(() => _disableOption = true),
              onStopLoading: () => mountedSetState(() => _disableOption = false),
              onAppend: (l) {
                if (l.length > 0) {
                  Fluttertoast.showToast(msg: '新添了 ${l.length} 部漫画');
                }
                _lastOrder = _order;
                if (mounted) setState(() {});
              },
              onError: (e) {
                Fluttertoast.showToast(msg: e.toString());
                _order = _lastOrder;
                if (mounted) setState(() {});
              },
              clearWhenRefreshing: false,
              clearWhenError: false,
              updateOnlyIfNotEmpty: false,
              refreshFirst: true,
              placeholderSetting: PlaceholderSetting().toChinese(),
              onStateChanged: (_, __) => _fabController.hide(),
              padding: EdgeInsets.zero,
              separator: Divider(height: 1),
              itemBuilder: (c, item) => TinyMangaLineView(manga: item.toTiny()),
            ),
          ),
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fabController: _fabController,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: 'AuthorPage',
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
