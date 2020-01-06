part of ftxplayer;

class FTXPlayerVideo extends StatefulWidget {
  final FTXPlayerController controller;

  FTXPlayerVideo({@required this.controller}):assert(controller != null);

  @override
  _FTXPlayerVideoState createState() => _FTXPlayerVideoState();
}

class _FTXPlayerVideoState extends State<FTXPlayerVideo> {
  int _textureId = 1;

  @override
  void initState() {
    super.initState();

    widget.controller.textureId.then((val) {
      setState(() {
        print("_textureId = $val");
        _textureId = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == -1
        ? Container()
        : Texture(
            textureId: _textureId,
          );
  }
}
