// lib/styles/app_text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  // 基础字体样式（根据字重定义）
  static const TextStyle bold = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const TextStyle extraLight = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 14,
    fontWeight: FontWeight.w200,
    color: Colors.grey,
  );

  static const TextStyle heavy = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.red,
  );

  static const TextStyle light = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.black87,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle regular = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  // 常用的文本样式（基于基础样式）
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: Colors.grey,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: Colors.grey,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: 'GenSenRounded',
    fontSize: 10,
    fontWeight: FontWeight.w200,
    color: Colors.grey,
  );

    // === Fredoka Styles（新增） ===
  static const TextStyle fredokaBold = TextStyle(
    fontFamily: 'Fredoka', // 使用你在 pubspec.yaml 中定义的字体 family
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const TextStyle fredokaSemiBold = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle fredokaMedium = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle fredokaRegular = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static const TextStyle fredokaTitleLarge = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle fredokaTitleMedium = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static const TextStyle fredokaBodyLarge = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle fredokaBodyMedium = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static const TextStyle fredokaButton = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // === Poppins Styles ===
  static const TextStyle poppinsBlack = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.black,
  );

  static const TextStyle poppinsExtraBold = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.black,
  );

  static const TextStyle poppinsBold = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const TextStyle poppinsSemiBold = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle poppinsMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle poppinsRegular = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static const TextStyle poppinsLight = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.black87,
  );

  static const TextStyle poppinsExtraLight = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w200,
    color: Colors.grey,
  );

  static const TextStyle poppinsThin = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );

  // Poppins Variants for Different Use Cases
  static const TextStyle poppinsTitleLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle poppinsTitleMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    letterSpacing: -0.3,
  );

  static const TextStyle poppinsTitleSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    letterSpacing: -0.2,
  );

  static const TextStyle poppinsBodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    height: 1.5,
  );

  static const TextStyle poppinsBodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    height: 1.4,
  );

  static const TextStyle poppinsBodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    height: 1.3,
  );

  static const TextStyle poppinsButton = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle poppinsCaption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
    letterSpacing: 0.2,
  );

  static const TextStyle poppinsOverline = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // === Poppins Italic Styles ===
  static const TextStyle poppinsBlackItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    color: Colors.black,
  );

  static const TextStyle poppinsExtraBoldItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: Colors.black,
  );

  static const TextStyle poppinsBoldItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: Colors.black,
  );

  static const TextStyle poppinsSemiBoldItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: Colors.black,
  );

  static const TextStyle poppinsMediumItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: Colors.black87,
  );

  static const TextStyle poppinsRegularItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: Colors.black87,
  );

  static const TextStyle poppinsLightItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    color: Colors.black87,
  );

  static const TextStyle poppinsExtraLightItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w200,
    fontStyle: FontStyle.italic,
    color: Colors.grey,
  );

  static const TextStyle poppinsThinItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w100,
    fontStyle: FontStyle.italic,
    color: Colors.grey,
  );

  // Poppins Italic Variants for Different Use Cases
  static const TextStyle poppinsTitleLargeItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: Colors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle poppinsBodyLargeItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: Colors.black87,
    height: 1.5,
  );

  static const TextStyle poppinsCaptionItalic = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: Colors.grey,
    letterSpacing: 0.2,
  );
}