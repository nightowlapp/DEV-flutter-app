import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceContext {
  final String platform; // 'ios' | 'android' //TODO Have enums.
  final String locale;   // e.g. 'en_US'
  final String version;  // app version

  DeviceContext({required this.platform, required this.locale, required this.version});

  static Future<DeviceContext> build() async {
    final info = await PackageInfo.fromPlatform();
    return DeviceContext(
      platform: Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),  //TODO Have enums. and platformclass.
      locale: WidgetsBinding.instance.platformDispatcher.locale.toString(),
      version: info.version,
    );
  }
}