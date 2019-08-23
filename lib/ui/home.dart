import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/ui/collections_fb.dart';
import 'package:gallery/ui/home_content.dart';
import 'package:gallery/ui/navigation_drawer.dart';
import 'package:gallery/ui/photos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<HomeContent> _contents;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_contents == null) {
      _contents = [
        /*
        HomeContent(
          Icons.home,
          UnsplutterLocalizations.of(context).trans('home'),
          UnsplutterLocalizations.of(context).trans('app_name'),
          true,
          (() => PhotosPage()),
        ),
        */
        HomeContent(
          Icons.collections,
          UnsplutterLocalizations.of(context).trans('collections'),
          UnsplutterLocalizations.of(context).trans('collections'),
          true,
          (() => CollectionsFbPage()),
        ),
      ];
    }

    return Scaffold(
        drawer: NavigationDrawer(
          contents: _contents,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.ac_unit),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CollectionsFbPage()));
              },
            ),
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                imageCache.clear();
              },
            )
          ],
          title: Text(_contents[_currentIndex].title),
          elevation: _contents[_currentIndex].hasTab ? 0.0 : 4.0,
        ),
        body: WillPopScope(
          onWillPop: _onWillPop,
          child: _contents[_currentIndex].body(),
          //child: _contents[_currentIndex].body(),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: Icon(
            Icons.book,
          ),
          onPressed: () {},
        ));
  }

  Future<bool> _onWillPop() async {
    // Don't exit the app when pushing back other than the home page.
    if (_currentIndex == 0 || Navigator.canPop(context)) {
      // Make default behaviors when the drawer is open or on the home page.
      return true;
    } else {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
  }
}
