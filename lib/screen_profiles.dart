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
//import 'main.2.dart';
import 'package:flutter/cupertino.dart';
//import 'package:numberpicker/numberpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';
import 'package:intl/intl.dart';
import 'screen_settings.dart';

//iap
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              MdiIcons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          )
        ],
        elevation: 0,
        backgroundColor: Colors.black87,
        title: new Text(
          '프로필',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: new Profile(),
    );
  }
}

class Profile extends StatefulWidget {
  @override
  State createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<Profile> {
  TextEditingController controllerNickname;
  TextEditingController controllerCom;
  TextEditingController controllerJob;
  TextEditingController controllerComment;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String photoUrl = '';
  String com = '';
  String job = '';
  String comment = '';
  int playCoin;

  bool isLoading = false;
  bool checkNickname = true;
  bool checkCom = true;
  bool checkJob = true;
  bool checkComment = true;
  bool isMentor;
  bool isCertified = false;

  File avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeCom = new FocusNode();
  final FocusNode focusNodeJob = new FocusNode();
  final FocusNode focusNodeComment = new FocusNode();

  var dateFormat;

  //iap
  final List<String> _productLists = Platform.isAndroid
      ? [
          'careering_purchase_1',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';
  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  //numberpicker
  int _currentPrice = 1;
  String today;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    readLocal();
    //initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterInappPurchase.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // prepare
    var result = await FlutterInappPurchase.initConnection;
    print('result: $result');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // refresh items for android
    String msg = await FlutterInappPurchase.consumeAllItems;
    print('consumeAllItems: $msg');
  }

  Future<Null> _buyProduct(IAPItem item) async {
    try {
      await FlutterInappPurchase.buyProduct(item.productId).then((onValue) {
        if (onValue.productId == 'careering_purchase_1') {
          Fluttertoast.showToast(msg: 'true');
          Firestore.instance
              .collection('users')
              .document(id)
              .updateData({'pointCoin': 500});
        }
      }).catchError((onError) {
        print('error: ${onError.toString()}');
      });
    } catch (error) {
      print('$error');
    }
  }

  Future<Null> _getProduct() async {
    List<IAPItem> items = await FlutterInappPurchase.getProducts(_productLists);
    for (var item in items) {
      try {
        await FlutterInappPurchase.buyProduct(item.productId).then((onValue) {
          if (onValue.productId == 'careering_purchase_1') {
            Firestore.instance
                .collection('users')
                .document(id)
                .updateData({'pointCoin': 500});
          }
        }).catchError((onError) {
          print('error: ${onError.toString()}');
        });
      } catch (error) {
        print('$error');
      }
      //print('${item.toString()}');
      //this._items.add(item);
    }

    setState(() {
      this._items = items;
      this._purchases = [];
    });
  }

  Future<Null> _getPurchases() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.getAvailablePurchases();
    for (var item in items) {
      print('${item.toString()}');
      this._purchases.add(item);
    }

    setState(() {
      this._items = [];
      this._purchases = items;
    });
  }

  Future<Null> _getPurchaseHistory() async {
    List<PurchasedItem> items = await FlutterInappPurchase.getPurchaseHistory();
    for (var item in items) {
      print('${item.toString()}');
      this._purchases.add(item);
    }

    setState(() {
      this._items = [];
      this._purchases = items;
    });
  }

