import 'dart:async';

import 'package:flutter/services.dart';

typedef EaseSingeCallback = Function(String callId, EaseCallError error);

class EaseCallKit {
  static const MethodChannel _channel = const MethodChannel('ease_call_kit');
  static EaseCallKitListener? _listener;

  /// EaseCall模块初始化
  /// `config` EaseCall的配置，包括用户昵称、头像、呼叫超时时间等
  static Future<void> initWithConfig(EaseCallConfig config) async {
    _addListener();
    Map<String, dynamic> req = {};
    req['agora_app_id'] = config.agoraAppId;
    if (config.defaultHeadImageURL != null) {
      req['default_head_image_url'] = config.defaultHeadImageURL;
    }

    if (config.ringFileURL != null) {
      req['ring_file_url'] = config.ringFileURL;
    }

    if (config.callTimeOut > 0) {
      req['call_timeout'] = config.callTimeOut;
    }

    req['enable_rtc_token_validate'] = config.enableRTCTokenValidate;
    List? userList = config.userMap?.keys
        .map(
          (key) => {
            "key": key,
            "value": config.userMap?[key]!.toJson(),
          },
        )
        .toList();
    if (userList != null) {
      req['user_map'] = userList;
    }
    return await _channel.invokeMethod('initCallKit', req);
  }

  /// 邀请成员进行单人通话
  /// `emId`,  被邀请人的环信ID
  /// `callType`, 通话类型，[EaseCallType.SingeAudio]或[EaseCallType.SingeAudio]
  /// `ext`, 扩展信息
  static Future<void> startSingleCall(
    String emId, {
    EaseCallType callType = EaseCallType.SingeAudio,
    Map? ext,
  }) async {
    Map<String, dynamic> req = {};
    req['em_id'] = emId;
    req['call_type'] = callType == EaseCallType.SingeAudio ? 0 : 1;
    if (ext != null) {
      req['ext'] = ext;
    }
    return await _channel.invokeMethod('startSingleCall', req);
  }

  /// 邀请成员进行多人会议
  /// `users` 被邀请人的环信ID数组
  /// `ext`, 扩展信息
  static Future<void> startInviteUsers(
    List<String> users, {
    Map? ext,
  }) async {
    Map req = {};
    req['users'] = users;
    if (ext != null) {
      req['ext'] = ext;
    }

    return await _channel.invokeMethod('startInviteUsers', req);
  }

  /*
  // 获取EaseCallKit的配置
  static Future<EaseCallConfig> getEaseCallConfig() async {
    Map result = await _channel.invokeMethod("getEaseCallConfig");
    String agoraAppId = result["agora_app_id"];
    String defaultImage = result["default_head_image_url"];
    int callTimeOut = result["call_timeout"] as int;
    String ringFileUrl = result["ring_file_url"];
    bool enableRTCTokenValidate = result["enableRTCTokenValidate"] as bool;
    return EaseCallConfig(
      agoraAppId,
      defaultHeadImageURL: defaultImage,
      callTimeOut: callTimeOut,
      ringFileURL: ringFileUrl,
      enableRTCTokenValidate: enableRTCTokenValidate,
    );
  }
  */

  /// 设置声网频道及token
  /// `token` 声网token
  /// `aChannelName` token对应的频道名称
  /// `uid` 声网账户
  static Future<void> setRTCToken(
    String token,
    String channelName,
    int uid,
  ) async {
    Map req = {};
    req['rtc_token'] = token;
    req['channel_name'] = channelName;
    req['uid'] = uid;
    return await _channel.invokeMethod('setRTCToken', req);
  }

  /// 设置环信eid和用户头像昵称的映射，该方法会覆盖掉之前添加的映射。
  /// `userMap` 用户映射表
  static Future<void> setUserInfoMapper(
      Map<String, EaseCallUser>? userMap) async {
    Map req = {};
    List? userList = userMap?.keys
        .map(
          (key) => {
            "key": key,
            "value": userMap[key]!.toJson(),
          },
        )
        .toList();
    if (userList != null) {
      req['userInfo_list'] = userList;
    }

    return await _channel.invokeMethod("setUserInfoMapper", req);
  }

