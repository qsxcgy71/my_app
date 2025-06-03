import 'dart:io';
import 'dart:typed_data';
import 'package:video_compress/video_compress.dart';
import 'image_compression_service.dart';
import 'video_compression_service.dart';

enum MediaType { image, video, unknown }

class MediaCompressionService {
  // 检测媒体类型
  static MediaType getMediaType(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm', 'flv'];
    
    if (imageExtensions.contains(extension)) {
      return MediaType.image;
    } else if (videoExtensions.contains(extension)) {
      return MediaType.video;
    } else {
      return MediaType.unknown;
    }
  }
  
  // 智能压缩媒体文件（自动识别类型）
  static Future<dynamic> smartCompressMedia(
    File file, {
    int targetSizeKB = 500, // 图片目标大小（KB）
    int targetSizeMB = 20,  // 视频目标大小（MB）- 降低到20MB
    Function(String message)? onProgress,
  }) async {
    final mediaType = getMediaType(file);
    
    switch (mediaType) {
      case MediaType.image:
        onProgress?.call('正在压缩图片...');
        return await ImageCompressionService.smartCompress(
          file,
          targetSizeKB: targetSizeKB,
        );
        
      case MediaType.video:
        onProgress?.call('正在压缩视频...');
        return await VideoCompressionService.smartCompressVideo(
          file,
          targetSizeMB: targetSizeMB,
        );
        
      case MediaType.unknown:
        throw Exception('不支持的媒体文件类型');
    }
  }
  
  // 生成媒体缩略图
  static Future<File?> generateMediaThumbnail(
    File file, {
    int imageMaxWidth = 512,
    int imageMaxHeight = 512,
    int videoTimeMs = 1000,
    int quality = 80,
  }) async {
    final mediaType = getMediaType(file);
    
    switch (mediaType) {
      case MediaType.image:
        // 对于图片，生成压缩版本作为缩略图
        final compressed = await ImageCompressionService.generateThumbnail(
          file,
          maxWidth: imageMaxWidth,
          maxHeight: imageMaxHeight,
          quality: quality,
        );
        
        if (compressed != null) {
          // 将压缩后的字节数据保存为临时文件
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(compressed);
          return tempFile;
        }
        return null;
        
      case MediaType.video:
        return await VideoCompressionService.generateThumbnail(
          file,
          timeMs: videoTimeMs,
          quality: quality,
        );
        
      case MediaType.unknown:
        return null;
    }
  }
  
  // 获取媒体信息
  static Future<Map<String, dynamic>?> getMediaInfo(File file) async {
    final mediaType = getMediaType(file);
    
    switch (mediaType) {
      case MediaType.image:
        final fileSize = await file.length();
        return {
          'type': 'image',
          'path': file.path,
          'size': fileSize,
          'sizeFormatted': _formatFileSize(fileSize),
        };
        
      case MediaType.video:
        final videoInfo = await VideoCompressionService.getVideoInfo(file);
        if (videoInfo != null) {
          return {
            'type': 'video',
            'path': videoInfo.path,
            'size': videoInfo.filesize,
            'sizeFormatted': _formatFileSize(videoInfo.filesize!),
            'duration': videoInfo.duration,
            'durationFormatted': VideoCompressionService.formatDuration(videoInfo.duration!.toInt()),
            'width': videoInfo.width,
            'height': videoInfo.height,
          };
        }
        return null;
        
      case MediaType.unknown:
        return null;
    }
  }
  
  // 批量压缩媒体文件
  static Future<List<dynamic>> compressMultipleMedia(
    List<File> files, {
    int imageTargetSizeKB = 500,
    int videoTargetSizeMB = 50,
    Function(int current, int total, String fileName)? onProgress,
  }) async {
    final results = <dynamic>[];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;
      
      onProgress?.call(i + 1, files.length, fileName);
      
      try {
        final result = await smartCompressMedia(
          file,
          targetSizeKB: imageTargetSizeKB,
          targetSizeMB: videoTargetSizeMB,
        );
        results.add(result);
      } catch (e) {
        print('压缩文件失败 $fileName: $e');
        results.add(null);
      }
    }
    
    return results;
  }
  
  // 检查文件是否需要压缩
  static Future<bool> shouldCompress(
    File file, {
    int imageMaxSizeKB = 500,
    int videoMaxSizeMB = 50,
  }) async {
    final mediaType = getMediaType(file);
    
    switch (mediaType) {
      case MediaType.image:
        final fileSize = await file.length();
        return fileSize > imageMaxSizeKB * 1024;
        
      case MediaType.video:
        return await VideoCompressionService.shouldCompress(
          file,
          maxSizeMB: videoMaxSizeMB,
        );
        
      case MediaType.unknown:
        return false;
    }
  }
  
  // 获取压缩预估信息
  static Future<Map<String, dynamic>?> getCompressionEstimate(
    File file, {
    int imageTargetSizeKB = 500,
    int videoTargetSizeMB = 50,
  }) async {
    final mediaType = getMediaType(file);
    final originalSize = await file.length();
    
    switch (mediaType) {
      case MediaType.image:
        final estimatedSize = await ImageCompressionService.getEstimatedCompressedSize(file);
        if (estimatedSize != null) {
          final compressionRatio = (1 - estimatedSize / originalSize) * 100;
          return {
            'type': 'image',
            'originalSize': originalSize,
            'estimatedSize': estimatedSize,
            'compressionRatio': compressionRatio,
            'originalSizeFormatted': _formatFileSize(originalSize),
            'estimatedSizeFormatted': _formatFileSize(estimatedSize),
          };
        }
        return null;
        
      case MediaType.video:
        // 视频压缩比例通常在30-70%之间，根据质量设置估算
        final estimatedSize = (originalSize * 0.4).round(); // 估算压缩到40%
        final compressionRatio = 60.0; // 估算60%压缩率
        
        return {
          'type': 'video',
          'originalSize': originalSize,
          'estimatedSize': estimatedSize,
          'compressionRatio': compressionRatio,
          'originalSizeFormatted': _formatFileSize(originalSize),
          'estimatedSizeFormatted': _formatFileSize(estimatedSize),
        };
        
      case MediaType.unknown:
        return null;
    }
  }
  
  // 清理压缩缓存
  static Future<void> clearCompressionCache() async {
    try {
      await VideoCompressionService.deleteAllCache();
      print('媒体压缩缓存已清理');
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }
  
  // 取消所有压缩任务
  static Future<void> cancelAllCompressions() async {
    try {
      await VideoCompressionService.cancelCompression();
      print('所有压缩任务已取消');
    } catch (e) {
      print('取消压缩任务失败: $e');
    }
  }
  
  // 私有方法：格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
    }
  }
  
  // 获取支持的媒体格式
  static Map<String, List<String>> getSupportedFormats() {
    return {
      'images': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
      'videos': ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm', 'flv'],
    };
  }
  
  // 验证文件是否为支持的媒体格式
  static bool isValidMediaFile(File file) {
    return getMediaType(file) != MediaType.unknown;
  }
} 