  List<Widget> _renderInApps() {
    List<Widget> widgets = this
        ._items
        .map((item) => Container(
              margin: EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    FlatButton(
                      color: Colors.orange,
                      onPressed: () {
                        print("---------- Buy Item Button Pressed");
                        this._buyProduct(item);
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 48.0,
                              alignment: Alignment(-1.0, 0.0),
                              child: Text('Buy Item'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
    return widgets;
  }

  List<Widget> _renderPurchases() {
    List<Widget> widgets = this
        ._purchases
        .map((item) => Container(
              margin: EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ))
        .toList();
    return widgets;
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    com = prefs.getString('com') ?? '';
    job = prefs.getString('job') ?? '';
    comment = prefs.getString('comment') ?? '';
    playCoin = prefs.getInt('playCoin') ?? 0;
    isMentor = prefs.getBool('isMentor');

    dateFormat = DateFormat('yyyyMMdd').format(DateTime.now());

    Firestore.instance.collection('users').document(id).get().then((onValue) {
      if (onValue.data['isCertified']) {
        setState(() {
          isCertified = true;
        });
      } else {
        setState(() {
          prefs.setBool('isMentor', false);
        });
      }
    });

    controllerNickname = new TextEditingController(text: nickname);
    controllerCom = new TextEditingController(text: com);
    controllerJob = new TextEditingController(text: job);
    controllerComment = new TextEditingController(text: comment);

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
          if (isMentor) {
            Firestore.instance.collection('mentors').document(id).updateData({
              'nickname': nickname,
              'com': com,
              'job': job,
              'comment': comment,
              'photoUrl': photoUrl
            }).then((data) async {
              Firestore.instance
                  .collection('purchases')
                  .where('mid', isEqualTo: id)
                  .getDocuments()
                  .then((onValue) {
                onValue.documents.forEach((f) {
                  Firestore.instance
                      .collection('purchases')
                      .document(f.documentID)
                      .updateData({'photoUrl': photoUrl});
                });
              });

              Firestore.instance
                  .collection('answers')
                  .where('id', isEqualTo: id)
                  .getDocuments()
                  .then((onValue) {
                onValue.documents.forEach((f) {
                  Firestore.instance
                      .collection('answers')
                      .document(f.documentID)
                      .updateData({'photoUrl': photoUrl});
                });
              });

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
          } else {
            Firestore.instance.collection('users').document(id).updateData({
              'nickname': nickname,
              'com': com,
              'job': job,
              'comment': comment,
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
          }
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
    focusNodeComment.unfocus();

    setState(() {
      isLoading = true;
    });
    if (isMentor) {
      Firestore.instance
          .collection('answers')
          .where('id', isEqualTo: id)
          .getDocuments()
          .then((onValue) {
        onValue.documents.forEach((f) {
          Firestore.instance
              .collection('answers')
              .document(f.documentID)
              .updateData({
            'nickname': nickname,
            'com': com,
            'job': job,
            'comment': comment,
            'photoUrl': photoUrl
          });
        });
      });
      Firestore.instance.collection('mentors').document(id).updateData({
        'nickname': nickname,
        'com': com,
        'job': job,
        'comment': comment,
        'photoUrl': photoUrl
      }).then((data) async {
        await prefs.setString('nickname', nickname);
        await prefs.setString('com', com);
        await prefs.setString('job', job);
        await prefs.setString('comment', comment);
        await prefs.setString('photoUrl', photoUrl);

        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: "Update success").then((onValue) {
          Navigator.of(context).pop();
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: err.toString());
      });
    } else {
      Firestore.instance.collection('users').document(id).updateData({
        'nickname': nickname,
        'com': com,
        'job': job,
        'comment': comment,
        'photoUrl': photoUrl
      }).then((data) async {
        await prefs.setString('nickname', nickname);
        await prefs.setString('com', com);
        await prefs.setString('job', job);
        await prefs.setString('comment', comment);
        await prefs.setString('photoUrl', photoUrl);

        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: "Update success").then((onValue) {
          Navigator.of(context).pop();
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: err.toString());
      });
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
                        onPressed: () {
                          getImage();
                        },
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
                        enabled: isMentor ? false : true,
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
                        enabled: isMentor ? false : true,
                        decoration: InputDecoration(
                          errorText:
                              checkCom ? null : 'This field Can\'t Be Empty',
                          hintText: '희망 회사를 적어주세요',
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
                        enabled: isMentor ? false : true,
                        decoration: InputDecoration(
                          errorText:
                              checkJob ? null : 'This field Can\'t Be Empty',
                          hintText: '희망 직무를 적어주세요',
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
                  // About me
                  false
                      ? Container(
                          child: Text(
                            'Comment',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: primaryColor),
                          ),
                          margin: EdgeInsets.only(
                              left: 10.0, top: 30.0, bottom: 5.0),
                        )
                      : Container(),
                  false
                      ? Container(
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(primaryColor: primaryColor),
                            child: TextField(
                              enabled: isMentor ? false : true,
                              decoration: InputDecoration(
                                errorText: checkComment
                                    ? null
                                    : 'This field Can\'t Be Empty',
                                hintText: '소개하고픈 멘트를 적어주세요',
                                contentPadding: EdgeInsets.all(5.0),
                                hintStyle: TextStyle(color: greyColor),
                              ),
                              controller: controllerComment,
                              onChanged: (value) {
                                comment = value;
                              },
                              focusNode: focusNodeComment,
                            ),
                          ),
                          margin: EdgeInsets.only(left: 30.0, right: 30.0),
                        )
                      : Container(),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              // Button
              !isMentor
                  ? Container(
                      child: FloatingActionButton.extended(
                        elevation: 0,
                        heroTag: null,
                        icon: Icon(MdiIcons.update),
                        onPressed: () {
                          if (controllerNickname.text.isNotEmpty &&
                              controllerCom.text.isNotEmpty &&
                              controllerJob.text.isNotEmpty) {
                            setState(() {
                              checkNickname = true;
                              checkCom = true;
                              checkJob = true;
                              checkComment = true;
                            });
                            handleUpdateData();
                          } else {
                            setState(() {
                              checkNickname = false;
                              checkCom = false;
                              checkJob = false;
                              checkComment = false;
                            });
                          }
                        },
                        label: Text(
                          'UPDATE',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        backgroundColor: Colors.black87,
                      ),
                      margin: EdgeInsets.only(
                        top: 50.0,
                      ),
                    )
                  : Container()
              /*
                   Container(
                      child: FloatingActionButton.extended(
                          backgroundColor: Colors.black87,
                          elevation: 1,
                          icon: Icon(MdiIcons.instagram),
                          onPressed: () {
                            launch('https://instagram.com/');
                          },
                          label: Text('CONTACT')),
                      margin: EdgeInsets.only(
                        top: 50.0,
                      ),
                    )*/
              ,
              // Button
              false
                  ? Container(
                      child: FlatButton(
                        onPressed: () {
                          prefs.setBool('isMentor', true);
                          isMentor = prefs.getBool('isMentor');

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
                            handleSignOut();
                            Fluttertoast.showToast(
                                msg: '멘토로 등록되었습니다. 재로그인 해주세요');
                          });
                        },
                        child: Text(
                          'MENTOR',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        color: primaryColor,
                        highlightColor: new Color(0xff8d93a0),
                        splashColor: Colors.transparent,
                        textColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                      ),
                    )
                  : Container(),
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
