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
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tabs_main.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: new Text(
          '프로필',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: new SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerCom;
  TextEditingController controllerJob;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String photoUrl = '';
  String com = '';
  String job = '';

  bool isLoading = false;
  bool checkCom = true;
  bool checkJob = true;
  bool checkNickname = true;
  File avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeCom = new FocusNode();
  final FocusNode focusNodeJob = new FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    com = prefs.getString('com') ?? '';
    job = prefs.getString('job') ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerCom = new TextEditingController(text: com);
    controllerJob = new TextEditingController(text: job);

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
      uploadFile();
    }
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
            'photoUrl': photoUrl,
            'com': com,
            'job': job,
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
    focusNodeCom.unfocus();
    focusNodeJob.unfocus();

    setState(() {
      isLoading = true;
    });

    Firestore.instance.collection('users').document(id).updateData({
      'nickname': nickname,
      'photoUrl': photoUrl,
      'com': com,
      'job': job,
      'checkEntry': true,
    }).then((data) async {
      await prefs.setString('nickname', nickname);
      await prefs.setString('com', com);
      await prefs.setString('job', job);
      await prefs.setString('photoUrl', photoUrl);
      await prefs.setBool('checkEntry', true);

      setState(() {
        isLoading = false;
      });

      bool isMentor = prefs.getBool('isMentor');

      Fluttertoast.showToast(msg: "Update success").then((onValue) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => MainTabs()));
      });
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      (avatarImageFile == null)
                          ? (photoUrl != ''
                              ? Material(
                                  child: CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    themeColor),
                                          ),
                                          width: 90.0,
                                          height: 90.0,
                                          padding: EdgeInsets.all(20.0),
                                        ),
                                    imageUrl: photoUrl,
                                    width: 90.0,
                                    height: 90.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(45.0)),
                                  clipBehavior: Clip.hardEdge,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 90.0,
                                  color: greyColor,
                                ))
                          : Material(
                              child: Image.file(
                                avatarImageFile,
                                width: 90.0,
                                height: 90.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(45.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: primaryColor.withOpacity(0.5),
                        ),
                        onPressed: getImage,
                        padding: EdgeInsets.all(30.0),
                        splashColor: Colors.transparent,
                        highlightColor: greyColor,
                        iconSize: 30.0,
                      ),
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),

              // Input
              Column(
                children: <Widget>[
                  // Username
                  Container(
                    child: Text(
                      'Nickname',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: primaryColor),
                      child: TextField(
                        enabled: true,
                        decoration: InputDecoration(
                          errorText: checkNickname
                              ? null
                              : 'This field Can\'t Be Empty',
                          hintText: '닉네임을 적어주세요',
                          contentPadding: new EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value) {
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),

                  // About me
                  Container(
                    child: Text(
                      'Com',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10.0, top: 30.0, bottom: 5.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: primaryColor),
                      child: TextField(
                        decoration: InputDecoration(
                          errorText:
                              checkCom ? null : 'This field Can\'t Be Empty',
                          hintText: 'A message about your idol',
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        controller: controllerCom,
                        onChanged: (value) {
                          com = value;
                        },
                        focusNode: focusNodeCom,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),
                  // About me
                  Container(
                    child: Text(
                      'Job',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10.0, top: 30.0, bottom: 5.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: primaryColor),
                      child: TextField(
                        decoration: InputDecoration(
                          errorText:
                              checkJob ? null : 'This field Can\'t Be Empty',
                          hintText: 'A message about your idol',
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: greyColor),
                        ),
                        controller: controllerJob,
                        onChanged: (value) {
                          job = value;
                        },
                        focusNode: focusNodeJob,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),

              // Button
              Container(
                child: FloatingActionButton.extended(
                  elevation: 0,
                  backgroundColor: Colors.black87,
                  icon: Icon(MdiIcons.update),
                  onPressed: () {
                    if (controllerNickname.text.isNotEmpty &&
                        controllerCom.text.isNotEmpty &&
                        controllerJob.text.isNotEmpty) {
                      setState(() {
                        checkCom = true;
                        checkNickname = true;
                        checkJob = true;
                      });
                      handleUpdateData();
                    } else {
                      setState(() {
                        checkCom = false;
                        checkNickname = false;
                        checkJob = false;
                      });
                    }
                  },
                  label: Text(
                    'UPDATE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                margin: EdgeInsets.only(top: 50.0, bottom: 50.0),
              ),
            ],
          ),
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        ),

        // Loading
        Positioned(
          child: isLoading
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : Container(),
        ),
      ],
    );
  }
}
