import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
import 'package:gallery/util/color_utils.dart';
import 'package:gallery/ui/collection_photos_card_fb.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionsPage extends StatefulWidget {
  @override
  CollectionsPageState createState() => CollectionsPageState();
}

class CollectionsPageState extends State<CollectionsPage>
    with TickerProviderStateMixin {
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

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
      length: 1,
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            DateFormat('yyyy.MMM.dd').format(DateTime.now()),
            style: TextStyle(fontFamily: "Gotik", color: Colors.black87),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<Collection>>(
          future: UnsplashApi().getCollections().then((collections) =>
              collections
                  .where((collection) => collection?.coverPhoto != null)
                  .toList()),
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);
            return snapshot.hasData
                ? CollectionsListView(
                    key: _allTabKey, collections: snapshot.data)
                : Center(child: CircularProgressIndicator());
          },
        ),
      );
}

class CollectionsListView extends StatelessWidget {
  final List<Collection> collections;

  const CollectionsListView({Key key, @required this.collections})
      : super(key: key);

  Widget _buildImagePlaceholder() => Container(
        color: Colors.grey[200],
      );

  /// Returns a error placeholder to show until an image is loaded.
  Widget _buildImageErrorWidget() => Container(
        color: Colors.grey[200],
        child: Center(
            child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
        )),
      );

  @override
  Widget build(BuildContext context) => GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
        //controller: PageController(viewportFraction: 0.9, initialPage: 0),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final Collection collection = collections[index];
          final List<Widget> overlayTexts = [];
          //firebase
          /*
          Firestore.instance
              .collection('collections')
              .document('${collection.id}')
              .setData({
            'cColor': collection.coverPhoto.color,
            'cUserBio': collection.user.bio,
            'cUserLink': collection.user.links.html,
            'cDesc': collection.description,
            'curated': collection.curated,
            'cProfileImage': collection.user.profileImage.medium,
            'cUserName': collection.user.name,
            'cPhotoUrlRegular': collection.coverPhoto.urls.regular,
            'cPhotoUrlSmall': collection.coverPhoto.urls.small,
            'cTitle': collection.title,
            'cid': collection.id,
            'cLink': collection.links.html,
            'cHeight': collection.coverPhoto.height,
            'cWidth': collection.coverPhoto.width,
            'cDate': collection.coverPhoto.createdAt
          });
          */

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
            //maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.title.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ));
          overlayTexts.add(Container(height: 8.0));
          final String description = collection.description != null
              ? "${collection.totalPhotos} Photos | ${collection.description}"
              : "${collection.totalPhotos} Photos";
          /*
          overlayTexts.add(Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
          ));
          */

          return Container(
            margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: AspectRatio(
                aspectRatio:
                    collection.coverPhoto.width / collection.coverPhoto.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: ColorUtils.colorFromHexString(
                            collection.coverPhoto.color),
                        child: CachedNetworkImage(
                          imageUrl: collection.coverPhoto.urls.regular,
                          placeholder: (context, url) =>
                              _buildImagePlaceholder(),
                          errorWidget: (context, url, obj) =>
                              _buildImageErrorWidget(),
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
                                    CollectionPhotosPage(cid: collection.id, cTitle: collection.title,),
                              ),
                            );

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
                )),
          );
        },
      );
}
