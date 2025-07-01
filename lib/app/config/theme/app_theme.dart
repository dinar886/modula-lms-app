// lib/app/config/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs principales de votre marque.
  // Utilisez un site comme coolors.co pour générer une belle palette.
  static const Color _primaryColor = Color(
    0xFF005A9C,
  ); // Un bleu institutionnel
  static const Color _secondaryColor = Color(
    0xFFF5A623,
  ); // Un orange pour les accents
  static const Color _backgroundColor = Color(0xFFF4F6F8); // Un fond gris clair
  static const Color _textColor = Color(0xFF212121); // Texte principal

  // Le thème clair
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Définition des couleurs
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: Colors.white,
      onSurface: _textColor,
      error: Colors.redAccent,
    ),

    // Définition des polices de caractères
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: _textColor),
        bodyMedium: TextStyle(color: _textColor),
      ),
    ),

    // Style global pour les boutons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),

    // Style global pour les AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: _textColor),
      titleTextStyle: TextStyle(
        color: _textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Vous pouvez ajouter un thème sombre (darkTheme) ici sur le même modèle.
}
