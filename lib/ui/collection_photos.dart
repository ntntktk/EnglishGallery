import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
import 'package:gallery/util/color_utils.dart';
import 'package:gallery/ui/collection_photos.dart';
//
import 'package:http/http.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/local_variables.dart';
import 'package:intl/intl.dart';

class CollectionPhotosPage extends StatefulWidget {
  final int collectionId;
  CollectionPhotosPage({Key key, @required this.collectionId})
      : super(key: key);

  @override
  CollectionsPageState createState() => CollectionsPageState(collectionId);
}

class CollectionsPageState extends State<CollectionPhotosPage>
    with TickerProviderStateMixin {
  final int collectionId;
  CollectionsPageState(this.collectionId);
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

  //
  static const baseUrl = 'https://api.unsplash.com';
  static const headers = {
    'Authorization': "Client-ID ${LocalVariables.unsplashAccessKey}"
  };

  @override
  void initState() {
    super.initState();
    getCollectionPhotos();
    // Workaround for https://github.com/flutter/flutter/issues/10969
    final index = PageStorage.of(context)
            .readState(context, identifier: _tabIndexIdentifier) ??
        0;
    _tabController = TabController(
      vsync: this,
      length: 1,
      initialIndex: index,
    )..addListener(() {
        PageStorage.of(context).writeState(context, _tabController.index,
            identifier: _tabIndexIdentifier);
      });
  }

  Future<List<Photo>> getCollectionPhotos({perPage: 30}) async {
    final Response response = await get(
        "$baseUrl/collections/$collectionId/photos",
        headers: headers);
    final List decodedBody = json.decode(utf8.decode(response.bodyBytes));
    return decodedBody.map<Photo>((json) => Photo.fromJson(json)).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('CollectionPhotos'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(
                text: '$collectionId',
              )
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            FutureBuilder<List<Photo>>(
              future: getCollectionPhotos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) print(snapshot.error);
                return snapshot.hasData
                    ? PhotosListView(key: _allTabKey, photos: snapshot.data)
                    : Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      );
}

class CollectionsListView extends StatelessWidget {
  final List<Collection> collections;

  const CollectionsListView({Key key, @required this.collections})
      : super(key: key);

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final Collection collection = collections[index];

          final List<Widget> overlayTexts = [];
          overlayTexts.add(Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    NetworkImage(collection.user.profileImage.medium),
                radius: 12.0,
              ),
              Container(width: 16.0),
              Text(
                collection.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Colors.white),
              ),
            ],
          ));
          overlayTexts.add(Container(height: 16.0));
          overlayTexts.add(Text(
            collection.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headline.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ));
          overlayTexts.add(Container(height: 8.0));
          final String description = collection.description != null
              ? "${collection.totalPhotos} Photos | ${collection.description}"
              : "${collection.totalPhotos} Photos | ${collection.id}";
          overlayTexts.add(Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
          ));

          return AspectRatio(
            aspectRatio:
                collection.coverPhoto.width / collection.coverPhoto.height,
            child: Stack(
              children: <Widget>[
                Container(
                  color: ColorUtils.colorFromHexString(
                      collection.coverPhoto.color),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: collection.coverPhoto.urls.regular,
                    fadeInDuration: Duration(milliseconds: 225),
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black45,
                        Colors.black26,
                        Colors.black12,
                        Colors.transparent
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: overlayTexts,
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    splashColor: Colors.white10,
                    onTap: () {
                      /*
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // TODO: Create the collection detail page.
                          builder: (BuildContext context) =>
                              PhotoDetailPage(photo: collection.coverPhoto),
                        ),
                      );
                      */
                    },
                  ),
                ),
              ],
              fit: StackFit.expand,
            ),
          );
        },
      );
}

class CollectionPhotosListView extends StatelessWidget {
  final List<Collection> collections;

  const CollectionPhotosListView({Key key, @required this.collections})
      : super(key: key);

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final Collection collection = collections[index];

          final List<Widget> overlayTexts = [];
          overlayTexts.add(Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    NetworkImage(collection.user.profileImage.medium),
                radius: 12.0,
              ),
              Container(width: 16.0),
              Text(
                collection.user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Colors.white),
              ),
            ],
          ));
          overlayTexts.add(Container(height: 16.0));
          overlayTexts.add(Text(
            collection.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headline.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ));
          overlayTexts.add(Container(height: 8.0));
          final String description = collection.description != null
              ? "${collection.totalPhotos} Photos | ${collection.description}"
              : "${collection.totalPhotos} Photos | ${collection.id}";
          overlayTexts.add(Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
          ));

          return AspectRatio(
            aspectRatio:
                collection.coverPhoto.width / collection.coverPhoto.height,
            child: Stack(
              children: <Widget>[
                Container(
                  color: ColorUtils.colorFromHexString(
                      collection.coverPhoto.color),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: collection.coverPhoto.urls.regular,
                    fadeInDuration: Duration(milliseconds: 225),
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black45,
                        Colors.black26,
                        Colors.black12,
                        Colors.transparent
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: overlayTexts,
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
                          // TODO: Create the collection detail page.
                          builder: (BuildContext context) =>
                              PhotoDetailPage(photo: collection.coverPhoto),
                        ),
                      );
                    },
                  ),
                ),
              ],
              fit: StackFit.expand,
            ),
          );
        },
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
