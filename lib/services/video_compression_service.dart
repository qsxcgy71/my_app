import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoCompressionService {
  // 压缩配置常量
  static const VideoQuality defaultQuality = VideoQuality.MediumQuality;
  static const VideoQuality highQuality = VideoQuality.HighestQuality;
  static const VideoQuality lowQuality = VideoQuality.LowQuality;
  
  // 压缩视频文件
  static Future<MediaInfo?> compressVideo(
    File videoFile, {
    VideoQuality quality = defaultQuality,
    bool deleteOrigin = false,
    int? frameRate,
  }) async {
    try {
      print('开始压缩视频: ${videoFile.path}');
      
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: deleteOrigin,
        frameRate: frameRate ?? 30,
      );
      
      if (info != null) {
        print('视频压缩完成:');
        print('原始大小: ${(videoFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');
        print('压缩后大小: ${(info.filesize! / 1024 / 1024).toStringAsFixed(2)} MB');
        print('压缩率: ${((1 - info.filesize! / videoFile.lengthSync()) * 100).toStringAsFixed(1)}%');
      }
      
      return info;
    } catch (e) {
      print('视频压缩失败: $e');
      return null;
    }
  }
  
  // 智能压缩 - 根据文件大小自动选择压缩质量
  static Future<MediaInfo?> smartCompressVideo(
    File videoFile, {
    int targetSizeMB = 20, // 降低目标文件大小到20MB
    bool deleteOrigin = false,
  }) async {
    try {
      final originalSizeMB = videoFile.lengthSync() / 1024 / 1024;
      print('原始视频大小: ${originalSizeMB.toStringAsFixed(2)} MB');
      
      // 对于超过10MB的视频都进行压缩优化
      if (originalSizeMB <= 10) {
        print('视频文件小于10MB，无需压缩');
        return MediaInfo(
          path: videoFile.path,
          title: videoFile.path.split('/').last,
          filesize: videoFile.lengthSync(),
        );
      }
      
      // 根据原始大小选择压缩质量 - 更积极的压缩策略
      VideoQuality quality;
      if (originalSizeMB > 100) {
        quality = VideoQuality.LowQuality; // 超过100MB用低质量
      } else if (originalSizeMB > 50) {
        quality = VideoQuality.MediumQuality; // 50-100MB用中等质量
      } else if (originalSizeMB > 25) {
        quality = VideoQuality.MediumQuality; // 25-50MB用中等质量
      } else {
        quality = VideoQuality.HighestQuality; // 10-25MB用高质量压缩
      }
      
      print('选择压缩质量: $quality');
      
      final result = await compressVideo(
        videoFile,
        quality: quality,
        deleteOrigin: deleteOrigin,
      );
      
      // 如果压缩后仍然太大，尝试更低质量
      if (result != null && result.filesize! / 1024 / 1024 > targetSizeMB) {
        if (quality != VideoQuality.LowQuality) {
          print('压缩后仍然太大，尝试更低质量压缩');
          return await compressVideo(
            File(result.path!),
            quality: VideoQuality.LowQuality,
            deleteOrigin: true, // 删除中间文件
          );
        }
      }
      
      return result;
    } catch (e) {
      print('智能视频压缩失败: $e');
      return null;
    }
  }
  
  // 生成视频缩略图
  static Future<File?> generateThumbnail(
    File videoFile, {
    int timeMs = 1000, // 截取时间点（毫秒）
    int quality = 50, // 缩略图质量 (1-100)
  }) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoFile.path,
        position: timeMs,
        quality: quality,
      );
      
      if (thumbnail != null) {
        print('视频缩略图生成成功: ${thumbnail.path}');
      }
      
      return thumbnail;
    } catch (e) {
      print('生成视频缩略图失败: $e');
      return null;
    }
  }
  
  // 获取视频信息
  static Future<MediaInfo?> getVideoInfo(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      
      if (info != null) {
        print('视频信息:');
        print('时长: ${info.duration}ms');
        print('宽度: ${info.width}');
        print('高度: ${info.height}');
        print('文件大小: ${(info.filesize! / 1024 / 1024).toStringAsFixed(2)} MB');
      }
      
      return info;
    } catch (e) {
      print('获取视频信息失败: $e');
      return null;
    }
  }
  
  // 批量压缩视频
  static Future<List<MediaInfo?>> compressMultipleVideos(
    List<File> videoFiles, {
    VideoQuality quality = defaultQuality,
    bool deleteOrigin = false,
    Function(int current, int total)? onProgress,
  }) async {
    final results = <MediaInfo?>[];
    
    for (int i = 0; i < videoFiles.length; i++) {
      onProgress?.call(i + 1, videoFiles.length);
      
      final result = await compressVideo(
        videoFiles[i],
        quality: quality,
        deleteOrigin: deleteOrigin,
      );
      
      results.add(result);
    }
    
    return results;
  }
  
  // 取消压缩
  static Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
      print('视频压缩已取消');
    } catch (e) {
      print('取消压缩失败: $e');
    }
  }
  
  // 删除缓存
  static Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
      print('视频压缩缓存已清理');
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }
  
  // 设置日志级别
  static void setLogLevel(int logLevel) {
    VideoCompress.setLogLevel(logLevel);
  }
  
  // 检查视频是否需要压缩
  static Future<bool> shouldCompress(
    File videoFile, {
    int maxSizeMB = 50,
    int maxDurationSeconds = 300, // 5分钟
  }) async {
    try {
      final info = await getVideoInfo(videoFile);
      if (info == null) return false;
      
      final sizeMB = info.filesize! / 1024 / 1024;
      final durationSeconds = info.duration! / 1000;
      
      return sizeMB > maxSizeMB || durationSeconds > maxDurationSeconds;
    } catch (e) {
      print('检查视频是否需要压缩失败: $e');
      return false;
    }
  }
  
  // 格式化文件大小
  static String formatFileSize(int bytes) {
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
  
  // 格式化视频时长
  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
} 