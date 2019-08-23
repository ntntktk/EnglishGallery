import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gallery/colors.dart';
import 'package:gallery/localizations.dart';
import 'package:gallery/login.dart';

class GalleryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        supportedLocales: [
          const Locale('en', 'US'),
          const Locale('ja', 'JP'),
        ],
        localizationsDelegates: [
          const UnsplutterLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales) {
          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode ||
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
        },
        theme: ThemeData(
          primaryColor: Colors.grey.shade100,
          accentColor: UnsplutterColors.unsplutterAccent,
          scaffoldBackgroundColor: Colors.grey.shade50,
        ),
        home: LoginScreen(),
      );
}
