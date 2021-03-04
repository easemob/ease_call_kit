import 'dart:async';

import 'package:flutter/services.dart';

class EaseCallKit {
  static const MethodChannel _channel = const MethodChannel('ease_call_kit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> initWithConfig() async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

class EaseCallUser {
  String nickname;
  String headImageURL;
}

class EaseCallConfig {
  String defaultHeadImageURL;
  String ringFileURL;
  int callTimeOut;
  final String agoraAppId;
  final bool enableRTCTokenValidate;
  EaseCallConfig(
    this.agoraAppId, {
    this.enableRTCTokenValidate = false,
  });
}
