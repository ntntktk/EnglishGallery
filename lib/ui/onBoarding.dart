import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery/Library/intro_views_flutter-2.4.0/lib/Models/page_view_model.dart';
import 'package:gallery/Library/intro_views_flutter-2.4.0/lib/intro_views_flutter.dart';
import '../tabs_main.dart';
import '../order_sheet.dart';
import '../const.dart';
import 'package:gallery/cookie_button.dart';
import 'package:fluttertoast/fluttertoast.dart';

//iap
import 'package:flutter/services.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnBoarding extends StatefulWidget {
  @override
  _OnBoardingState createState() => _OnBoardingState();
}

var _fontHeaderStyle = TextStyle(
    fontFamily: "Popins",
    fontSize: 21.0,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
    letterSpacing: 1.5);

var _fontDescriptionStyle = TextStyle(
    fontFamily: "Sans",
    fontSize: 15.0,
    color: Colors.black26,
    fontWeight: FontWeight.w400);

///
/// Page View Model for on boarding
///
final pages = [
  new PageViewModel(
      pageColor: Colors.white,
      iconColor: Colors.black,
      bubbleBackgroundColor: Colors.black,
      title: Text(
        'E-Commerce App',
        style: _fontHeaderStyle,
      ),
      body: Container(
        height: 250.0,
        child: Text(
            'E commerce application template \nbuy this code template in codecanyon',
            textAlign: TextAlign.center,
            style: _fontDescriptionStyle),
      ),
      mainImage: Image.asset(
        'res/image/IlustrasiOnBoarding1.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      )),
  new PageViewModel(
      pageColor: Colors.white,
      iconColor: Colors.black,
      bubbleBackgroundColor: Colors.black,
      title: Text(
        'Choose Item',
        style: _fontHeaderStyle,
      ),
      body: Container(
        height: 250.0,
        child: Text(
            'Choose Items wherever you are with this application to make life easier',
            textAlign: TextAlign.center,
            style: _fontDescriptionStyle),
      ),
      mainImage: Image.asset(
        'res/image/IlustrasiOnBoarding2.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      )),
  new PageViewModel(
      pageColor: Colors.white,
      iconColor: Colors.black,
      bubbleBackgroundColor: Colors.black,
      title: Text(
        'Buy Item',
        style: _fontHeaderStyle,
      ),
      body: Container(
        height: 250.0,
        child: Text(
            'Shop from thousand brands in the world \n in one application at throwaway \nprices ',
            textAlign: TextAlign.center,
            style: _fontDescriptionStyle),
      ),
      mainImage: Image.asset(
        'res/image/IlustrasiOnBoarding3.png',
        height: 285.0,
        width: 285.0,
        alignment: Alignment.center,
      )),
];

class _OnBoardingState extends State<OnBoarding> {
  SharedPreferences prefs;
  String currentUserId;

  //iap
  final List<String> _productLists = Platform.isAndroid
      ? [
          'android.test.purchased',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';
  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    readLocal();
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('id') ?? '';
    setState(() {});
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
      PurchasedItem purchased =
          await FlutterInappPurchase.buyProduct(item.productId);
      print('purchased: ${purchased.toString()}');
    } catch (error) {
      print('$error');
    }
  }

  Future<Null> _getProduct() async {
    List<IAPItem> items = await FlutterInappPurchase.getProducts(_productLists);
    for (var item in items) {
      Fluttertoast.showToast(msg: item.productId);
      /*
      try {
        await FlutterInappPurchase.buyProduct(item.productId).then((onValue) {
          if (onValue.productId == 'android.test.purchased') {
            Fluttertoast.showToast(
                msg: DateTime.now().millisecondsSinceEpoch.toString());
          }
        }).catchError((onError) {
          print('error: ${onError.toString()}');
        });
      } catch (error) {
        print('$error');
      }
      */
      this._items.add(item);
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

  _showOrderSheet(BuildContext context) {
    initPlatformState();

    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        context: context,
        builder: (context) => Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20.0),
                      topRight: const Radius.circular(20.0))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10, top: 10),
                      child: _title(context),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                          minHeight: 300,
                          maxHeight: MediaQuery.of(context).size.height,
                          maxWidth: MediaQuery.of(context).size.width),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _ShippingInformation(),
                            _LineDivider(),
                            _PaymentTotal(),
                            _LineDivider(),
                            _RefundInformation(),
                            _payButtons(context),
                          ]),
                    ),
                  ]),
            ));
  }

  Widget _title(context) =>
      Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Container(
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close),
                color: greyColor)),
        Container(
          child: Expanded(
            child: Text(
              "Place your order",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(padding: EdgeInsets.only(right: 56)),
      ]);

  Widget _payButtons(context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          CookieButton(
            text: "Pay with card",
            onPressed: () {
              Navigator.pop(context, PaymentType.cardPayment);
            },
          ),
          Container(
            height: 64,
            width: MediaQuery.of(context).size.width * .4,
            child: RaisedButton(
              onPressed: true
                  ? () {
                      if (Platform.isAndroid) {
                        _getProduct();
                        Navigator.pop(context, PaymentType.googlePay);
                      } else if (Platform.isIOS) {
                        _getProduct();
                        Navigator.pop(context, PaymentType.applePay);
                      }
                    }
                  : null,
              child: Image(
                  image: (Theme.of(context).platform == TargetPlatform.iOS)
                      ? AssetImage("res/image/applePayLogo.png")
                      : AssetImage("res/image/googlePayLogo.png")),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Colors.black,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return IntroViewsFlutter(
      pages,
      pageButtonsColor: Colors.black45,
      skipText: Text(
        "SKIP",
        style: _fontDescriptionStyle.copyWith(
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0),
      ),
      doneText: Text(
        "DONE",
        style: _fontDescriptionStyle.copyWith(
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0),
      ),
      onTapDoneButton: () {
        _showOrderSheet(context);
      },
    );
  }
}

class _ShippingInformation extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(left: 30)),
          Text(
            "Ship to",
            style: TextStyle(fontSize: 16, color: themeColor),
          ),
          Padding(padding: EdgeInsets.only(left: 30)),
          Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Lauren Nobel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                ),
                Text(
                  "1455 Market Street\nSan Francisco, CA, 94103",
                  style: TextStyle(fontSize: 16, color: themeColor),
                ),
              ]),
        ],
      );
}

class _LineDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(left: 30, right: 30),
      child: Divider(
        height: 1,
        color: primaryColor,
      ));
}

class _PaymentTotal extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: EdgeInsets.only(left: 30)),
          Text(
            "Total",
            style: TextStyle(fontSize: 16, color: themeColor),
          ),
          Padding(padding: EdgeInsets.only(right: 47)),
          Text(
            "\$${getCookieAmount()}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class _RefundInformation extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              width: MediaQuery.of(context).size.width - 60,
              child: Text(
                "You can refund this transaction through your Square dashboard, go to squareup.com/dashboard.",
                style: TextStyle(fontSize: 12, color: primaryColor),
              ),
            ),
          ],
        ),
      );
}
