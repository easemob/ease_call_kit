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
  EaseCallConfig(this.agoraAppId);
  String defaultHeadImageURL;
  String ringFileURL;
  final String agoraAppId;
  int callTimeOut;
}
