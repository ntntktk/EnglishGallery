import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
//
import 'package:http/http.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/local_variables.dart';
import 'package:intl/intl.dart';
import 'package:flip_card/flip_card.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery/info_sheet_fb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
//
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery/info_sheet_desc_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//
//tranlate
import 'package:translator/translator.dart';
import 'models/language.dart';

enum TtsState { playing, stopped }

const String API_KEY = 'AIzaSyBMI1BM4EQewTd0i265MG0xxv6PNh0pjAU';

class BookmarkScreen extends StatefulWidget {
  final Language firstLanguage = Language('en', 'English', true, true, true);
  final Language secondLanguage = Language('ko', 'Korea', true, true, true);

  BookmarkScreen({
    Key key,
  }) : super(key: key);

  @override
  CollectionsPageState createState() => CollectionsPageState(
        firstLanguage,
        secondLanguage,
      );
}

class CollectionsPageState extends State<BookmarkScreen>
    with TickerProviderStateMixin {
  final Language firstLanguage;
  final Language secondLanguage;

  CollectionsPageState(
    this.firstLanguage,
    this.secondLanguage,
  );
  final String _tabIndexIdentifier = 'collections_tab_index';
  final Key _allTabKey = const PageStorageKey('collections_all');
  final Key _featuredTabKey = const PageStorageKey('collections_featured');
  final Key _curatedTabKey = const PageStorageKey('collections_curated');

  TabController _tabController;

  //bool isGrid = true;
  bool isTTsSetup = false;
  var speechRate = 1;

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
  List<String> listDesc = new List();
  Map<String, String> mapDesc = new Map();
  String transDesc = '';

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
  /// Stored the currently searched keyword.
  String keyword;
  var txt = TextEditingController();
  String currentUserId;

  //
  GoogleTranslator _translator = new GoogleTranslator();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        currentUserId = prefs.getString('id') ?? '';
      });
    });
    _readLocal();
    _initTts();
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
  bool isRegular = false;
  var _currentTranslatedTo = "";

  SharedPreferences prefs;
  _readLocal() async {
    prefs = await SharedPreferences.getInstance();
    language = prefs.getString("language") ?? 'en-US';
    currentUserId = prefs.getString("id") ?? '';
    isRegular = prefs.getBool("isRegular") ?? false;
    speechRate = prefs.getDouble("speechRate") ?? 1;
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
  Future _speak(String desc) async {
    if (desc == null || desc == '') {
    } else {
      var result = await flutterTts.speak(desc);
      if (result == 1) setState(() => ttsState = TtsState.playing);
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  _onTextWord({String text, DocumentSnapshot document}) async {
    await _translator
        .translate(text,
            from: this.widget.firstLanguage.code,
            to: this.widget.secondLanguage.code)
        .then((translatedText) {
      transDesc = translatedText ?? '';
    });

    //_onTextFb(map: mapDesc, document: document);
  }

  _onTextMap({List<String> list, DocumentSnapshot document}) async {
    for (var item in list) {
      await _translator
          .translate(item,
              from: this.widget.firstLanguage.code,
              to: this.widget.secondLanguage.code)
          .then((translatedText) {
        Fluttertoast.showToast(msg: translatedText ?? '');
        mapDesc[item] = translatedText;
      });
    }
  }

  _translate({String text}) async {
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
        //Fluttertoast.showToast(msg: _result ?? '');

        setState(() {
          _currentTranslatedTo = _result;
          isTranslating = false;
        });
        return _result ?? '';
      } else {
        setState(() {
          _currentTranslatedTo = "Faild To Connect to internet";
          Fluttertoast.showToast(msg: _currentTranslatedTo);
          isTranslating = false;
          return _currentTranslatedTo ?? '';
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

  _translateDesc({List<String> list, DocumentSnapshot document}) async {
    for (var item in list) {
      try {
        setState(() {
          isTranslating = true;
        });
        final response = await http.get(Uri.encodeFull(
            'https://translation.googleapis.com/language/translate/v2?target=ko&key=$API_KEY&q=$item'));
        //above is Google's own api but will block after few request till that use bello api

        //final response = await http.get(Uri.encodeFull(
        //    'http://mozaffari.me/api/gtranslate/?from=${from}&to=${to}&text=${text}'));
        if (response.statusCode == 200) {
          // If the call to the server was successful, parse the JSON
          var _result = json.decode(response.body)['data']['translations'][0]
              ['translatedText'];
          mapDesc[item] = _result ?? '';

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
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (keyword != null) {
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              'Memorizing',
              style: TextStyle(fontFamily: "Gotik"),
            ),
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
                                    prefs.setDouble('speechRate', 1);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('0.8'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    flutterTts.setSpeechRate(0.8);
                                    prefs.setDouble('speechRate', 0.8);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('0.6'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    flutterTts.setSpeechRate(0.6);
                                    prefs.setDouble('speechRate', 0.6);
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
                  MdiIcons.cardsOutline,
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
                                child: Text('화질 좋은'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isRegular = true;
                                    prefs.setBool('isRegular', isRegular);
                                  });
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('화질 낮은'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    isRegular = false;
                                    prefs.setBool('isRegular', isRegular);
                                  });
                                },
                              ),
                            ],
                          ));
                },
              )
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.black87,
            elevation: 1,
            onPressed: () {
              Fluttertoast.showToast(msg: currentUserId);
            },
            label: Text(
              'memorized',
              style: TextStyle(color: Colors.white),
            ),
            icon: Icon(
              Icons.collections_bookmark,
              color: Colors.white,
            ),
          ),
          body: StreamBuilder(
            stream: Firestore.instance
                .collection('users')
                .document(currentUserId)
                .collection('memorizing-photos')
                .orderBy('timestamp', descending: true)
                //.orderBy('timestamp')
                //.where('desc', isGreaterThan: '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);

              QuerySnapshot querySnapshot = snapshot.data;
              return snapshot.hasData
                  ? Padding(
                      padding: EdgeInsets.all(1),
                      child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1),
                          itemCount: querySnapshot.documents.length,
                          itemBuilder: (context, index) {
                            print(index);
                            DocumentSnapshot document =
                                querySnapshot.documents[index];
                            listDesc = document['desc'].toString().split(' ');
                            List<String> listSlash = List();
                            for (var item in listDesc) {
                              listSlash.add(item + '/');
                            }
                            /*
                                Firestore.instance.collection('collections').document('$cid').collection('photos').document(document.documentID).updateData({'descList':listSlash});
                                listSlash.clear();
                                Firestore.instance
                                    .collection('collections')
                                    .document('$cid')
                                    .collection('photos')
                                    .document(document.documentID)
                                    .updateData({
                                  'descMap': mapDesc,
                                });
                                listDesc.clear();
                                mapDesc.clear();

                                _translateDesc(
                                    list: listDesc, document: document);

                                Firestore.instance
                                    .collection('collections')
                                    .document('$cid')
                                    .collection('photos')
                                    .document(document.documentID)
                                    .get()
                                    .then((onValue) {
                                  Firestore.instance
                                      .collection('available-collections')
                                      .document('$cid')
                                      .collection('photos')
                                      .document(document.documentID)
                                      .setData(onValue.data)
                                      .then((onValue) {
                                    Firestore.instance
                                        .collection('available-collections')
                                        .document('$cid')
                                        .collection('photos')
                                        .document(document.documentID)
                                        .updateData({'descMap': map});
                                  });
                                  Firestore.instance
                                      .collection('available-photos')
                                      .document(document.documentID)
                                      .setData(onValue.data)
                                      .then((onValue) {
                                    Firestore.instance
                                        .collection('available-photos')
                                        .document(document.documentID)
                                        .updateData({'descMap': map});
                                  });
                                });
                                */

                            /*
                                Firestore.instance
                                    .collection('photos')
                                    .document(document.documentID)
                                    .updateData({
                                  'descMap': map,
                                  //'descKr': '',
                                });
                                Firestore.instance
                                    .collection('collections')
                                    .document(document['cid'].toString())
                                    .collection('photos')
                                    .document(document.documentID)
                                    .updateData({
                                  'descMap': map,
                                  //'descKr': '',
                                });
                                list.clear();
                                map.clear();
                                */

                            return AspectRatio(
                                aspectRatio:
                                    document['width'] / document['height'],
                                child: Container(
                                    padding: EdgeInsets.all(4),
                                    child: Hero(
                                      tag: document['id'],
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: document['desc'] == null ||
                                                document['desc'] == ''
                                            ? InkWell(
                                                onTap: () {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'altDescription is null');
                                                },
                                                child: Stack(
                                                  children: <Widget>[
                                                    CachedNetworkImage(
                                                      imageUrl: isRegular
                                                          ? document[
                                                              'photoUrlRegular']
                                                          : document[
                                                              'photoUrlSmall'],
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
                                                              builder:
                                                                  (context) {
                                                                Timestamp
                                                                    timestamp =
                                                                    document[
                                                                        'date'];

                                                                return InfoSheet(
                                                                  name: document[
                                                                      'userName'],
                                                                  profileUrl:
                                                                      document[
                                                                          'profileImage'],
                                                                  );
                                                              });
                                                        },
                                                      ),
                                                    ),
                                                    document['desc'] == null ||
                                                            document['desc'] ==
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
                                                      imageUrl: isRegular
                                                          ? document[
                                                              'photoUrlRegular']
                                                          : document[
                                                              'photoUrlSmall'],
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
                                                              builder:
                                                                  (context) {
                                                                Timestamp
                                                                    timestamp =
                                                                    document[
                                                                        'date'];

                                                                return InfoSheet(
                                                                  name: document[
                                                                      'userName'],
                                                                  profileUrl:
                                                                      document[
                                                                          'profileImage'],
                                                                  );
                                                              });
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
                                                                      () {
                                                                    Firestore
                                                                        .instance
                                                                        .collection(
                                                                            'users')
                                                                        .document(
                                                                            currentUserId)
                                                                        .setData(document
                                                                            .data)
                                                                        .then(
                                                                            (onValue) {
                                                                      Fluttertoast
                                                                          .showToast(
                                                                              msg: 'upload success');
                                                                    });
                                                                  },
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
                                                                      () {
                                                                    if (!isTTsSetup) {
                                                                      flutterTts
                                                                          .setLanguage(
                                                                              language);
                                                                    }
                                                                    _speak(document[
                                                                        'desc']);
                                                                  },
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
                                                                    List<String>
                                                                        listDesc =
                                                                        List<String>.from(
                                                                            document['descList']);
                                                                    showModalBottomSheet(
                                                                        context:
                                                                            context,
                                                                        builder: (context) =>
                                                                            InfoDescListSheet(
                                                                              listDesc: listDesc,
                                                                              cid: '',
                                                                              pid: document.documentID,
                                                                            ));
                                                                  },
                                                                )
                                                              ],
                                                            ),
                                                            Container(
                                                                margin:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10),
                                                                child: Center(
                                                                    child: Text(
                                                                  document[
                                                                          'desc'] ??
                                                                      'null',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .title
                                                                      .copyWith(
                                                                        color: Colors
                                                                            .white,
                                                                        fontFamily:
                                                                            "Gotik",
                                                                        //fontWeight: FontWeight.bold
                                                                      ),
                                                                )
                                                                    /*
                                                                          RichText(
                                                                              text: TextSpan(
                                                                                  text: document['desc'] ?? 'null',
                                                                                  style: Theme.of(context).textTheme.title.copyWith(
                                                                                        color: Colors.white,
                                                                                        fontFamily: "Gotik",
                                                                                      ))),
                                                                                      */
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
        ),
      );
}
