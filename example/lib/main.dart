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
    var config = EaseCallConfig('15cb0d28b87b425ea613fc46f7c9f974');
    EaseCallKit.initWithConfig(config);
    EaseCallKit.listener = this;
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
                      'du002',
                      callType: EaseCallType.SingeAudio,
                    );
                  },
                ),
                FlatButton(
                  child: Text('1v1视频'),
                  onPressed: () {
                    EaseCallKit.startSingleCall(
                      'du002',
                      callType: EaseCallType.SingeVideo,
                    );
                  },
                ),
                FlatButton(
                  child: Text('多人'),
                  onPressed: () {
                    EaseCallKit.startInviteUsers([
                      'du002',
                      'du003',
                      'du004',
                      'du005',
                    ]);
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
      'channelName --$channelName, reason -- $reason, time -- $time, callType -- $callType',
    );
  }

  @override
  void callDidOccurError(EaseCallError error) {
    print(
      'error --$error',
    );
  }

  @override
  void callDidReceive(EaseCallType callType, String inviter, Map ext) {
    print(
      'callType --$callType, inviter -- $inviter, ext -- $ext',
    );
  }

  @override
  void callDidRequestRTCToken(
      String appId, String channelName, String account) {
    print(
      'appId --$appId, channelName -- $channelName, account -- $account',
    );
  }

  @override
  void multiCallDidInviting(List<String> excludeUsers, Map ext) {
    print(
      'excludeUsers --$excludeUsers, ext -- $ext',
    );
  }
}
