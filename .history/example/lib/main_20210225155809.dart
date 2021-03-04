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
    Map map = {"k": "v", "k1": "v1"};
    List list = map.keys.map((e) => {e)}).toList();
    print('list --- $list');

    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Container(
            child: Center(
              child: FlatButton(
                child: Text('呼叫'),
                onPressed: () {},
              ),
            ),
          )),
    );
  }
}
