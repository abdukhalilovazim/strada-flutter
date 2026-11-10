import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_marketing_names/device_marketing_names.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoHelper {
  static String deviceId = '';
  static String deviceName = '';
  static String appVersion = '1.0.0';
  static String appVersionCode = '1';
  static String get appSource => Platform.isIOS ? 'app_store' : 'play_store';

  static Future<void> init() async {
    final info = DeviceInfoPlugin();

    String? marketingName;
    try {
      marketingName = await DeviceMarketingNames().getSingleName();
    } catch (_) {}

    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      deviceId = android.id;
      deviceName = (marketingName != null && marketingName.isNotEmpty)
          ? marketingName
          : '${android.manufacturer} ${android.model}';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      deviceId = ios.identifierForVendor ?? '';
      deviceName = (marketingName != null && marketingName.isNotEmpty)
          ? marketingName
          : (ios.name.isNotEmpty ? ios.name : ios.utsname.machine);
    } else {
      deviceId = 'unknown';
      deviceName = marketingName ?? 'Unknown Device';
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      appVersionCode = packageInfo.buildNumber;
    } catch (_) {
      appVersion = '1.0.0';
      appVersionCode = '1'; // Fallback
    }
  }
}
