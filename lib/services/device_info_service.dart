import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return _getIOSDeviceInfo();
      } else {
        return {'error': 'Unsupported platform'};
      }
    } catch (e) {
      print('Error getting device info: $e');
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _getAndroidDeviceInfo() async {
    final AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
    return {
      'platform': 'Android',
      'device': androidInfo.device,
      'model': androidInfo.model,
      'manufacturer': androidInfo.manufacturer,
      'brand': androidInfo.brand,
      'androidVersion': androidInfo.version.release,
      'sdkInt': androidInfo.version.sdkInt,
      'id': androidInfo.id,
      'isPhysicalDevice': androidInfo.isPhysicalDevice,
    };
  }

  static Future<Map<String, dynamic>> _getIOSDeviceInfo() async {
    final IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
    return {
      'platform': 'iOS',
      'name': iosInfo.name,
      'systemName': iosInfo.systemName,
      'systemVersion': iosInfo.systemVersion,
      'model': iosInfo.model,
      'localizedModel': iosInfo.localizedModel,
      'identifierForVendor': iosInfo.identifierForVendor,
      'isPhysicalDevice': iosInfo.isPhysicalDevice,
      'utsname': {
        'sysname': iosInfo.utsname.sysname,
        'nodename': iosInfo.utsname.nodename,
        'release': iosInfo.utsname.release,
        'version': iosInfo.utsname.version,
        'machine': iosInfo.utsname.machine,
      },
    };
  }
} 