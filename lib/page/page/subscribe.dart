import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/page/subscribe_favorite.dart';
import 'package:manhuagui_flutter/page/page/subscribe_history.dart';
import 'package:manhuagui_flutter/page/page/subscribe_shelf.dart';
import 'package:manhuagui_flutter/page/search.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';

/// 订阅
class SubscribeSubPage extends StatefulWidget {
  const SubscribeSubPage({
    Key? key,
    this.action,
  }) : super(key: key);

  final ActionController? action;

  @override
  _SubscribeSubPageState createState() => _SubscribeSubPageState();
}

class _SubscribeSubPageState extends State<SubscribeSubPage> with SingleTickerProviderStateMixin {
  late final _controller = TabController(length: _tabs.length, vsync: this);
  var _selectedIndex = 0; // for tab bar
  var _currentPageIndex = 0; // for tab bar view
  late final _keys = List.generate(3, (_) => GlobalKey<State<StatefulWidget>>());
  late final _actions = List.generate(3, (_) => ActionController());
  late final _tabs = [
    Tuple2('书架', ShelfSubPage(key: _keys[0], action: _actions[0], parentContext: context)),
    Tuple2('收藏', FavoriteSubPage(key: _keys[1], action: _actions[1])),
    Tuple2('阅读历史', HistorySubPage(key: _keys[2], action: _actions[2])),
  ];
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    widget.action?.addAction(() => _actions[_controller.index].invoke());
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) {
      _keys.where((k) => k.currentState?.mounted == true).forEach((k) => k.currentState?.setState(() {}));
      if (mounted) setState(() {});
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ToShelfRequestedEvent>((_) {
      _controller.animateTo(0);
      _selectedIndex = 0;
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ToFavoriteRequestedEvent>((_) {
      _controller.animateTo(1);
      _selectedIndex = 1;
    }));
    _cancelHandlers.add(EventBusManager.instance.listen<ToHistoryRequestedEvent>((_) {
      _controller.animateTo(2);
      _selectedIndex = 2;
    }));
  }

  @override
  void dispose() {
    widget.action?.removeAction();
    _cancelHandlers.forEach((c) => c.call());
    _controller.dispose();
    _actions.forEach((a) => a.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _controller,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs
              .map(
                (t) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    t.item1,
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                  ),
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
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: true),
        actions: [
          if (_currentPageIndex == 0)
            AppBarActionButton(
              icon: Icon(Icons.sync),
              tooltip: '同步书架记录',
              onPressed: () => _actions[0].invoke('sync'),
            ),
          if (_currentPageIndex == 1)
            AppBarActionButton(
              icon: Icon(Icons.bookmark_border),
              tooltip: '管理收藏分组',
              onPressed: () => _actions[1].invoke('manage'),
            ),
          AppBarActionButton(
            icon: Icon(Icons.search),
            tooltip: '搜索漫画',
            onPressed: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => SearchPage(),
              ),
            ),
          ),
        ],
      ),
      body: PageChangedListener(
        callPageChangedAtEnd: false,
        onPageChanged: (i) {
          if (!_controller.indexIsChanging || // swipe manually => indexIsChanging is false
              i == _controller.index /* select tabBar => index equals to target index */) {
            _currentPageIndex = i; // prevent setting to middle page
            if (mounted) setState(() {});
          }
        },
        child: TabBarView(
          controller: _controller,
          physics: DefaultScrollPhysics.of(context),
          children: _tabs.map((t) => t.item2).toList(),
        ),
      ),
    );
  }
}
