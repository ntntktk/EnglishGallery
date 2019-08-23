import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:package_info/package_info.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/home_content.dart';

class NavigationDrawer extends StatelessWidget {
  final List<HomeContent> contents;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavigationDrawer({
    Key key,
    @required this.contents,
    @required this.currentIndex,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> drawerChildren = [
      DrawerHeader(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            height: 56.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Text(
                    UnsplutterLocalizations.of(context).trans("app_name"),
                    style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white),
                  ),
                  Text(
                    UnsplutterLocalizations.of(context).trans("drawer_app_description"),
                    style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white70),
                  ),
                ]),
                Container(height: 2.0),
                FutureBuilder<String>(
                  future: PackageInfo.fromPlatform().then((info) => "version ${info.version}"),
                  builder: (context, snapshot) => Text(
                        snapshot.hasData ? snapshot.data : "",
                        style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
                      ),
                ),
              ],
            ),
          ),
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('res/image/drawer_header.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    ];
    drawerChildren.addAll(contents.map((content) {
      final bool isSelected = contents.indexOf(content) == currentIndex;
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
        ),
        child: ListTileTheme(
          style: ListTileStyle.drawer,
          selectedColor: Theme.of(context).accentColor,
          child: ListTile(
            leading: Icon(content.icon),
            title: Text(content.drawerLabel),
            selected: isSelected,
            onTap: () {
              Navigator.pop(context);
              onTap(contents.indexOf(content));
            },
          ),
        ),
      );
    }));
    return Drawer(child: ListView(padding: EdgeInsets.zero, children: drawerChildren));
  }
}
