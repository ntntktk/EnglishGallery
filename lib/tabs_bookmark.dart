import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
import 'package:gallery/util/color_utils.dart';
import 'package:gallery/ui/collection_photos_fb.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'screen_bookmark.dart';

class BookmarkTabs extends StatefulWidget {
  @override
  CollectionsPageState createState() => CollectionsPageState();
}

class CollectionsPageState extends State<BookmarkTabs>
    with TickerProviderStateMixin {
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

  SharedPreferences prefs;

  int today = int.parse(DateFormat('dd').format(DateTime.now()));

  @override
  void initState() {
    super.initState();
    readLocal();
    // Workaround for https://github.com/flutter/flutter/issues/10969
    final index = PageStorage.of(context)
            .readState(context, identifier: _tabIndexIdentifier) ??
        0;
    _tabController = TabController(
      initialIndex: 0,
      vsync: this,
      length: 2,
    );
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('memorizing', style: TextStyle(fontFamily: "Gotik"),),
        centerTitle: true,
      ),
      /*
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.flash_off),
              text: 'memorizing',
            ),
            Tab(
              icon: Icon(Icons.flash_on),
              text: 'memorized',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        child: Icon(
          Icons.collections_bookmark,
          color: Colors.white,
        ),
        onPressed: () {},
      ),

      bottomNavigationBar: TabBar(
        unselectedLabelColor: Colors.black38,
        labelColor: Colors.purple,
        indicatorColor: Colors.purple,
        controller: _tabController,
        tabs: <Widget>[
          Tab(
            icon: Icon(
              Icons.flash_off,
            ),
            text: 'memorizing',
          ),
          Tab(
            icon: Icon(Icons.flash_on),
            text: 'memorized',
          ),
        ],
      ),
      */
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          BookmarkScreen(),
          BookmarkScreen(),
        ],
      ));
}

class CollectionsListView extends StatefulWidget {
  final QuerySnapshot snapshot;
  final SharedPreferences prefs;

  const CollectionsListView({
    Key key,
    @required this.snapshot,
    @required this.prefs,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return CollectionsListViewState(
      prefs: prefs,
      snapshot: snapshot,
    );
  }
}

class CollectionsListViewState extends State<CollectionsListView> {
  final QuerySnapshot snapshot;
  final SharedPreferences prefs;

  CollectionsListViewState({
    Key key,
    @required this.snapshot,
    @required this.prefs,
  });

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
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        controller: PageController(viewportFraction: 0.9, initialPage: 0),
        itemCount: snapshot.documents.length,
        itemBuilder: (context, index) {
          DocumentSnapshot document = snapshot.documents[index];
          final List<Widget> overlayTexts = [];
          //temp
          Firestore.instance
              .collection('collections')
              .document(document.documentID)
              .updateData({'indexDate': document['indexAvailable'] ~/ 5 + 1});
/*
          Firestore.instance
              .collection('collections')
              .document(document.documentID)
              .get()
              .then((onValue) {
            Firestore.instance
                .collection('available-collections')
                .document(document.documentID)
                .setData(onValue.data);
          });
          Firestore.instance
              .collection('collections')
              .document(document.documentID)
              .updateData({'indexAvailable': index});
          if (document.data['cTitle'].toString().contains('Unsplash')) {
            Firestore.instance
                .collection('collections')
                .document(document.documentID)
                .updateData({'isAvailable': 1});
          } else {
            Firestore.instance
                .collection('collections')
                .document(document.documentID)
                .collection('photos')
                //.where('desc', isGreaterThan: '')
                .getDocuments()
                .then((onValue) {
              if (onValue.documents.length < 30) {
                Firestore.instance
                    .collection('collections')
                    .document(document.documentID)
                    .updateData({'isAvailable': 2});
              } else {
                Firestore.instance
                    .collection('collections')
                    .document(document.documentID)
                    .updateData({'isAvailable': 0});
              }
            });
          }
          */

          overlayTexts.add(Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(document.data['cProfileImage']),
                radius: 12.0,
              ),
              Container(width: 16.0),
              Text(
                document.data['cUserName'],
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
            document['cTitle'],
            //maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.title.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ));
          overlayTexts.add(Container(height: 8.0));
          final String description = document.data['desc'] != null
              ? "${document.data['cTotalphotos'] ?? ''} Photos | ${document.data['desc']}"
              : "${document.data['cTotalphotos'] ?? ''} Photos";
          /*
          overlayTexts.add(Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
          ));
          */
          bool checkCid =
              prefs.getBool(document.data['cid'].toString()) ?? false;

          return Container(
            margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: AspectRatio(
                aspectRatio: document.data['cWidth'] / document.data['cHeight'],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: ColorUtils.colorFromHexString(
                            document.data['cColor']),
                        child: CachedNetworkImage(
                          imageUrl: document.data['cPhotoUrlRegular'],
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
                            if (!checkCid) {
                              prefs.setBool(
                                  document.data['cid'].toString(), true);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // TODO: Create the collection detail page.
                                builder: (BuildContext context) =>
                                    CollectionPhotosPage(
                                  cid: document.data['cid'],
                                  cTitle: document.data['cTitle'],
                                ),
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
