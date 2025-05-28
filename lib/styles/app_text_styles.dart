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
}