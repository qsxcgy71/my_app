import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  // 压缩配置常量
  static const int defaultMaxWidth = 1920;
  static const int defaultMaxHeight = 1080;
  static const int defaultQuality = 85;
  static const int thumbnailMaxWidth = 512;
  static const int thumbnailMaxHeight = 512;
  static const int thumbnailQuality = 80;
  
  // 压缩图片文件
  static Future<Uint8List?> compressImageFile(
    File file, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: format,
      );
      return result;
    } catch (e) {
      print('图片压缩失败: $e');
      return null;
    }
  }
  
  // 压缩图片并保存到新文件
  static Future<File?> compressAndSaveImage(
    File sourceFile,
    String targetPath, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: format,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('图片压缩保存失败: $e');
      return null;
    }
  }
  
  // 生成缩略图
  static Future<Uint8List?> generateThumbnail(
    File file, {
    int maxWidth = thumbnailMaxWidth,
    int maxHeight = thumbnailMaxHeight,
    int quality = thumbnailQuality,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      print('缩略图生成失败: $e');
      return null;
    }
  }
  
  // 智能压缩 - 根据文件大小自动调整压缩参数
  static Future<Uint8List?> smartCompress(
    File file, {
    int targetSizeKB = 500, // 目标文件大小（KB）
    int maxAttempts = 3,
  }) async {
    try {
      // 获取原始文件大小
      final originalSize = await file.length();
      print('原始文件大小: ${(originalSize / 1024).toStringAsFixed(1)} KB');
      
      // 如果文件已经很小，直接返回
      if (originalSize <= targetSizeKB * 1024) {
        return await file.readAsBytes();
      }
      
      // 计算初始压缩参数
      int quality = 85;
      int maxWidth = defaultMaxWidth;
      int maxHeight = defaultMaxHeight;
      
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final compressed = await compressImageFile(
          file,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        
        if (compressed == null) return null;
        
        final compressedSize = compressed.length;
        print('压缩后大小 (尝试 ${attempt + 1}): ${(compressedSize / 1024).toStringAsFixed(1)} KB');
        
        // 如果达到目标大小，返回结果
        if (compressedSize <= targetSizeKB * 1024) {
          return compressed;
        }
        
        // 调整压缩参数
        if (attempt < maxAttempts - 1) {
          quality = (quality * 0.8).round();
          maxWidth = (maxWidth * 0.9).round();
          maxHeight = (maxHeight * 0.9).round();
          
          // 设置最小值
          quality = quality.clamp(30, 100);
          maxWidth = maxWidth.clamp(480, defaultMaxWidth);
          maxHeight = maxHeight.clamp(320, defaultMaxHeight);
        }
      }
      
      // 如果所有尝试都失败，返回最后一次压缩结果
      return await compressImageFile(file, quality: 30, maxWidth: 480, maxHeight: 320);
    } catch (e) {
      print('智能压缩失败: $e');
      return null;
    }
  }
  
  // 批量压缩
  static Future<List<Uint8List?>> compressMultipleImages(
    List<File> files, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
  }) async {
    final results = <Uint8List?>[];
    
    for (final file in files) {
      final compressed = await compressImageFile(
        file,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      results.add(compressed);
    }
    
    return results;
  }
  
  // 获取压缩后的预估文件大小（不实际压缩）
  static Future<int?> getEstimatedCompressedSize(
    File file, {
    int quality = defaultQuality,
  }) async {
    try {
      // 使用低质量快速压缩来估算
      final sample = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 100,
        minHeight: 100,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (sample == null) return null;
      
      // 根据采样结果估算实际压缩后大小
      final originalSize = await file.length();
      final sampleRatio = sample.length / (100 * 100 * 3); // 估算每像素字节数
      
      // 这是一个粗略估算，实际结果可能有差异
      return (defaultMaxWidth * defaultMaxHeight * sampleRatio).round();
    } catch (e) {
      print('估算压缩大小失败: $e');
      return null;
    }
  }
} 