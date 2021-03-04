import 'package:ease_call_kit/ease_call_kit.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var user1 = EaseCallUser('username', 'avatar');
    var user2 = EaseCallUser('username1', 'avata1');
    var user3 = EaseCallUser('username2', 'avatar2');

    var config = EaseCallConfig('15cb0d28b87b425ea613fc46f7c9f974');
    config.userMap = {
      'use1': user1,
      'use2': user2,
      'use3': user3,
    };

    EaseCallKit.initWithConfig(config);

    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Container(
            child: Center(
              child: FlatButton(
                child: Text('呼叫'),
                onPressed: () {
                  // EaseCallKit.startSingleCall('du002');
                  EaseCallKit.startInviteUsers(['du005', 'du006']);
                },
              ),
            ),
          )),
    );
  }
}