  /*
  /// 设置声网uid和环信eid的映射表
  /// `aUserMapper` 声网账户与环信id的映射表
  /// `channelName` 对应的频道名称
  static Future<void> setUsersMapper(
      Map<String, int> aUserMapper, String channelName) async {
    Map req = {};
    req["map"] = aUserMapper;
    req["channel_name"] = channelName;
    return await _channel.invokeMethod("setUsersMapper", req);
  }
  */
  static void _addListener() {
    _channel.setMethodCallHandler((MethodCall call) async {
      Map argMap = call.arguments;
      if (call.method == 'callDidEnd') {
        String channelName = argMap['channel_name'];
        int time = argMap['time'];
        EaseCallType callType =
            EaseCallHelper.callTypeFromInt(argMap['call_type']);
        EaseCallEndReason reason =
            EaseCallHelper.endReasonFromInt(argMap['reason']);

        _listener?.callDidEnd(
          channelName,
          reason,
          time,
          callType,
        );
      } else if (call.method == 'callDidReceive') {
        EaseCallType callType =
            EaseCallHelper.callTypeFromInt(argMap['call_type']);
        _listener?.callDidReceive(
          callType,
          argMap['inviter'],
          argMap['ext'],
        );
      } else if (call.method == 'callDidOccurError') {
        _listener?.callDidOccurError(
          EaseCallError.fromJson(argMap),
        );
      } else if (call.method == 'multiCallDidInviting') {
        List? excludeUsers = argMap['exclude_users'];
        List<String?> list = [];
        if (excludeUsers != null) {
          for (var item in excludeUsers) {
            if (item is String) {
              list.add(item);
            }
          }
        }
        Map? ext = argMap['ext'];
        _listener?.multiCallDidInviting(
          list,
          ext,
        );
      } else if (call.method == 'callDidRequestRTCToken') {
        String appId = argMap['app_id'];
        String channelName = argMap['channel_name'];
        String account = argMap['account'];
        _listener?.callDidRequestRTCToken(
          appId,
          channelName,
          account,
        );
      } else if (call.method == "callDidJoinChannel") {
        String channelName = argMap["channel_name"];
        int agoraUId = argMap["agora_uid"];
        _listener?.callDidJoinChannel(
          channelName,
          agoraUId,
        );
      } else if (call.method == "remoteUserDidJoinChannel") {
        String channelName = argMap["channel_name"];
        String account = argMap['account'];
        int agoraUId = argMap["agora_uid"];
        _listener?.remoteUserDidJoinChannel(
          channelName,
          agoraUId,
          account,
        );
      }
      return null;
    });
  }

  /// 仅供demo使用
  static Future<String?> getTestUserToken() async {
    return _channel.invokeMethod("getTestUserToken");
  }

  static set listener(EaseCallKitListener listener) {
    _listener = listener;
  }

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
  void callDidReceive(
    EaseCallType callType,
    String inviter,
    Map? ext,
  );

  /// 通话过程发生异常时，触发该回调
  /// `error` 错误信息
  void callDidOccurError(
    EaseCallError error,
  );

  /// 加入音视频通话频道前触发该回调，用户需要在触发该回调后，
  /// 主动从AppServer获取声网token，然后调用EaseCallKit#setRTCToken方法将token设置进来
  /// `appId` 声网通话使用的appId
  /// `channelName` 呼叫使用的频道名称
  /// `eid` 当前登录的环信id
  void callDidRequestRTCToken(
    String appId,
    String channelName,
    String eid,
  );

  /// 多人通话中，点击邀请按钮触发该回调
  /// `excludeUsers` 当前会议中已存在的成员及已邀请的成员
  /// `ext` 邀请中的扩展信息
  void multiCallDidInviting(
    List<String?> excludeUsers,
    Map? ext,
  );

  /// 通话中对方加入会议时触发该回调
  /// `channelName` 呼叫使用的频道名称
  /// `uid` 声网账户
  /// `eid` 当前登录的环信id
  void remoteUserDidJoinChannel(
    String channelName,
    int uid,
    String eid,
  );

  /// 通话中自己加入会议成功时触发该回调
  /// `channelName` 呼叫使用的频道名称
  /// `uid` 声网账户
  void callDidJoinChannel(
    String channelName,
    int uid,
  );
}

/// 用户信息
class EaseCallUser {
  EaseCallUser([
    this.nickname,
    this.headImageURL,
  ]);

  /// 用户名称
  String? nickname;

  /// 用户头像URL
  String? headImageURL;

