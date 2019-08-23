import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const supportedLocales = const ['en', 'ja'];

class UnsplutterLocalizations {
  UnsplutterLocalizations(this.locale);

  final Locale locale;

  static UnsplutterLocalizations of(BuildContext context) {
    return Localizations.of<UnsplutterLocalizations>(context, UnsplutterLocalizations);
  }

  Map<String, Object> sentences;

  Future<bool> load() async {
    String data = await rootBundle.loadString('res/localization/${this.locale.languageCode}.json');
    sentences = json.decode(data);
    return true;
  }

  String trans(String key) {
    return sentences[key];
  }
}

class UnsplutterLocalizationsDelegate extends LocalizationsDelegate<UnsplutterLocalizations> {
  const UnsplutterLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => supportedLocales.contains(locale.languageCode);

  @override
  Future<UnsplutterLocalizations> load(Locale locale) async {
    UnsplutterLocalizations localizations = new UnsplutterLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(UnsplutterLocalizationsDelegate old) => false;
}
