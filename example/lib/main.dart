import 'package:flutter/material.dart';
import 'package:flutter_txplayer_example/test_ftxplayer.dart';
import 'package:flutter_txplayer_example/test_video.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: RaisedButton(child: Text("Video"),onPressed: (){
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => VideoLive()));
        },),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => TestFTXPlayer()));
        },
        child: Icon(Icons.fiber_new),
      ),
    );
  }
}
