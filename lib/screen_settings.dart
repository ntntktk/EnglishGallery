import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery/const.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'const.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;
  TextEditingController controllerCom;
  TextEditingController controllerJob;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String com = '';
  String job = '';
  String photoUrl = '';
  String uniMail = '';
  String email = '';

  bool isLoading = false;
  bool isApplicant = false;
  bool isNotificationOn = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();
  final FocusNode focusNodeCom = new FocusNode();
  final FocusNode focusNodeJob = new FocusNode();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();

    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    com = prefs.getString('com') ?? '';
    job = prefs.getString('job') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    isNotificationOn = prefs.getBool('notification') ?? true;
    email = prefs.getString('email') ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);
    controllerCom = new TextEditingController(text: com);
    controllerJob = new TextEditingController(text: job);

    Firestore.instance.collection('users').document(id).get().then((onValue) {
      if (onValue.data['isApplicant']) {
        setState(() {
          isApplicant = true;
        });
      } else {
        setState(() {
          isApplicant = false;
        });
      }
    });

    // Force refresh input
    setState(() {});
  }

  Future getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    String fileName = id;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          Firestore.instance.collection('users').document(id).updateData({
            'nickname': nickname,
            'aboutMe': aboutMe,
            'com': com,
            'job': job,
            'photoUrl': photoUrl
          }).then((data) async {
            await prefs.setString('photoUrl', photoUrl);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Upload success");
          }).catchError((err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: err.toString());
          });
        }, onError: (err) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'This file is not an image');
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();
    focusNodeCom.unfocus();
    focusNodeJob.unfocus();

    setState(() {
      isLoading = true;
    });

    Firestore.instance.collection('users').document(id).updateData({
      'nickname': nickname,
      'aboutMe': aboutMe,
      'com': com,
      'job': job,
      'photoUrl': photoUrl,
      'uniMail': uniMail
    }).then((data) async {
      await prefs.setString('nickname', nickname);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('com', com);
      await prefs.setString('job', job);
      await prefs.setString('photoUrl', photoUrl);
      await prefs.setString('uniMail', uniMail);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    }).then((onValue) {
      Navigator.pop(context);
    });
  }

  addMentor() {
    showDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
              content: Text('환영합니다,\n후배들을 위해 좋은 멘토가 되어주세요'),
              actions: <Widget>[
                FlatButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text('확인'),
                  onPressed: () {
                    //user/isMentor
                    Firestore.instance
                        .collection('users')
                        .document(id)
                        .updateData({'isMentor': true});

                    //mentors
                    Firestore.instance
                        .collection('users')
                        .document(id)
                        .get()
                        .then((onValue) {
                      Firestore.instance
                          .collection('mentors')
                          .document(id)
                          .setData(onValue.data);
                    }).then((onValue) {
                      //mentors-update
                      Firestore.instance
                          .collection('mentors')
                          .document(id)
                          .updateData({
                        'doc': '',
                        'comUrl': '',
                        'timestamp':
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'youtubeUrl': 'https://youtube.com/',
                        'dropboxUrl': 'https://dropbox.com/',
                        'members': [],
                        'isNew': {},
                        'isOn': {},
                      });

                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => MyApp()));
                    });
                  },
                )
              ],
            ));
  }

  setNotification() {
    showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
              content: Text('알림 설정을 변경하시겠습니까?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text('확인'),
                  onPressed: () {
                    if (isNotificationOn) {
                      Navigator.pop(context);
                      prefs.setBool('notification', false);
                      isNotificationOn = false;
                      setState(() {});
                    } else {
                      Navigator.pop(context);
                      prefs.setBool('notification', true);
                      isNotificationOn = true;
                      setState(() {});
                    }
                  },
                ),
              ],
            ));
  }

  deleteAll() {
    Firestore.instance
        .collection('users')
        .document(id)
        .delete()
        .then((onValue) {
      handleSignOut();
    });
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        title: new Text(
          '설정',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                /*
                Card(
                  elevation: 1.0,
                  child: Container(
                    decoration: BoxDecoration(),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.only(right: 12.0),
                        decoration: new BoxDecoration(
                            border: new Border(
                                right: new BorderSide(
                                    width: 1.0, color: Colors.black))),
                        child: Icon(MdiIcons.bellOutline, color: Colors.black),
                      ),
                      title: Text(
                        '정보 수신 동의',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Checkbox(
                        value: prefs.getBool('feature_enabled') ?? true,
                        onChanged: (val) {
                          showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                    content: Text('정보 수신 설정을 변경하시겠습니까?'),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text('취소'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      FlatButton(
                                        child: Text('확인'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            prefs.setBool(
                                                'feature_enabled', val);
                                          });
                                        },
                                      ),
                                    ],
                                  ));
                        },
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
                */
                Card(
                  elevation: 1.0,
                  child: Container(
                    decoration: BoxDecoration(),
                    child: ListTile(
                      onTap: () {
                        launch('https://www.careeringlab.com/privacy-1');
                      },
                      leading: Container(
                        padding: EdgeInsets.only(right: 12.0),
                        decoration: new BoxDecoration(
                            border: new Border(
                                right: new BorderSide(
                                    width: 1.0, color: Colors.black))),
                        child: Icon(Icons.info_outline, color: Colors.black),
                      ),
                      title: Text(
                        "개인정보 처리방침",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  elevation: 1.0,
                  child: Container(
                    decoration: BoxDecoration(),
                    child: ListTile(
                      onTap: () {
                        launch('https://www.careeringlab.com/terms');
                      },
                      leading: Container(
                        padding: EdgeInsets.only(right: 12.0),
                        decoration: new BoxDecoration(
                            border: new Border(
                                right: new BorderSide(
                                    width: 1.0, color: Colors.black))),
                        child: Icon(MdiIcons.text, color: Colors.black),
                      ),
                      title: Text(
                        "이용약관",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  elevation: 1.0,
                  child: Container(
                    decoration: BoxDecoration(),
                    child: ListTile(
                      onTap: () {
                        var url =
                            'mailto:${'scriptlab27@gmail.com'}?subject=${'[탈퇴신청]' '$nickname 님' }&body=${'닉네임:$nickname\n가입메일:$email\n불편사항:\n\n그동안 이용해 주셔서 감사합니다\n이용 중 혹시 불편사항 있으셨다면 말씀 부탁드립니다\n탈퇴 진행 후 확인 메일을 발송드릴 예정이며, 언제든 이 서비스가 필요하실 때 다시 찾아주시기 바랍니다'}';
                        launch(url);
                        /*
                    
                      showCupertinoDialog(
                        context: context,
                        builder: (context)=>CupertinoAlertDialog(
                          content: Text('탈퇴하시겠습니까?'),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('취소'),
                              onPressed: (){
                                Navigator.pop(context);
                              },
                            ),
                            FlatButton(
                              child: Text('확인'),
                              onPressed: (){
                                Navigator.pop(context);
                                deleteAll();
                              },
                            )
                          ],
                        )
                      );
                    */
                      },
                      leading: Container(
                        padding: EdgeInsets.only(right: 12.0),
                        decoration: new BoxDecoration(
                            border: new Border(
                                right: new BorderSide(
                                    width: 1.0, color: Colors.black))),
                        child: Icon(MdiIcons.exitRun, color: Colors.grey),
                      ),
                      title: Text(
                        "탈퇴하기",
                        style: TextStyle(color: greyColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[],
          ),

          // Loading
          Positioned(
            child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)),
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
