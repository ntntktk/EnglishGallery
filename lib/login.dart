import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs_main.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/gestures.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'const.dart';

const APP_STORE_URL =
    'https://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=YOUR-APP-ID&mt=8';
const PLAY_STORE_URL =
    'https://play.google.com/store/apps/details?id=YOUR-APP-ID';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnglishGallery',
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      home: LoginScreen(title: 'EnglishGallery'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = true;
  bool isMentor;
  bool isCertified;

  FirebaseUser currentUser;

  //version
  static const APP_STORE_URL =
      'https://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=YOUR-APP-ID&mt=8';
  static const PLAY_STORE_URL =
      'https://play.google.com/store/apps/details?id=com.careering.eightly';

  @override
  void initState() {
    super.initState();
    isSignedIn();
    /*
    try {
      versionCheck(context);
    } catch (e) {
      print(e);
    }
    */
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
      } else {
        isSignedIn();
      }
    } on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      print(exception);
    }
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainTabs()),
                      );
                    },
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
                      isSignedIn();
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

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabs()),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser =
        await firebaseAuth.signInWithCredential(credential);

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({
          'id': firebaseUser.uid,
          'nickname': firebaseUser.displayName,
          'email': firebaseUser.email,
          'photoUrl': firebaseUser.photoUrl,
          'com': '',
          'job': '',
          'checkEntry': false,
          'checkContract': false,
          'isCertified': false,
          'isMentor': false,
          'isIntern': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          //mentor
          'video': '',
          'script': '',
          'certificate': '',
          'contract': '',
          'questions': [],
          'countPurchased': 0,
          'countPaid': 0,
          'countAnswer': 0,
          'account': ''
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
        await prefs.setString('email', currentUser.email);
        await prefs.setString('com', '');
        await prefs.setString('job', '');
        await prefs.setBool('checkEntry', false);
        await prefs.setBool('isMentor', false);
        await prefs.setBool('isCertified', false);
      } else {
        // Write data to local
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('email', documents[0]['email']);
        await prefs.setString('com', documents[0]['com']);
        await prefs.setString('job', documents[0]['job']);
        await prefs.setBool('checkEntry', documents[0]['checkEntry']);
        await prefs.setBool('isMentor', documents[0]['isMentor']);
        await prefs.setBool('isCertified', documents[0]['isCertified']);
      }
      this.setState(() {
        isLoading = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainTabs()),
      );
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
              decoration: new BoxDecoration(
                  image: DecorationImage(
                      image: new AssetImage('res/image/bg_splash_gallery.png'),
                      fit: BoxFit.cover)),
              child: Column(
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    alignment: Alignment.bottomCenter,
                    margin: EdgeInsets.all(10.0),
                    child: Text(
                      'ENGLISH\nGALLERY',
                      style: TextStyle(
                          fontFamily: 'Gotik',
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: FloatingActionButton.extended(
                          elevation: 0,
                          backgroundColor: Color(0xffdd4b39).withOpacity(0.9),
                          icon: Icon(
                            MdiIcons.googlePlus,
                            color: Colors.white,
                          ),
                          onPressed: handleSignIn,
                          label: Text(
                            'SIGN IN WITH GOOGLE',
                            style:
                                TextStyle(fontSize: 16.0, color: Colors.white),
                          ),
                          //color: Color(0xffdd4b39),
                          //highlightColor: Color(0xffff7f7f),
                          //splashColor: Colors.transparent,
                          //textColor: Colors.white,
                          //padding:EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)
                        ),
                      ),
                      Center(
                          child: Container(
                        margin: EdgeInsets.all(10.0),
                        child: RichText(
                          text: new TextSpan(
                            children: [
                              new TextSpan(
                                text: '회원가입 시 ',
                                style: new TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                              new TextSpan(
                                text: '개인정보처리방침',
                                style: new TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.white.withOpacity(0.8)),
                                recognizer: new TapGestureRecognizer()
                                  ..onTap = () {
                                    launch(
                                        'https://www.careeringlab.com/privacy-1');
                                  },
                              ),
                              new TextSpan(
                                text: '을 읽었으며,',
                                style: new TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                              new TextSpan(
                                text: '\n이용약관',
                                style: new TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.white.withOpacity(0.8)),
                                recognizer: new TapGestureRecognizer()
                                  ..onTap = () {
                                    launch(
                                        'https://www.careeringlab.com/terms');
                                  },
                              ),
                              new TextSpan(
                                text: '에 동의하신 것으로 간주됩니다.',
                                style: new TextStyle(
                                    color: Colors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ))
                    ],
                  )),
                ],
              )),
          Container(
            alignment: Alignment.bottomRight,
            child: Text(
              'Photo by Drew Graham on Unsplash',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),

          // Loading
          Positioned(
            child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ),
                    color: Colors.white.withOpacity(0.8),
                  )
                : Container(),
          ),
        ],
      ),
    );
  }
}
