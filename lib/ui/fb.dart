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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

//
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
//import 'package:gallery/ui/collection_photos.dart';
//
import 'package:http/http.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/local_variables.dart';
import 'package:flip_card/flip_card.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:gallery/info_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
//
import 'package:http/http.dart' as http;
import 'package:gallery/info_sheet_desc.dart';

enum TtsState { playing, stopped }

const String API_KEY = 'AIzaSyBMI1BM4EQewTd0i265MG0xxv6PNh0pjAU';

class CollectionsFbPage extends StatefulWidget {
  @override
  CollectionsPageState createState() => CollectionsPageState();
}

class CollectionsPageState extends State<CollectionsFbPage>
    with TickerProviderStateMixin {
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

  SharedPreferences prefs;

  bool isGrid = true;
  bool isTTsSetup = false;

  //tts
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  String language;
  String voice;

  String _newVoiceText;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  //
  static const baseUrl = 'https://api.unsplash.com';
  static const headers = {
    'Authorization': "Client-ID ${LocalVariables.unsplashAccessKey}"
  };

  /// Stores the current page index for the api requests.
  int page = 0, totalPages = -1;

  /// States whether there is currently a task running loading images.
  bool loadingPhotos = false;

  /// Stores the currently loaded loaded images.
  List<Photo> photos = [];

  /// Stored the currently searched keyword.
  String keyword;
  var txt = TextEditingController();

  int cid = 100392;

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

  Future<List<Photo>> getCollectionPhotos({page: 1, perpage: 30}) async {
    final Response response = await get(
        "$baseUrl/collections/$cid/photos?page=$page&per_page=$perpage",
        headers: headers);
    final List decodedBody = json.decode(utf8.decode(response.bodyBytes));
    return decodedBody.map<Photo>((json) => Photo.fromJson(json)).toList();
  }

  /// Returns a placeholder to show until an image is loaded.
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
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          DateFormat('yyyy.MMM.dd').format(DateTime.now()),
          style: TextStyle(fontFamily: "Gotik"),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: <Widget>[
          StreamBuilder(
            stream: Firestore.instance.collection('collections').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);
              return snapshot.hasData
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5),
                      //controller: PageController(viewportFraction: 0.9, initialPage: 0),
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document =
                            snapshot.data.documents[index];
                        final List<Widget> overlayTexts = [];

                        overlayTexts.add(Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  NetworkImage(document.data['cProfileImage']),
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

                        setState(() {
                          cid = document['cid'];
                        });

                        return Container(
                          margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
                          child: AspectRatio(
                              aspectRatio: document.data['cWidth'] /
                                  document.data['cHeight'],
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Stack(
                                  children: <Widget>[
                                    Container(
                                      color: ColorUtils.colorFromHexString(
                                          document.data['cColor']),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            document.data['cPhotoUrlRegular'],
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: overlayTexts,
                                      ),
                                    ),
                                    Material(
                                      type: MaterialType.transparency,
                                      child: InkWell(
                                        splashColor: Colors.white10,
                                        onTap: () {
                                          String strCid = prefs.getString(
                                                  document.data['cid']
                                                      .toString()) ??
                                              '';
                                          if (strCid.isNotEmpty) {
                                            Fluttertoast.showToast(msg: strCid);
                                          }
                                          prefs.setString(
                                              document.data['cid'].toString(),
                                              DateFormat('yyyy-MM-dd hh:mm:ss')
                                                  .format(DateTime.now()));
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
                    )
                  : Center(child: CircularProgressIndicator());
            },
          ),
          FutureBuilder<List<Photo>>(
            future: getCollectionPhotos(),
            builder: (context, snapshot) {
              List<Photo> photos = snapshot.data;
              if (snapshot.hasError) print(snapshot.error);

              return snapshot.hasData
                  ? Padding(
                      padding: EdgeInsets.all(1),
                      child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isGrid ? 30 : 1),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            //firebase
                            Firestore.instance
                                .collection('photos')
                                .document('${photos[index].id}')
                                .setData({
                              'profileImage':
                                  photos[index].user.profileImage.medium,
                              'userName': photos[index].user.name,
                              'photoUrlSmall': photos[index].urls.small,
                              'photoUrlRegular': photos[index].urls.regular,
                              'desc': photos[index].altDescription,
                              'id': photos[index].id,
                              'cid': cid,
                              'link': photos[index].user.links.html,
                              'height': photos[index].height,
                              'width': photos[index].width,
                              'color': photos[index].color,
                              'date': photos[index].createdAt
                            }).then((onValue) {
                              Firestore.instance
                                  .collection('collections')
                                  .document('$cid')
                                  .collection('photos')
                                  .document('${photos[index].id}')
                                  .setData({
                                'profileImage':
                                    photos[index].user.profileImage.medium,
                                'userName': photos[index].user.name,
                                'photoUrlSmall': photos[index].urls.small,
                                'photoUrlRegular': photos[index].urls.regular,
                                'desc': photos[index].altDescription,
                                'id': photos[index].id,
                                'cid': cid,
                                'link': photos[index].user.links.html,
                                'height': photos[index].height,
                                'width': photos[index].width,
                                'color': photos[index].color,
                                'date': photos[index].createdAt
                              });
                            });
                            return AspectRatio(
                                aspectRatio:
                                    photos[index].width / photos[index].height,
                                child: Container(
                                    padding: EdgeInsets.all(4),
                                    child: Hero(
                                      tag: photos[index].id,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: photos[index].altDescription ==
                                                    null ||
                                                photos[index].altDescription ==
                                                    ''
                                            ? InkWell(
                                                onTap: () {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'altDescription is null');
                                                },
                                                child: Stack(
                                                  children: <Widget>[
                                                    CachedNetworkImage(
                                                      imageUrl: isGrid
                                                          ? photos[index]
                                                              .urls
                                                              .small
                                                          : photos[index]
                                                              .urls
                                                              .regular,
                                                      placeholder: (context,
                                                              url) =>
                                                          _buildImagePlaceholder(),
                                                      errorWidget: (context,
                                                              url, obj) =>
                                                          _buildImageErrorWidget(),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.info_outline,
                                                          color: Colors.white
                                                              .withOpacity(0.5),
                                                        ),
                                                        onPressed: () {
                                                          showModalBottomSheet(
                                                              context: context,
                                                              builder: (context) =>
                                                                  InfoSheet(photos[
                                                                      index]));
                                                        },
                                                      ),
                                                    ),
                                                    photos[index].altDescription ==
                                                                null ||
                                                            photos[index]
                                                                    .altDescription ==
                                                                ''
                                                        ? Align(
                                                            alignment: Alignment
                                                                .center,
                                                            child: Icon(
                                                              MdiIcons
                                                                  .eyeOffOutline,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      1),
                                                            ),
                                                          )
                                                        : Container()
                                                  ],
                                                  fit: StackFit.expand,
                                                ),
                                              )
                                            : FlipCard(
                                                front: Stack(
                                                  children: <Widget>[
                                                    CachedNetworkImage(
                                                      imageUrl: isGrid
                                                          ? photos[index]
                                                              .urls
                                                              .small
                                                          : photos[index]
                                                              .urls
                                                              .regular,
                                                      placeholder: (context,
                                                              url) =>
                                                          _buildImagePlaceholder(),
                                                      errorWidget: (context,
                                                              url, obj) =>
                                                          _buildImageErrorWidget(),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.info_outline,
                                                          color: Colors.white
                                                              .withOpacity(0.5),
                                                        ),
                                                        onPressed: () {
                                                          showModalBottomSheet(
                                                              context: context,
                                                              builder: (context) =>
                                                                  InfoSheet(photos[
                                                                      index]));
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                  fit: StackFit.expand,
                                                ),
                                                back: Container(
                                                    alignment: Alignment.center,
                                                    color: Colors.black87,
                                                    child: Wrap(
                                                      direction:
                                                          Axis.horizontal,
                                                      spacing: 8.0,
                                                      runSpacing: 8.0,
                                                      children: <Widget>[
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                IconButton(
                                                                  icon: Icon(
                                                                    Icons
                                                                        .bookmark_border,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  onPressed:
                                                                      () {},
                                                                ),
                                                                FloatingActionButton(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  heroTag: null,
                                                                  mini: true,
                                                                  child: Icon(
                                                                    MdiIcons
                                                                        .chatProcessing,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                  onPressed:
                                                                      () {},
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(
                                                                    MdiIcons
                                                                        .googleTranslate,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) =>
                                                                                InfoDescSheet(desc: photos[index].altDescription));
                                                                  },
                                                                )
                                                              ],
                                                            ),
                                                            Container(
                                                                margin: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10.0),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Center(
                                                                  child: RichText(
                                                                      text: TextSpan(
                                                                          text: photos[index].altDescription ??
                                                                              'null',
                                                                          style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontFamily: "Gotik",
                                                                              fontSize: isGrid ? 16 : 24))),
                                                                )),
                                                          ],
                                                        )
                                                      ],
                                                    )),
                                              ),
                                      ),
                                    )));
                          }))
                  : Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ));
}
