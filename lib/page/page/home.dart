import 'package:flutter/material.dart';
import 'package:flutter_ahlib/util.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/page/overall.dart';
import 'package:manhuagui_flutter/page/page/ranking.dart';
import 'package:manhuagui_flutter/page/page/recent.dart';
import 'package:manhuagui_flutter/page/page/recommend.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';

/// 首页
class HomeSubPage extends StatefulWidget {
  const HomeSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _HomeSubPageState createState() => _HomeSubPageState();
}

class _HomeSubPageState extends State<HomeSubPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _tabs.length, vsync: this);
  late final _actions = List.generate(_tabs.length, (_) => ActionController());
  var _selectedIndex = 0;
  late final _tabs = [
    Tuple2('推荐', RecommendSubPage(action: _actions[0])),
    Tuple2('更新', RecentSubPage(action: _actions[1])),
    Tuple2('全部', OverallSubPage(action: _actions[2])),
    Tuple2('排行', RankingSubPage(action: _actions[3])),
  ];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _actions[0].addAction('to_shelf', () => widget.action?.invoke('to_shelf'));
    _actions[0].addAction('to_update', () => _controller.animateTo(1));
    _actions[0].addAction('to_ranking', () => _controller.animateTo(3));
    _actions[0].addAction('to_genre', () => widget.action?.invoke('to_genre'));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: TabBar(
          controller: _controller,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: Theme.of(context).primaryTextTheme.subtitle1,
          tabs: _tabs
              .map(
                (t) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(t.item1),
                ),
              )
              .toList(),
          onTap: (idx) {
            if (idx == _selectedIndex) {
              _actions[idx].invoke();
            } else {
              _selectedIndex = idx;
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: WEB_HOMEPAGE_URL,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                // builder: (c) => SearchPage(),
                builder: (c) => SearchPage(),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        children: _tabs.map((t) => t.item2).toList(),
      ),
    );
  }
}
