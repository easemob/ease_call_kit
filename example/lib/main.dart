import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:ease_call_kit/ease_call_kit.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;

const String appkey = "easemob-demo#easeim";
const String emUsername = "du001";
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
                TextButton(
                  child: Text('1v1音频'),
                  onPressed: () {
                    EaseCallKit.startSingleCall(
                      'du002',
                      callType: EaseCallType.SingeAudio,
                    );
                  },
                ),
                TextButton(
                  child: Text('1v1视频'),
                  onPressed: () {
                    EaseCallKit.startSingleCall(
                      'du002',
                      callType: EaseCallType.SingeVideo,
                    );
                  },
                ),
                TextButton(
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
    debugPrint(
      "callDidEnd channelName: $channelName, reason: $reason, time: $time",
    );
  }

  @override
  void callDidJoinChannel(String channelName, int uid) {
    debugPrint(
      "callDidJoinChannel channelName: $channelName, uid: $uid",
    );
  }

  @override
  void callDidOccurError(EaseCallError error) {
    debugPrint(
      "callDidOccurError: $error",
    );
  }

  @override
  void callDidReceive(EaseCallType callType, String inviter, Map? ext) {
    debugPrint(
      "callDidReceive callType: $callType, inviter: $inviter, ext: $ext",
    );
  }

  @override
  void callDidRequestRTCToken(
      String appId, String channelName, String eid, int uid) async {
    debugPrint(
      "callDidRequestRTCToken appId: $appId, channelName: $channelName, eid: $eid, uid: $uid",
    );
    // String? rtcToken =
    await fetchRTCToken(channelName, emUsername);
  }

  @override
  void multiCallDidInviting(List<String?> excludeUsers, Map? ext) {
    debugPrint(
      "multiCallDidInviting excludeUsers: $excludeUsers, ext: $ext",
    );
  }

  @override
  void remoteUserDidJoinChannel(String channelName, int uid, String eid) {
    debugPrint(
      "remoteUserDidJoinChannel channelName: $channelName, uid: $uid, eid: $eid",
    );
  }

  Future<String?> fetchRTCToken(String channelName, String username) async {
    String? token = await EaseCallKit.getTestUserToken();
    if (token == null) return null;
    var httpClient = new HttpClient();
    var uri = Uri.http("a1.easemob.com", "/token/rtcToken/v1", {
      "userAccount": username,
      "channelName": channelName,
      "appkey": appkey,
    });
    var request = await httpClient.getUrl(uri);
    request.headers.add("Authorization", "Bearer $token");
    HttpClientResponse response = await request.close();
    httpClient.close();
    if (response.statusCode == HttpStatus.ok) {
      var _content = await response.transform(Utf8Decoder()).join();
      debugPrint(_content);
      Map<String, dynamic>? map = convert.jsonDecode(_content);
      if (map != null) {
        if (map["code"] == "RES_0K") {
          debugPrint("获取数据成功: $map");
          String rtcToken = map["accessToken"];
          int agoraUserId = map["agoraUserId"];
          await EaseCallKit.setRTCToken(rtcToken, channelName, agoraUserId);
        }
      }
    }
  }
}
