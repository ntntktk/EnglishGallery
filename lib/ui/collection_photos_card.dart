import 'dart:io';
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
import 'package:flip_card/flip_card.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery/info_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
//
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery/info_sheet_desc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TtsState { playing, stopped }

const String API_KEY = 'AIzaSyBMI1BM4EQewTd0i265MG0xxv6PNh0pjAU';

class CollectionPhotosPage extends StatefulWidget {
  final Collection collection;
  CollectionPhotosPage({Key key, @required this.collection}) : super(key: key);

  @override
  CollectionsPageState createState() => CollectionsPageState(collection);
}

class CollectionsPageState extends State<CollectionPhotosPage>
    with TickerProviderStateMixin {
  final Collection collection;
  CollectionsPageState(this.collection);
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _readLocal();
    _initTts();
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

  bool isTranslating = false;
  var _currentTranslatedTo = "";
  SharedPreferences prefs;
  _readLocal() async {
    prefs = await SharedPreferences.getInstance();
    language = prefs.getString("language") ?? 'en-US';
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

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
    _tabController.dispose();
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in languages) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  List<DropdownMenuItem<String>> getVoiceDropDownMenuItems() {
    var items = List<DropdownMenuItem<String>>();
    for (String type in voices) {
      items.add(DropdownMenuItem(value: type, child: Text(type)));
    }
    return items;
  }

  void changedLanguageDropDownItem(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
    });
  }

  void changedVoiceDropDownItem(String selectedType) {
    setState(() {
      voice = selectedType;
      flutterTts.setVoice(voice);
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  Future<List<Photo>> getCollectionPhotos({page: 1, perpage: 30}) async {
    final Response response = await get(
        "$baseUrl/collections/${collection.id}/photos?alt_description&page=$page&per_page=$perpage",
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

  //tts
  Future _speak(Photo photo) async {
    if (photo.altDescription == null || photo.altDescription == '') {
    } else {
      var result = await flutterTts.speak(photo.altDescription);
      if (result == 1) setState(() => ttsState = TtsState.playing);
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  //load image
  _resetImages() {
    // clear image list
    photos = [];
    // reset page counter
    page = 0;
    totalPages = -1;
    // reset keyword
    keyword = null;
    // show regular images
    _loadImages();
  }

  /// Requests a list of [UnsplashImage] for a given [keyword].
  /// If the given [keyword] is null, trending images are loaded.
  _loadImages({String keyword}) async {
    // check if there is currently a loading task running
    if (loadingPhotos) {
      // there is currently a task running
      return;
    }
    // check if all pages are already loaded
    if (totalPages != -1 && page >= totalPages) {
      // all pages already loaded
      return;
    }
    // set loading state
    // delay setState, otherwise: Unhandled Exception: setState() or markNeedsBuild() called during build.
    await Future.delayed(Duration(microseconds: 1));
    setState(() {
      // set loading
      loadingPhotos = true;
      // check if new search
      if (this.keyword != keyword) {
        // clear images for new search
        this.photos = [];
        // reset page counter
        this.page = 0;
      }
      // keyword null
      this.keyword = keyword;
    });

    // load images
    List<Photo> photos;
    if (keyword == null) {
      // load images from the next page of trending images
      photos = await getCollectionPhotos(page: ++page);
      photos.shuffle();
    }
    /*
    else {
      // load images from the next page with a keyword
      List res = await getCollectionPhotos(keyword,
          page: ++page);
      // set totalPages
      totalPages = res[0];
      // set images
      photos = res[1];
    }
    */

    // TODO: handle errors

    // update the state
    setState(() {
      // done loading
      loadingPhotos = false;
      // set new loaded images

      this.photos.addAll(photos);
    });
  }

  /// Asynchronously loads a [UnsplashImage] for a given [index].
  _loadImage(int index) async {
    // check if new images need to be loaded
    if (index >= photos.length - 2) {
      // Reached the end of the list. Try to load more images.
      _loadImages(keyword: keyword);
    }

    return index < photos.length ? photos[index] : null;
  }

  void _translate({String text}) async {
    try {
      setState(() {
        isTranslating = true;
      });
      final response = await http.get(Uri.encodeFull(
          'https://translation.googleapis.com/language/translate/v2?target=ko&key=$API_KEY&q=$text'));
      //above is Google's own api but will block after few request till that use bello api

      //final response = await http.get(Uri.encodeFull(
      //    'http://mozaffari.me/api/gtranslate/?from=${from}&to=${to}&text=${text}'));
      if (response.statusCode == 200) {
        print(text);
        // If the call to the server was successful, parse the JSON
        var _result = json.decode(response.body)['data']['translations'][0]
            ['translatedText'];
        Fluttertoast.showToast(msg: _result ?? '');

        setState(() {
          _currentTranslatedTo = _result;
          isTranslating = false;
        });
      } else {
        setState(() {
          _currentTranslatedTo = "Faild To Connect to internet";
          Fluttertoast.showToast(msg: _currentTranslatedTo);
          isTranslating = false;
        });
        // If that call was not successful, throw an error.
        throw Exception('Failed to load data error:${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _currentTranslatedTo = "Faild To Connect to internet";
        isTranslating = false;
      });
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (keyword != null) {
            _resetImages();
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text('${collection.title}'),
            actions: <Widget>[
              IconButton(
                icon: Icon(MdiIcons.playSpeed),
                onPressed: () {
                  showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                            cancelButton: CupertinoActionSheetAction(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            actions: <Widget>[
                              CupertinoActionSheetAction(
                                child: Text('1.0'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    flutterTts.setSpeechRate(1);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('0.8'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    flutterTts.setSpeechRate(0.8);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('0.6'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    flutterTts.setSpeechRate(0.6);
                                  });
                                },
                              ),
                            ],
                          ));
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.language,
                  color: Colors.black87,
                ),
                onPressed: () {
                  showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                            cancelButton: CupertinoActionSheetAction(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            actions: <Widget>[
                              CupertinoActionSheetAction(
                                child: Text('US'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isTTsSetup = true;
                                    language = "en-US";
                                    prefs.setString('language', language);
                                    flutterTts.setLanguage(language);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('GB'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isTTsSetup = true;
                                    language = "en-GB";
                                    prefs.setString('language', language);
                                    flutterTts.setLanguage(language);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('AU'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isTTsSetup = true;
                                    language = "en-AU";
                                    prefs.setString('language', language);
                                    flutterTts.setLanguage(language);
                                  });
                                },
                              )
                            ],
                          ));
                },
              ),
              IconButton(
                icon: Icon(
                  MdiIcons.cards,
                  color: Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    if (isGrid) {
                      isGrid = false;
                    } else {
                      isGrid = true;
                    }
                  });
                },
              )
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: <Widget>[
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
                                      crossAxisCount: isGrid ? 2 : 1),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                //firebase
                                /*
                                Firestore.instance
                                    .collection('photos')
                                    .document('${photos[index].id}')
                                    .setData({
                                  'profileImage':
                                      photos[index].user.profileImage,
                                  'userName': photos[index].user.name,
                                  'photoUrlSmall': photos[index].urls.small,
                                  'photoUrlRegular': photos[index].urls.regular,
                                  'desc': photos[index].altDescription,
                                  'id': photos[index].id,
                                  'link': photos[index].user.links.html,
                                  'height': photos[index].height,
                                  'width': photos[index].width,
                                  'date': photos[index].createdAt
                                });
                                */
                                return AspectRatio(
                                    aspectRatio: photos[index].width /
                                        photos[index].height,
                                    child: Container(
                                        padding: EdgeInsets.all(4),
                                        child: Hero(
                                          tag: photos[index].id,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: photos[index]
                                                            .altDescription ==
                                                        null ||
                                                    photos[index]
                                                            .altDescription ==
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
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.5),
                                                            ),
                                                            onPressed: () {
                                                              showModalBottomSheet(
                                                                  context:
                                                                      context,
                                                                  builder: (context) =>
                                                                      InfoSheet(
                                                                          photos[
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
                                                                alignment:
                                                                    Alignment
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
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.5),
                                                            ),
                                                            onPressed: () {
                                                              showModalBottomSheet(
                                                                  context:
                                                                      context,
                                                                  builder: (context) =>
                                                                      InfoSheet(
                                                                          photos[
                                                                              index]));
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                      fit: StackFit.expand,
                                                    ),
                                                    back: Container(
                                                        alignment:
                                                            Alignment.center,
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
                                                              children: <
                                                                  Widget>[
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
                                                                      icon:
                                                                          Icon(
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
                                                                      heroTag:
                                                                          null,
                                                                      mini:
                                                                          true,
                                                                      child:
                                                                          Icon(
                                                                        MdiIcons
                                                                            .chatProcessing,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                      onPressed:
                                                                          () {
                                                                        if (!isTTsSetup) {
                                                                          flutterTts
                                                                              .setLanguage(language);
                                                                        }
                                                                        _speak(photos[
                                                                            index]);
                                                                      },
                                                                    ),
                                                                    IconButton(
                                                                      icon:
                                                                          Icon(
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
                                                                            builder: (context) =>
                                                                                InfoDescSheet(desc: photos[index].altDescription));
                                                                      },
                                                                    )
                                                                  ],
                                                                ),
                                                                Container(
                                                                    margin: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.0),
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child:
                                                                        Center(
                                                                      child: RichText(
                                                                          text: TextSpan(
                                                                              text: photos[index].altDescription ?? 'null',
                                                                              style: TextStyle(color: Colors.white, fontFamily: "Gotik", fontSize: isGrid ? 16 : 24))),
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
          ),
        ),
      );
}
