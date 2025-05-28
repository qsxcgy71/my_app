// lib/styles/app_text_styles.dart

import 'package:flutter/material.dart';

class AppTextStyles {
  // 基础字体样式（根据字重定义）
  static const TextStyle bold = TextStyle(
    fontFamily: 'GenSenRounded2TC-B',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle extraLight = TextStyle(
    fontFamily: 'GenSenRounded2TC-EL',
    fontSize: 14,
    fontWeight: FontWeight.w100,
    color: Colors.grey,
  );

  static const TextStyle heavy = TextStyle(
    fontFamily: 'GenSenRounded2TC-H',
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: Colors.red,
  );

  static const TextStyle light = TextStyle(
    fontFamily: 'GenSenRounded2TC-L',
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.black87,
  );

  static const TextStyle medium = TextStyle(
    fontFamily: 'GenSenRounded2TC-M',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle regular = TextStyle(
    fontFamily: 'GenSenRounded2TC-R',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  // 常用的文本样式（基于基础样式）
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'GenSenRounded2TC-B', // 使用 Bold 字体
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'GenSenRounded2TC-M', // 使用 Medium 字体
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'GenSenRounded2TC-R', // 使用 Regular 字体
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'GenSenRounded2TC-M', // 使用 Medium 字体
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'GenSenRounded2TC-R', // 使用 Regular 字体
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'GenSenRounded2TC-L', // 使用 Light 字体
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'GenSenRounded2TC-B', // 使用 Bold 字体
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'GenSenRounded2TC-L', // 使用 Light 字体
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: 'GenSenRounded2TC-EL', // 使用 Extra Light 字体
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );
}