import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/view/tiny_manga.dart';

/// 漫画分组
/// Page for [MangaGroup].
class MangaGroupPage extends StatefulWidget {
  const MangaGroupPage({
    Key key,
    @required this.group,
    @required this.type,
    @required this.icon,
  })  : assert(group != null),
        assert(type != null),
        assert(icon != null),
        super(key: key);

  final MangaGroup group;
  final String type;
  final IconData icon;

  @override
  _MangaGroupPageState createState() => _MangaGroupPageState();
}

class _MangaGroupPageState extends State<MangaGroupPage> {
  ScrollMoreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollMoreController();
  }

  @override
  Widget build(BuildContext context) {
    var paddingWidth = 5.0;
    var width = MediaQuery.of(context).size.width / 3 - paddingWidth * 2;
    var height = width / 3 * 4;
    var title = widget.group.title.isEmpty ? widget.type : (widget.type + "・" + widget.group.title);

    Widget buildTinyMangaView(TinyManga manga) => TinyMangaView(
          manga: manga,
          width: width,
          height: height,
          paddingWidth: paddingWidth,
        );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(title),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          controller: _controller,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(title, style: Theme.of(context).textTheme.subtitle1),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTinyMangaView(widget.group.mangas[0]),
                buildTinyMangaView(widget.group.mangas[1]),
                buildTinyMangaView(widget.group.mangas[2]),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTinyMangaView(widget.group.mangas[3]),
                buildTinyMangaView(widget.group.mangas[4]),
                buildTinyMangaView(widget.group.mangas[5]),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTinyMangaView(widget.group.mangas[6]),
                buildTinyMangaView(widget.group.mangas[7]),
                buildTinyMangaView(widget.group.mangas[8]),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTinyMangaView(widget.group.mangas[9]),
                if (widget.group.mangas.length == 12) buildTinyMangaView(widget.group.mangas[10]),
                if (widget.group.mangas.length == 12) buildTinyMangaView(widget.group.mangas[11]),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: ScrollFloatingActionButton(
        scrollController: _controller,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          onPressed: () => _controller.scrollTop(),
        ),
      ),
    );
  }
}
