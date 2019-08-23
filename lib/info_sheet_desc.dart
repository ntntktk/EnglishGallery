import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
//
import 'dart:async';

import 'package:http/http.dart';
import 'package:gallery/api/collection.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/local_variables.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
//tranlate
import 'package:translator/translator.dart';
import 'models/language.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bottom-sheet displaying info for a given [image].

enum TtsState { playing, stopped }

const String API_KEY = 'AIzaSyBMI1BM4EQewTd0i265MG0xxv6PNh0pjAU';

class InfoDescSheet extends StatefulWidget {
  final String desc;
  final Language firstLanguage = Language('en', 'English', true, true, true);
  final Language secondLanguage = Language('ko', 'Korea', true, true, true);

  InfoDescSheet({Key key, @required this.desc}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return InfoDescSheetState(desc, firstLanguage, secondLanguage);
  }
}

class InfoDescSheetState extends State<InfoDescSheet> {
  final String desc;
  final Language firstLanguage;
  final Language secondLanguage;

  InfoDescSheetState(this.desc, this.firstLanguage, this.secondLanguage);

  String transDesc;
  bool isTranslating = false;
  var _currentTranslatedTo = "";

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

  //translate
  TextEditingController _textEditingController = TextEditingController();
  String _textTranslated = "";
  GoogleTranslator _translator = new GoogleTranslator();

  _onTextChanged({String text}) {
    if (text != "") {
      _translator
          .translate(text,
              from: this.widget.firstLanguage.code,
              to: this.widget.secondLanguage.code)
          .then((translatedText) {
        this.setState(() {
          this._textTranslated = translatedText;
        });
      });
    } else {
      this.setState(() {
        this._textTranslated = "";
      });
    }
  }

  _onTextToast({String text}) {
    if (text != "") {
      _translator
          .translate(text,
              from: this.widget.firstLanguage.code,
              to: this.widget.secondLanguage.code)
          .then((translatedText) {
        Fluttertoast.showToast(msg: translatedText);
      });
    } else {
      this.setState(() {
        this._textTranslated = "";
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initTts();
    _translateWidget(text: desc);
    _onTextChanged(text: desc);
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

  _translateWidget({String text}) async {
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
        transDesc = _result ?? '';

        setState(() {
          _currentTranslatedTo = _result;
          isTranslating = false;
        });
      } else {
        setState(() {
          _currentTranslatedTo = "Faild To Connect to internet";
          isTranslating = false;
          print(_currentTranslatedTo);
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

  void _translatePapago({String text}) async {
    var baseUrl = 'https://naveropenapi.apigw.ntruss.com/nmt/v1/translation';
    const client_id = 'o6ffxnrrrk';
    const client_secret = 'roIRmNNHkyLwkUNc8wcuXpF8v9FiOtYVz6LHdAX2';
    const headers = {
      'X-Naver-Client-Id': client_id,
      'X-Naver-Client-Secret': client_secret
    };
    final Response response = await get("$baseUrl", headers: headers);
    Fluttertoast.showToast(
        msg: '${json.decode(utf8.decode(response.bodyBytes))}');
    //final List decodedBody = json.decode(utf8.decode(response.bodyBytes));
    /*

    try {
      setState(() {
        isTranslating = true;
      });
      final response = await http.get(Uri.encodeFull(
          'https://openapi.naver.com/v1/papago/n2mt?target=ko&key=$API_KEY&q=$text'));
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
    */
  }

  @override
  Widget build(BuildContext context) {
    List<String> listDesc = desc.split(' ');

    return /*Container*/ Card(
      margin: const EdgeInsets.only(top: 16.0),
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10.0),
            topRight: const Radius.circular(10.0)),
      ),
      child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: desc != null
              ? <Widget>[
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Powered by Google Translate',
                        style: Theme.of(context)
                            .textTheme
                            .subtitle
                            .copyWith(fontFamily: "Sans"),
                      ),
                    ),
                  ),
                  /*
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Text(
                      this._textTranslated ?? 'loading..',
                      style: Theme.of(context)
                          .textTheme
                          .title
                          .copyWith(fontFamily: "Sans"),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  */
                  Container(
                    height: 64,
                    child: new ListView.builder(
                      itemCount: listDesc.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Container(
                            margin: EdgeInsets.all(10),
                            child: InkWell(
                              onLongPress: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                          children: <Widget>[
                                            FlatButton(
                                              child: Text('OK'),
                                              onPressed: () {},
                                            ),
                                            FlatButton(
                                              child: Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            )
                                          ],
                                        ));
                              },
                              child: FloatingActionButton.extended(
                                heroTag: null,
                                elevation: 1,
                                backgroundColor: Colors.white,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      listDesc[index],
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontFamily: "Gotik",
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                onPressed: () {
                                  _onTextToast(text: listDesc[index]);
                                },
                              ),
                            ));
                      },
                      /*

                      <Widget>[
                        new Container(
                          height: 80.0,
                          child: new ListView(
                            scrollDirection: Axis.horizontal,
                            children: new List.generate(10, (int index) {
                              return new Card(
                                color: Colors.blue[index * 100],
                                child: new Container(
                                  width: 50.0,
                                  height: 50.0,
                                  child: new Text("$index"),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                        */
                    ),
                  ), // show description
                  //_buildDescriptionWidget(image.getDescription()),
                  // show location
                  //_buildLocationWidget(image.getLocation()),
                  // show exif data
                  //_buildExifWidget(image.getExif()),
                  // filter null views
                ].where((w) => w != null).toList()
              : <Widget>[CircularProgressIndicator()]),
      /*decoration: new BoxDecoration(
            color: Colors.grey[50],
            borderRadius: new BorderRadius.only(
                topLeft: const Radius.circular(10.0),
                topRight: const Radius.circular(10.0))),*/
    );
  }

  /// Builds a round image widget displaying a profile image from a given [url].
  Widget _buildUserProfileImage(String url) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircleAvatar(
          backgroundImage: NetworkImage(url),
        ),
      );

  /// Builds widget displaying a given [description] for an image.
  Widget _buildDescriptionWidget(String description) => description != null
      ? Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
          child: Text(
            '$description',
            style: TextStyle(
              color: Colors.black38,
              fontSize: 16.0,
              letterSpacing: 0.1,
            ),
          ),
        )
      : null;

  /// Builds a widget displaying the [location], where the image was captured.
  Widget _buildLocationWidget(Location location) => location != null
      ? Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
          child: Row(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.black54,
                  )),
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '${location.getCity()}, ${location.getCountry()}'
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ],
          ),
        )
      : null;

  /// Builds a widget displaying all [exif] data
  Widget _buildExifWidget(Exif exif) => exif != null
      ? Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
          child: Row(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.photo_camera,
                    color: Colors.black54,
                  )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(
                          left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
                      child: Text(
                        '${exif.getModel()}',
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold),
                      )),
                  Row(
                    children: <Widget>[
                      // display exif info
                      _buildExifInfoItem('ƒ${exif.getAperture()}'),
                      _buildExifInfoItem('${exif.getExposureTime()}'),
                      _buildExifInfoItem('${exif.getFocalLength()}mm'),
                      _buildExifInfoItem('ISO${exif.getIso()}'),
                    ],
                  ),
                ],
              )
            ].where((w) => w != null).toList(),
          ))
      : null;

  /// Builds exif info item that displays given [data].
  Widget _buildExifInfoItem(String data) => data != null
      ? Padding(
          padding:
              EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
          child: Text(
            data,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.black26,
                fontSize: 12.0,
                fontWeight: FontWeight.bold),
          ))
      : null;
}
