import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors (Galio Green Theme)
  static const primaryGreen = Color(0xFF28A745);
  static const secondaryGreen = Color(0xFF23963D);
  static const darkPrimaryGreen = Color(0xFF4CBB6A);

  // App Bar / Surface Dark (Galio Dark Gray)
  static const darkBackground = Color(0xFF343A40);

  // Surface Colors
  static const white = Color(0xFFFFFFFF);
  static const scaffoldBackground = Color(0xFFFAFAFA);
  static const surfaceLight = Color(0xFFF4F6F8);
  static const black = Color(0xFF000000);

  // Text Colors
  static const textPrimary = Color(0xDE000000);
  static const textSecondary = Color(0xC2000000);
  static const textTertiary = Color(0x8A000000);
  static const textDisabled = Color(0x61000000);
  static const textWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF343A40);

  // Icon Colors
  static const iconSecondary = Color(0xC2000000);
  static const iconTertiary = Color(0x8a000000);
  static const iconDisabled = Color(0x61000000);

  // Border Colors
  static const bordersLight = Color(0x1F000000);
  static const borderError = Color(0xFFD12730);

  // State Colors
  static const textError = Color(0xFFD12730);
  static const notificationInfo = Color(0xFF323232);
  static const notificationWarning = Color(0xFFdc6d1b);
  static const notificationSuccess = Color(0xFF28A745);
  static const notificationError = Color(0xFFD12730);

  // Overlay Colors
  static const bgOverlay = Color(0x61000000);
  static const cameraBackground = Color(0xFF828282);

  // Selection and Focus Colors
  static const selectionColor = Color(0x3328A745); // primaryGreen with 20% opacity
  static const focusColor = primaryGreen;

  // Material Color Swatch for Primary Green
  static const MaterialColor primarySwatch = MaterialColor(0xFF28A745, <int, Color>{
    50: Color(0xFFE9F7EC),
    100: Color(0xFFC8ECD0),
    200: Color(0xFFA3DFB3),
    300: Color(0xFF7DD397),
    400: Color(0xFF58C97D),
    500: primaryGreen,
    600: secondaryGreen,
    700: Color(0xFF1C8233),
    800: Color(0xFF166E28),
    900: Color(0xFF0D501C),
  });

  // Dark Theme Material Color Swatch
  static const MaterialColor darkPrimarySwatch = MaterialColor(0xFF28A745, <int, Color>{
    50: Color(0xFFE9F7EC),
    100: Color(0xFFC8ECD0),
    200: Color(0xFFA3DFB3),
    300: Color(0xFF7DD397),
    400: Color(0xFF58C97D),
    500: darkPrimaryGreen,
    600: primaryGreen,
    700: Color(0xFF23963D),
    800: Color(0xFF1C8233),
    900: Color(0xFF0D501C),
  });

  // Getters for dynamic color access
  static Color get appPrimaryColor => primaryGreen;
}
