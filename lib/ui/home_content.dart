import 'package:flutter/material.dart';

class HomeContent {
  final IconData icon;
  final String drawerLabel;
  final String title;
  final bool hasTab;
  final ValueGetter<Widget> body;

  const HomeContent(this.icon, this.drawerLabel, this.title, this.hasTab, this.body);
}
