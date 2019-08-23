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

class PhotosFbPage extends StatefulWidget {
  final int cid;
  final String cTitle;
  PhotosFbPage({
    Key key,
    @required this.cid,
    @required this.cTitle,
  }) : super(key: key);
  @override
  CollectionsPageState createState() => CollectionsPageState(cid, cTitle);
}

class CollectionsPageState extends State<PhotosFbPage>
    with TickerProviderStateMixin {
  final int cid;
  final String cTitle;
  CollectionsPageState(this.cid, this.cTitle);
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    readLocal();
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
        elevation: 0,
        title: Text(
          cTitle,
          style: TextStyle(fontFamily: "Gotik"),
        ),
        centerTitle: true,
        actions: <Widget>[
          
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('collections')
            .document('$cid')
            .collection('photos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? CollectionsListView(
                  key: _allTabKey,
                  snapshot: snapshot.data,
                  prefs: prefs,
                )
              : Center(child: CircularProgressIndicator());
        },
      ));
}

class CollectionsListView extends StatelessWidget {
  final QuerySnapshot snapshot;
  final SharedPreferences prefs;

  const CollectionsListView({
    Key key,
    @required this.snapshot,
    @required this.prefs,
  }) : super(key: key);

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
        //controller: PageController(viewportFraction: 0.9, initialPage: 0),
        itemCount: snapshot.documents.length,
        itemBuilder: (context, index) {
          DocumentSnapshot document = snapshot.documents[index];
          final List<Widget> overlayTexts = [];
          
          return Container(
            margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: AspectRatio(
                aspectRatio: document.data['width'] / document.data['height'],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: Colors.black87,
                        child: CachedNetworkImage(
                          imageUrl: document.data['photoUrlSmall'],
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
