import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/api/unsplash_api.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/photo_detail.dart';
import 'package:gallery/util/color_utils.dart';
//

import 'package:http/http.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/local_variables.dart';
import 'package:intl/intl.dart';
//
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
//tts
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class CollectionPhotosPage extends StatefulWidget {
  final int collectionId;
  CollectionPhotosPage({Key key, @required this.collectionId})
      : super(key: key);

  @override
  PhotosPageState createState() => PhotosPageState(collectionId: collectionId);
}

class PhotosPageState extends State<CollectionPhotosPage>
    with TickerProviderStateMixin {
  final int collectionId;
  PhotosPageState({Key key, @required this.collectionId});

  final String _tabIndexIdentifier = 'photos_tab_index';
  final Key _allTabKey = const PageStorageKey('photos_all');
  final Key _curatedTabKey = const PageStorageKey('photos_curated');

  TabController _tabController;
  String keyword;

  //tts
  FlutterTts flutterTts;
  dynamic languages;
  dynamic voices;
  String language;
  String voice;
  String _newVoiceText;
  TtsState ttsState = TtsState.stopped;
  bool isTTsSetup = false;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

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

  //tts
  _initTts() async {
    flutterTts = FlutterTts();
    if (Platform.isAndroid) {
      flutterTts.ttsInitHandler(() {
        _getLanguages();
        _getVoices();
      });
    } else if (Platform.isIOS) {
      _getLanguages();
      _getVoices();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future _getVoices() async {
    voices = await flutterTts.getVoices;
    if (voices != null) setState(() => voices);
  }

  Future _speak(String desc) async {
    var result = await flutterTts.speak(desc);
    if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    flutterTts.stop();
  }

  Future<List<Photo>> getCollectionPhotos({perPage: 30}) async {
    const baseUrl = 'https://api.unsplash.com';
    const headers = {
      'Authorization': "Client-ID ${LocalVariables.unsplashAccessKey}"
    };

    final Response response = await get(
        "$baseUrl/collections/$collectionId/photos?per_page=$perPage",
        headers: headers);
    final List decodedBody = json.decode(utf8.decode(response.bodyBytes));
    return decodedBody.map<Photo>((json) => Photo.fromJson(json)).toList();
  }

  /// Returns a FutureBuilder to load a [UnsplashImage] for a given [index].
  Widget _buildImageItemBuilder(BuildContext context, Photo photo, int index) =>
      InkWell(
        onTap: () {},
        // Hero Widget for Hero animation with [ImagePage]
        child: photo == null
            ? _buildImagePlaceholder()
            : Hero(
                tag: photo.id,
                child: _addRoundedCorners(InkWell(
                  onTap: () {},
                  child: FlipCard(
                      front: Stack(
                        children: <Widget>[
                          CachedNetworkImage(
                            imageUrl: photo.urls.small,
                            placeholder: (context, url) =>
                                _buildImagePlaceholder(color: photo.color),
                            errorWidget: (context, url, obj) =>
                                _buildImageErrorWidget(),
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              onPressed: () {},
                            ),
                          )
                        ],
                        fit: StackFit.expand,
                      ),
                      back: SizedBox(
                          height: 500,
                          child: Container(
                              alignment: Alignment.center,
                              color: Colors.black87,
                              child: Wrap(
                                direction: Axis.horizontal,
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(
                                              Icons.bookmark_border,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {},
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          FloatingActionButton(
                                            backgroundColor: Colors.white,
                                            heroTag: null,
                                            mini: true,
                                            child: Icon(
                                              MdiIcons.chatProcessing,
                                              color: Colors.black87,
                                            ),
                                            onPressed: () {
                                              /*
                                              if (!isTTsSetup) {
                                                isTTsSetup = true;
                                                flutterTts
                                                    .setLanguage("en-US")
                                                    .then((onValue) {
                                                  _speak(photo.altDescription ??
                                                      'null');
                                                });
                                              } else {
                                                _speak(
                                                    photo.altDescription ?? 'null');
                                              }
                                              */
                                            },
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              MdiIcons.googleTranslate,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {},
                                          )
                                        ],
                                      ),
                                      Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: RichText(
                                                text: TextSpan(
                                                    text:
                                                        photo.altDescription ??
                                                            'null',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: "Gotik"))),
                                          )),
                                    ],
                                  )
                                ],
                              )))),
                ))),
      );

  /// Adds rounded corners to a given [widget].
  Widget _addRoundedCorners(Widget widget) =>
      // wrap in ClipRRect to achieve rounded corners
      ClipRRect(borderRadius: BorderRadius.circular(4.0), child: widget);

  /// Returns a placeholder to show until an image is loaded.
  Widget _buildImagePlaceholder({String color}) => Container(
        color: color != null
            ? Color(int.parse(color, radix: 16) + 0x64000000)
            : Colors.grey[200],
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

  /// Returns a StaggeredTile for a given [image].
  StaggeredTile _buildStaggeredTile(
      BuildContext context, Photo photo, int columnCount) {
    // calc image aspect ration
    double aspectRatio = photo.height.toDouble() / photo.width.toDouble();
    // calc columnWidth
    double columnWidth = MediaQuery.of(context).size.width / columnCount;
    // not using [StaggeredTile.fit(1)] because during loading StaggeredGrid is really jumpy.
    return StaggeredTile.extent(1, aspectRatio * columnWidth);
  }

  /// Resets the state to the inital state.

  @override
  Widget build(BuildContext context) => WillPopScope(
        child: Scaffold(
          appBar: AppBar(
              /*
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black54,
              
              tabs: [
                Tab(
                    text: UnsplutterLocalizations.of(context)
                        .trans('photos_tab_all')),
              ],
            ),
            */
              ),
          body: FutureBuilder<List<Photo>>(
              future: getCollectionPhotos(),
              builder: (context, snapshot) => !snapshot.hasData
                  ? new Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: EdgeInsets.all(16.0),
                      child: StaggeredGridView.countBuilder(
                        // set column count
                        crossAxisCount: 2,
                        itemCount: snapshot.data.length,
                        // set itemBuilder
                        itemBuilder: (BuildContext context, int index) =>
                            _buildImageItemBuilder(
                                context, snapshot.data[index], index),
                        staggeredTileBuilder: (int index) {
                          return _buildStaggeredTile(
                              context, snapshot.data[index], 2);
                        },
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                      ),
                    )
              /*
              
          TabBarView(
            controller: _tabController,
            children: <Widget>[
                builder: (context, snapshot) {
                  if (snapshot.hasError) print(snapshot.error);
                  return snapshot.hasData
                      ? PhotosStaggeredView(
                          key: _allTabKey, photos: snapshot.data)
                      : Center(child: CircularProgressIndicator());
                },
                  ),
            ],
                */
              ),
        ),
        onWillPop: () async {
          if (keyword != null) {
            //_resetImages();
            return false;
          }
          return true;
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

class PhotosStaggeredView extends StatelessWidget {
  final List<Photo> photos;

  const PhotosStaggeredView({Key key, @required this.photos}) : super(key: key);

  //tts

  /// Returns a StaggeredTile for a given [image].
  StaggeredTile _buildStaggeredTile(
      BuildContext context, Photo photo, int columnCount) {
    // calc image aspect ration
    double aspectRatio = photo.height.toDouble() / photo.width.toDouble();
    // calc columnWidth
    double columnWidth = MediaQuery.of(context).size.width / columnCount;
    // not using [StaggeredTile.fit(1)] because during loading StaggeredGrid is really jumpy.
    return StaggeredTile.extent(1, aspectRatio * columnWidth);
  }

  /// Returns a FutureBuilder to load a [UnsplashImage] for a given [index].
  Widget _buildImageItemBuilder(BuildContext context, Photo photo, int index) =>
      InkWell(
        onTap: () {},
        // Hero Widget for Hero animation with [ImagePage]
        child: photo == null
            ? _buildImagePlaceholder()
            : Hero(
                tag: photo.id,
                child: _addRoundedCorners(InkWell(
                  onTap: () {},
                  child: FlipCard(
                      front: Stack(
                        children: <Widget>[
                          CachedNetworkImage(
                            imageUrl: photo.urls.small,
                            placeholder: (context, url) =>
                                _buildImagePlaceholder(color: photo.color),
                            errorWidget: (context, url, obj) =>
                                _buildImageErrorWidget(),
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              onPressed: () {
                                
                              },
                            ),
                          )
                        ],
                        fit: StackFit.expand,
                      ),
                      back: SizedBox(
                          height: 500,
                          child: Container(
                              alignment: Alignment.center,
                              color: Colors.black87,
                              child: Wrap(
                                direction: Axis.horizontal,
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(
                                              Icons.bookmark_border,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {},
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          FloatingActionButton(
                                            backgroundColor: Colors.white,
                                            heroTag: null,
                                            mini: true,
                                            child: Icon(
                                              MdiIcons.chatProcessing,
                                              color: Colors.black87,
                                            ),
                                            onPressed: () {
                                              /*
                                              if (!isTTsSetup) {
                                                isTTsSetup = true;
                                                flutterTts
                                                    .setLanguage("en-US")
                                                    .then((onValue) {
                                                  _speak(photo.altDescription ??
                                                      'null');
                                                });
                                              } else {
                                                _speak(
                                                    photo.altDescription ?? 'null');
                                              }
                                              */
                                            },
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              MdiIcons.googleTranslate,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {},
                                          )
                                        ],
                                      ),
                                      Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: RichText(
                                                text: TextSpan(
                                                    text:
                                                        photo.altDescription ??
                                                            'null',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: "Gotik"))),
                                          )),
                                    ],
                                  )
                                ],
                              )))),
                ))),
      );

  /// Adds rounded corners to a given [widget].
  Widget _addRoundedCorners(Widget widget) =>
      // wrap in ClipRRect to achieve rounded corners
      ClipRRect(borderRadius: BorderRadius.circular(4.0), child: widget);

  /// Returns a placeholder to show until an image is loaded.
  Widget _buildImagePlaceholder({String color}) => Container(
        color: color != null
            ? Color(int.parse(color, radix: 16) + 0x64000000)
            : Colors.grey[200],
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
  Widget build(BuildContext context) => StaggeredGridView.countBuilder(
      crossAxisCount: 2,
      staggeredTileBuilder: (int index) {
        return _buildStaggeredTile(context, photos[index], 2);
      },
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      itemCount: photos.length,
      /*
        itemBuilder: (BuildContext context, int index) =>
            _buildImageItemBuilder(context, photos[index], index),
            */
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
