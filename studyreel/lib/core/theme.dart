import 'package:flutter/material.dart';

const kBgColor      = Color(0xFF0F0F1A);
const kCardColor    = Color(0xFF1A1A2E);
const kPrimaryColor = Color(0xFF6C63FF);
const kTextGray     = Color(0xFFA0A0B0);
const kRedAccent    = Color(0xFFFF4444);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBgColor,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryColor,
    surface: kCardColor,
  ),
  useMaterial3: true,
);
