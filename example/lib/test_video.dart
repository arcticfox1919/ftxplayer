
import 'package:flutter/material.dart';
import 'package:ftxplayer/ftxplayer.dart';

class VideoLive extends StatefulWidget {
  @override
  _VideoLiveState createState() => _VideoLiveState();
}

class _VideoLiveState extends State<VideoLive> {
  FTXPlayerController _controller = FTXPlayerController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
    _controller.play("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FTXPlayerVideo(controller: _controller,),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
