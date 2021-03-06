import 'dart:collection';

import 'package:ease_call_kit/ease_call_kit.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with EaseCallKitListener {
  @override
  void initState() {
    super.initState();
    // var config = EaseCallConfig('15cb0d28b87b425ea613fc46f7c9f974');
    String agoraUserId = "15cb0d28b87b425ea613fc46f7c9f974";
    EaseCallConfig config =
        EaseCallConfig(agoraUserId, enableRTCTokenValidate: true);
    EaseCallUser aUser = EaseCallUser("liu001昵称");
    Map<String, EaseCallUser> userMap = HashMap();
    userMap[agoraUserId] = aUser;
    config.userMap = userMap;
    config.callTimeOut = 30 * 30 * 1000;

    EaseCallKit.initWithConfig(config);
    EaseCallKit.listener = this;

    print('initState agoraUserId:$agoraUserId userMap:$userMap');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          child: Center(
            child: Column(
              children: [
                FlatButton(
                  child: Text('1v1音频'),
                  onPressed: () {
                    EaseCallKit.startSingleCall(
                      'liu002',
                      callType: EaseCallType.SingeAudio,
                    );
                  },
                ),
                FlatButton(
                  child: Text('1v1视频'),
                  onPressed: () {
                    EaseCallKit.startSingleCall(
                      'liu002',
                      callType: EaseCallType.SingeVideo,
                    );
                  },
                ),
                FlatButton(
                  child: Text('多人'),
                  onPressed: () {
                    Map<String, String> ext = HashMap();
                    ext["groupId"] = "153539520299009";
                    EaseCallKit.startInviteUsers([
                      'liu002',
                      'liu003',
                    ], ext: ext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    EaseCallKit.dispose();
    super.dispose();
  }

  @override
  void callDidEnd(String channelName, EaseCallEndReason reason, int time,
      EaseCallType callType) {
    print(
      '[callDidEnd] channelName --$channelName, reason -- $reason, time -- $time, callType -- $callType',
    );
  }

  @override
  void callDidOccurError(EaseCallError error) {
    print(
      '[callDidOccurError] --$error',
    );
  }

  @override
  void callDidReceive(EaseCallType callType, String inviter, Map ext) {
    print(
      'callDidReceive callType --$callType, inviter -- $inviter, ext -- $ext',
    );
  }

  @override
  void callDidRequestRTCToken(
      String appId, String channelName, String account) {
    print(
      '[callDidRequestRTCToken] appId --$appId, channelName -- $channelName, account -- $account',
    );

    EaseCallKit.getRTCToken(
      channelName,
      appId,
    );
  }

  @override
  void multiCallDidInviting(List<String> excludeUsers, Map ext) {
    print(
      '[multiCallDidInviting] excludeUsers--$excludeUsers, ext -- $ext',
    );
  }
}