  Map<String, String> toJson() {
    Map<String, String> map = {};
    if (nickname != null) {
      map["nickname"] = nickname!;
    }

    if (headImageURL != null) {
      map["avatar_url"] = headImageURL!;
    }
    return map;
  }
}

class EaseCallConfig {
  /// 声网AppId
  final String agoraAppId;

  /// 是否开启声网token验证，默认不开启，开启后必须实现callDidRequestRTCToken回调，并在收到回调后调用setRTCToken才能进行通话
  final bool enableRTCTokenValidate;

  /// 默认头像本地路径, 当收到未设置头像用户的呼叫时将展示默认头像。
  final String? defaultHeadImageURL;

  /// 铃声本地路径
  final String? ringFileURL;

  /// 超时时间
  late int callTimeOut = 30;

  /// 用户信息字典,key为环信ID，value为EaseCallUser
  Map<String, EaseCallUser>? userMap;

  /// 初始化Config,
  /// `agoraAppId` 声网AppId，必填，需要从声网申请。
  /// `enableRTCTokenValidate` 是否开启声网Token验证, 默认为false，开启后，
  /// 需要实现`EaseCallKitListener#callDidRequestRTCToken`回调，在收到回调时根据需要取声网请求token，之后调用
  /// `EaseCallKit#setRTCToken` 方法将RTCToken提供给callkit，之后才能进行通话。
  /// `callTimeOut` 呼叫超时时间。
  /// `defaultHeadImageURL` 默认头像本地路径, 当收到未设置头像用户的呼叫时将展示默认头像。
  /// `ringFileURL` 铃声文件路径。
  EaseCallConfig(
    this.agoraAppId, {
    this.enableRTCTokenValidate = false,
    this.callTimeOut = 30,
    this.defaultHeadImageURL,
    this.ringFileURL,
  });
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

/// EaseCallError
class EaseCallError {
  EaseCallError._private();

  /// 错误种类
  late EaseCallErrorType errType;

  /// 错误码
  late int errCode;

  /// 错误描述
  late String errDescription;

  factory EaseCallError.fromJson(Map map) {
    EaseCallErrorType callType =
        EaseCallHelper.errorTypeFromInt(map['err_type']);
    return EaseCallError._private()
      ..errCode = map['err_code'] as int
      ..errDescription = map['err_desc'] as String
      ..errType = callType;
  }

  @override
  String toString() {
    return '{err_type: $errType, err_code: $errCode, err_desc: $errDescription}';
  }
}

/// 结束原因
enum EaseCallEndReason {
  None,

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

enum EaseCallErrorType {
  /// none
  None,

  /// 呼叫过程中错误
  Process,

  /// RTC错误
  RTC,

  /// im错误
  IM,
}

class EaseCallHelper {
  static EaseCallErrorType errorTypeFromInt(int intType) {
    EaseCallErrorType callType = EaseCallErrorType.None;
    switch (intType) {
      case 1:
        callType = EaseCallErrorType.Process;
        break;
      case 2:
        callType = EaseCallErrorType.RTC;
        break;
      case 3:
        callType = EaseCallErrorType.IM;
    }
    return callType;
  }

  static EaseCallEndReason endReasonFromInt(int intReason) {
    EaseCallEndReason reason = EaseCallEndReason.None;
    switch (intReason) {
      case 1:
        reason = EaseCallEndReason.Hangup;
        break;
      case 2:
        reason = EaseCallEndReason.Cancel;
        break;
      case 3:
        reason = EaseCallEndReason.RemoteCancel;
        break;
      case 4:
        reason = EaseCallEndReason.Refuse;
        break;
      case 5:
        reason = EaseCallEndReason.Busy;
        break;
      case 6:
        reason = EaseCallEndReason.NoResponse;
        break;
      case 7:
        reason = EaseCallEndReason.RemoteNoResponse;
        break;
      case 8:
        reason = EaseCallEndReason.HandleOtherDevice;
        break;
    }
    return reason;
  }

  static EaseCallType callTypeFromInt(int intCallType) {
    EaseCallType callType = EaseCallType.SingeAudio;
    switch (intCallType) {
      case 1:
        callType = EaseCallType.SingeAudio;
        break;
      case 2:
        callType = EaseCallType.SingeVideo;
        break;
      case 3:
        callType = EaseCallType.Multi;
        break;
    }
    return callType;
  }
}
