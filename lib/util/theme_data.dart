import 'package:flutter/material.dart';

const defaultAccentColor = Color(0xff1ed660);

ThemeData buildThemeData(bool isDark) {
  var _accentColor =
      /* = RainbowColorTween([
      Colors.orange,
      Colors.red,
      Colors.blue,
    ]).transform(_controller.value);
 */

      //    Colors.lime;
      //Color(0xffEC1873);
      //Colors.cyan;
      defaultAccentColor;
  //Color(0xff1ed660);

  var brightness = isDark ? Brightness.dark : Brightness.light;

  var themeData = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _accentColor,
    ),
    brightness: brightness,
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.dark
          ? Colors.black /*  Colors.grey[850]  */ : Colors.white,
      /*   brightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark, */
    ),
    hintColor:
        brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[500],

    primaryColor: _accentColor,
    accentColor: _accentColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    toggleableActiveColor: _accentColor,
    highlightColor: _accentColor,
    buttonColor: _accentColor,
    // hintColor: _accentColor,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _accentColor,
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.primary,
      buttonColor: _accentColor,
    ),
    textTheme: TextTheme(
      button: TextStyle(color: _accentColor),
      subtitle1: TextStyle(
        // fontSize: 100,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      focusColor: _accentColor,
      fillColor: _accentColor,
    ),
  );

  if (isDark) {
    final backgroundColor = Color(0xff202323);
    themeData = themeData.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xff404647),
      ),
      primaryColor: backgroundColor,
      backgroundColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      dialogBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
    );
  }
  /* else if (theme == 'sepia') {
    Color backgroundColor = Color(0xffF7ECD5);
    themeData = themeData.copyWith(
      primaryColor: backgroundColor,
      backgroundColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      dialogBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
    );
  } else if (theme == 'black') {
    Color backgroundColor = Colors.black;
    themeData = themeData.copyWith(
      primaryColor: backgroundColor,
      backgroundColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      dialogBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
    );
  } */

  return themeData;
}
