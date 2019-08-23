import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share/share.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';
import 'screen_profiles.dart';
import 'login.dart';
import 'package:intl/intl.dart';
//import 'package:gallery/screen_purchase.dart';
import 'screen_settings.dart';
//import 'screen_guide.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ui/collections_fb.dart';
import 'translate/translate-input.dart';
import 'tabs_mine.dart';

//import 'screen_question.dart';

import 'package:gallery/const.dart';
import 'package:gallery/login.dart';
import 'package:gallery/screen_profiles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:gallery/ui/collections_fb.dart';
import 'translate/home-page.dart';
import 'ui/user_photos_fb.dart';

class DrawerItem {
  String title;
  IconData icon;
  DrawerItem(this.title, this.icon);
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

class MineTabs extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<MineTabs> {
  SharedPreferences prefs;
  String currentUserId;
  String photoUrl;
  String nickname;
  String email;
  bool isCertified;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  //version
  static const APP_STORE_URL =
      'https://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=YOUR-APP-ID&mt=8';
  static const PLAY_STORE_URL =
      'https://play.google.com/store/apps/details?id=com.careering.eightly';

  @override
  void initState() {
    super.initState();
    readLocal();
    try {
      versionCheck(context);
    } catch (e) {
      print(e);
    }
  }

  versionCheck(context) async {
    //Get Current installed version of app

    final PackageInfo info = await PackageInfo.fromPlatform();
    double currentVersion =
        double.parse(info.version.trim().replaceAll(".", ""));

    //Get Latest version info from firebase config
    final RemoteConfig remoteConfig = await RemoteConfig.instance;

    try {
      // Using default duration to force fetching from remote server.
      await remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await remoteConfig.activateFetched();
      remoteConfig.getString('force_update_current_version');
      double newVersion = double.parse(remoteConfig
          .getString('force_update_current_version')
          .trim()
          .replaceAll(".", ""));
      if (newVersion > currentVersion) {
        _showVersionDialog(context);
      } else {}
    } on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {}
  }

  _showVersionDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "UPDATE";
        String message = "더욱 편리한 어플리케이션 이용을 위해 기능을 개선하였습니다";
        String btnLabel = "OK";
        String btnLabelCancel = "CANCEL";
        return Platform.isIOS
            ? new AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  FlatButton(
                    child: Text(btnLabel),
                    onPressed: () => _launchURL(APP_STORE_URL),
                  ),
                  FlatButton(
                    child: Text(btnLabelCancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              )
            : new AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  FlatButton(
                    child: Text(btnLabel),
                    onPressed: () => _launchURL(PLAY_STORE_URL),
                  ),
                  FlatButton(
                    child: Text(btnLabelCancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
      },
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('checkEntry', true);
    currentUserId = prefs.getString('id') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('email') ?? '';
    isCertified = prefs.getBool('isCertified') ?? false;
    // Force refresh input
    setState(() {});
  }

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: '프로필', icon: MdiIcons.account),
    //const Choice(title: '설정', icon: Icons.settings),
    const Choice(title: '관리', icon: MdiIcons.chartBar),
    const Choice(title: '로그아웃', icon: Icons.exit_to_app),
  ];

  final GoogleSignIn googleSignIn = GoogleSignIn();

  void onItemMenuPress(Choice choice) {
    if (choice.title == '로그아웃') {
      handleSignOut();
    } else if (choice.title == '프로필') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    } else if (choice.title == '설정') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SettingsScreen()));
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  _accountSwitch(String uid) async {
    Firestore.instance.collection('users').document(uid).get().then((onValue) {
      Firestore.instance
          .collection('mentors')
          .document(uid)
          .setData(onValue.data);
      Fluttertoast.showToast(msg: 'success');
    });
  }

  Future<bool> onBackPress() {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: primaryColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      '앱 종료',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '앱을 종료하시겠습니까?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      '취소',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      '확인',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  _launchEMAIL(String toMailId, String subject, String body) async {
    var url = 'mailto:$toMailId?subject=$subject&body=$body';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          iconTheme: IconThemeData(color: Colors.black87),
          elevation: 1,
          backgroundColor: Colors.white,
          title: Text(
            //'RANK ${DateFormat('dd MMM').format(DateTime.now())}',
            'Enddict',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: "Sans"),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: <Widget>[
              Tab(
                icon: Icon(MdiIcons.volumeLow),
                text: 'DOING',
              ),
              Tab(
                icon: Icon(MdiIcons.volumeHigh),
                text: 'DONE',
              ),
            ],
          ),
          actions: <Widget>[
            /*
              PopupMenuButton<Choice>(
                onSelected: onItemMenuPress,
                itemBuilder: (BuildContext context) {
                  return choices.map((Choice choice) {
                    return PopupMenuItem<Choice>(
                        value: choice,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              choice.icon,
                              color: primaryColor,
                            ),
                            Container(
                              width: 10.0,
                            ),
                            Text(
                              choice.title,
                              style: TextStyle(color: primaryColor),
                            ),
                          ],
                        ));
                  }).toList();
                },
              ),
                Container(
                    child: IconButton(
                  icon: Icon(MdiIcons.accountConvert),
                  onPressed: () {
                    if (isMentor) {
                      setState(() {
                        isMentor = false;
                        prefs.setBool('isMentor', false);
                      });
                    } else {
                      Firestore.instance
                          .collection('users')
                          .document(currentUserId)
                          .updateData({'isCertified': true});
                    }
                  },
                )),
                */
            Container(
                child: IconButton(
              icon: Icon(MdiIcons.googleTranslate),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage(
                              title: "Translator",
                            )));
              },
            )),
            Container(
                child: IconButton(
              icon: Icon(MdiIcons.send),
              onPressed: () {
                Share.share(
                    "인턴뷰\n청년구직자, 면접 스크립트 여기서 확인해보세요!\n인턴/직장인, 면접 스크립트 작성하고 보상을 받으세요!\nLink: https://scriptlab27.wixsite.com/internview");
              },
            ))
          ],
        ),
        body: WillPopScope(
          child: TabBarView(
            children: <Widget>[
              UserPhotosPage(),
              UserPhotosPage(),
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {});
  }
}
