import 'dart:async';

import 'package:flutter/services.dart';

typedef EaseSingeCallback = Function(String callId, EaseCallError error);

class EaseCallKit {
  static const MethodChannel _channel = const MethodChannel('ease_call_kit');
  static EaseCallKitListener _listener;
  static EaseCallConfig _config;

  /// 初始化EaseCallKit,
  /// 必须确保登录成功后再调用。
  static Future<void> initWithConfig(EaseCallConfig config) async {
    Map req = {};
    req['agora_app_id'] = config.agoraAppId;
    req['default_head_image_url'] = config.defaultHeadImageURL;
    req['call_timeout'] = config.callTimeOut;
    req['ring_file_url'] = config.ringFileURL;
    req['enable_rtc_token_validate'] = config.enableRTCTokenValidate;
    req['user_map'] = config.userMap?.keys
        ?.map((e) => {e: config.userMap[e].toJson()})
        ?.toList();
    _config = config;
    await _channel.invokeMethod('initCallKit', req);
  }

  /// 发起1v1通话，
  /// `emId`, 环信id
  /// `callType`, 只能是 [EaseCallType.SingeAudio]或[EaseCallType.SingeAudio]
  /// `ext`, 扩展信息
  static Future<String> startSingleCall(
    String emId, {
    EaseCallType callType = EaseCallType.SingeAudio,
    Map ext,
  }) async {
    Map req = {};
    req['em_id'] = emId;
    req['call_type'] = callType == EaseCallType.SingeAudio ? 0 : 1;
    req['ext'] = ext ?? {};
    Map result = await _channel.invokeMethod('startSingleCall', req);
    String callId;
    if (result['error'] != null) {
      throw (EaseCallError.fromJson(result['error']));
    } else {
      callId = result['call_id'];
    }
    return callId;
  }

  /// 邀请用户发起群聊，
  /// `users` 需要邀请的环信ids
  /// `ext`, 扩展信息
  static Future<String> startInviteUsers(
    List<String> users, {
    Map ext,
  }) async {
    Map req = {};
    req['users'] = users;
    req['ext'] = ext ?? {};
    Map result = await _channel.invokeMethod('startInviteUsers', req);
    String callId;
    if (result['error'] != null) {
      throw (EaseCallError.fromJson(result['error']));
    } else {
      callId = result['call_id'];
    }
    return callId;
  }

  // /// 获取当前配置
  static EaseCallConfig get getEaseCallConfig => _config;

  // static Future<EaseCallConfig> getEaseCallConfig() async {
  //   return null;
  // }

  static Future<void> setRTCToken(String token, String channelName) async {
    Map req = {};
    req['rtc_token'] = token;
    req['channel_name'] = channelName;
    await _channel.invokeMethod('startInviteUsers', req);
  }

  set listener(listener) => _listener;

  static dispose() {
    _listener = null;
  }
}

abstract class EaseCallKitListener {
  /// 通话结束时触发该回调
  /// `channelName`  通话的通道名称，用于在声网水晶球查询通话质量
  /// `reason` 通话结束原因
  /// `time` 通话时长
  /// `callType` 通话类型，EaseCallTypeAudio为语音通话，EaseCallTypeVideo为视频通话，EaseCallTypeMulti为多人通话
  void callDidEnd(
    String channelName,
    EaseCallEndReason reason,
    int time,
    EaseCallType callType,
  );

  /// 被叫开始振铃时，触发该回调
  /// `callType` 通话类型
  /// `inviter` 主叫的环信id
  /// `ext` 邀请中的扩展信息
  void callDidReceive(EaseCallType callType, String inviter, Map ext);

  /// 通话过程发生异常时，触发该回调
  /// `error` 错误信息
  void callDidOccurError(EaseCallError error);

  /// 加入音视频通话频道前触发该回调，用户需要在触发该回调后，主动从AppServer获取声网token，然后调用setRTCToken:channelName:方法将token设置进来
  /// `appId` 声网通话使用的appId
  /// `channelName` 呼叫使用的频道名称
  /// `account` 账户
  void callDidRequestRTCToken(String appId, String channelName, String account);
}

/// 用户信息
class EaseCallUser {
  EaseCallUser([
    this.nickname,
    this.headImageURL,
  ]);

  /// 用户名称
  String nickname;

  /// 用户头像URL
  String headImageURL;

  Map<String, String> toJson() {
    return {
      'nickname': nickname ?? '',
      'avatar_url': headImageURL ?? '',
    };
  }
}

class EaseCallConfig {
  EaseCallConfig(
    this.agoraAppId, {
    this.enableRTCTokenValidate = false,
  });

  /// 默认头像本地路径
  String defaultHeadImageURL = '';

  /// 铃声本地路径
  String ringFileURL = '';

  /// 超时时间
  int callTimeOut = 30;

  Map<String, EaseCallUser> userMap;

  /// 声网AppId
  final String agoraAppId;

  /// 是否需要RTC验证，需要去声网后台控制，默认关闭
  final bool enableRTCTokenValidate;
}

/// 呼叫类型
enum EaseCallType {
  /// 1v1 音频
  SingeAudio,

  /// 1v1 视频
  SingeVideo,

  /// 多人
  Multi,
}

class EaseCallError {
  EaseCallError._private();

  /// 错误种类
  EaseCallErrorType errType;

  /// 错误码
  int errCode;

  /// 错误描述
  String errDescription;

  factory EaseCallError.fromJson(Map map) {
    EaseCallErrorType callType;
    switch (map['err_type']) {
      case 0:
        callType = EaseCallErrorType.None;
        break;
      case 1:
        callType = EaseCallErrorType.Process;
        break;
      case 2:
        callType = EaseCallErrorType.RTC;
        break;
      case 3:
        callType = EaseCallErrorType.IM;
    }
    return EaseCallError._private()
      ..errCode = map['err_code']
      ..errDescription = map['err_desc']
      ..errType = callType;
  }
}

/// 结束原因
enum EaseCallEndReason {
  /// 挂断
  Hangup,

  /// 呼叫取消
  Cancel,

  /// 对方取消
  RemoteCancel,

  /// 对方拒接
  Refuse,

  /// 对方忙
  Busy,

  /// 无响应
  NoResponse,

  /// 对方无响应
  RemoteNoResponse,

  /// 已在其他设备处理
  HandleOtherDevice,
}

enum EaseCallErrorType { None, Process, RTC, IM }