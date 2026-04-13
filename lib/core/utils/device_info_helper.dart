import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoHelper {
  static String deviceId   = '';
  static String deviceName = '';

  static Future<void> init() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      deviceId   = android.id;
      deviceName = '${android.manufacturer} ${android.model}';
    } else {
      final ios = await info.iosInfo;
      deviceId   = ios.identifierForVendor ?? '';
      deviceName = ios.utsname.machine;
    }
  }
}
