
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_txplayer/ftxplayer.dart';

class TestFTXPlayer extends StatefulWidget {
  @override
  _TestFTXPlayerState createState() => _TestFTXPlayerState();
}

class _TestFTXPlayerState extends State<TestFTXPlayer> {
  FTXPlayerController _controller = FTXPlayerController();


  Future<void> init() async {
    if (!mounted) return;
    _controller.onPlayerState.listen((val){
      debugPrint("********** $val **********");
    });
    await FTXPlayerController.setConsoleEnabled(true);
    await _controller.initialize(onlyAudio: true);
    await _controller.setLoop(true);
//    await _controller.setLiveMode(LiveMode.Speed);
    await _controller.play("http://music.163.com/song/media/outer/url?id=436514312.mp3");
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          RaisedButton(
            onPressed: ()=>_controller.pause(),
            child: Text("暂停"),
          ),
          RaisedButton(
            onPressed: ()=>_controller.resume(),
            child: Text("继续"),
          )
        ],
      ),),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
