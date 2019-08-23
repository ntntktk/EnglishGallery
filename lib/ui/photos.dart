import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
import 'package:gallery/util/color_utils.dart';

class PhotosPage extends StatefulWidget {
  @override
  PhotosPageState createState() => PhotosPageState();
}

class PhotosPageState extends State<PhotosPage> with TickerProviderStateMixin {
  final String _tabIndexIdentifier = 'photos_tab_index';
  final Key _allTabKey = const PageStorageKey('photos_all');
  final Key _curatedTabKey = const PageStorageKey('photos_curated');

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Workaround for https://github.com/flutter/flutter/issues/10969
    final index = PageStorage.of(context)
            .readState(context, identifier: _tabIndexIdentifier) ??
        0;
    _tabController = TabController(
      vsync: this,
      length: 2,
      initialIndex: index,
    )..addListener(() {
        PageStorage.of(context).writeState(context, _tabController.index,
            identifier: _tabIndexIdentifier);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kTextTabBarHeight),
          child: Material(
            color: Theme.of(context).primaryColor,
            elevation: 4.0,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(
                    text: UnsplutterLocalizations.of(context)
                        .trans('photos_tab_all')),
                Tab(
                    text: UnsplutterLocalizations.of(context)
                        .trans('photos_tab_curated')),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            FutureBuilder<List<Photo>>(
              future: UnsplashApi().getPhotos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                return snapshot.hasData
                    ? PhotosListView(key: _allTabKey, photos: snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            ),
            FutureBuilder<List<Photo>>(
              future: UnsplashApi().getCuratedPhotos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                return snapshot.hasData
                    ? PhotosListView(key: _curatedTabKey, photos: snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      );
}

class PhotosListView extends StatelessWidget {
  final List<Photo> photos;

  const PhotosListView({Key key, @required this.photos}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView.builder(
      itemCount: photos.length,
      itemBuilder: (context, index) => AspectRatio(
            aspectRatio: photos[index].width / photos[index].height,
            child: Stack(
              children: <Widget>[
                Container(
                  color: ColorUtils.colorFromHexString(photos[index].color),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: photos[index].urls.regular,
                    fadeInDuration: Duration(milliseconds: 225),
                    fit: BoxFit.cover,
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    splashColor: Colors.white10,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              PhotoDetailPage(photo: photos[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
              fit: StackFit.expand,
            ),
          ));
}
