import 'package:flutter/material.dart';

extension ContextUtils on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  TextStyle get headline1 => textTheme.displayLarge!;
  TextStyle get headline2 => textTheme.displayMedium!;
  TextStyle get headline3 => textTheme.displaySmall!;
  TextStyle get headline4 => textTheme.headlineMedium!;
  TextStyle get headline5 => textTheme.headlineSmall!;
  TextStyle get headline6 => textTheme.titleLarge!;
  TextStyle get bodyText1 => textTheme.bodyLarge!;
  TextStyle get bodyText2 => textTheme.bodyMedium!;
}
