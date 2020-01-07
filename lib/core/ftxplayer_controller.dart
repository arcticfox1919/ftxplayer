part of ftxplayer;

///
/// 播放器类型
///
enum PlayerType {
  LivePlayer, // 直播播放器
  VodPlayer   // 点播播放器
}

class FTXPlayerController extends ChangeNotifier implements ValueListenable<FtxValue> {
  int _playerId = -1;

  final Completer<int> _initPlayer;
  final Completer<int> _createTexture;
  final PlayerType playerType;
  bool _isDisposed = false;
  bool _isNeedDisposed = false;
  MethodChannel _channel;
  FtxValue _value;
  FtxState _state;

  FtxState get playState => _state;
  StreamSubscription _eventSubscription;

  final StreamController<FtxState> _stateStreamController =
  StreamController.broadcast();

  final StreamController<FtxWarning> _warningStreamController =
  StreamController.broadcast();

  Stream<FtxState> get onPlayerState => _stateStreamController.stream;
  Stream<FtxWarning> get onWarning => _warningStreamController.stream;

  FTXPlayerController({this.playerType = PlayerType.VodPlayer})
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = FtxValue.uninitialized();
    _state = _value.state;
    _create();
  }

  Future<void> _create() async {
    _playerId = await FTXPlayerPlugin._createPlayer();
    _channel = MethodChannel("${FTXPlayerPlugin.channelName}/$_playerId");
    _eventSubscription =
        EventChannel("${FTXPlayerPlugin.channelName}/event/$_playerId")
            .receiveBroadcastStream()
            .listen(_eventHandler, onError: _errorHandler);

    _initPlayer.complete(_playerId);
  }

  ///
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  _eventHandler(event) {
    if(event == null) return;
    final Map<dynamic, dynamic> map = event;
    debugPrint("= event = ${map.toString()}");
    switch(map["event"]){
      case 2002:
        break;
      case 2003:
        break;
      case 2004:
        if(_isNeedDisposed) return;
        _changeState(FtxState.playing);
        break;
      case 2006:
        _stateStreamController.add(FtxState.completed);
        break;
      case -2301:
        _warningStreamController.add(FtxWarning.disconnect);
        break;
      case 2103:
        _warningStreamController.add(FtxWarning.reconnect);
        break;
      case 3001:
        _warningStreamController.add(FtxWarning.dnsFail);
        break;
      case 3002:
        _warningStreamController.add(FtxWarning.severConnFail);
        break;
      case 3003:
        _warningStreamController.add(FtxWarning.shakeFail);
        break;

      default:
    }
  }

  _errorHandler(error) {}

  Future<int> get textureId async {
    return _createTexture.future;
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  ///
  Future<bool> play(String url, {int playType}) async {
    await _initPlayer.future;
    await _createTexture.future;
    _changeState(FtxState.prepared);

    final result =
        await _channel.invokeMethod("play", {"url": url, "playType": playType});
    return result == 0;
  }

  _changeState(FtxState playerState){
    value = _value.copyWith(state: playerState);
    _state = value.state;
    _stateStreamController.add(_state);
  }

  Future<void> initialize({bool onlyAudio}) async{
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    final textureId = await _channel.invokeMethod("init", {
      "onlyAudio": onlyAudio ?? false,
      "playerType": playerType.index
    });
    _createTexture.complete(textureId);
    _changeState(FtxState.initialized);
  }

  Future<bool> stop({bool isNeedClear = true}) async {
    if(_isNeedDisposed) return false;
    await _initPlayer.future;
    final result =
        await _channel.invokeMethod("stop", {"isNeedClear": isNeedClear});
    _changeState(FtxState.stopped);
    return result == 0;
  }

  Future<bool> isPlaying() async {
    await _initPlayer.future;
    return await _channel.invokeMethod("isPlaying");
  }

  Future<void> pause() async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("pause");
    _changeState(FtxState.paused);
  }

  Future<void> resume() async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("resume");
  }

  Future<void> setLiveMode(LiveMode mode) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLiveMode", {"type": mode.index});
  }

  ///
  /// 该方法仅在使用[LivePlayer]播放器时有效
  /// 音量大小，范围 (0 - 100)
  ///
  Future<void> setVolume(int volume) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setVolume", {"volume": volume});
  }

  Future<void> setMute(bool mute) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setMute", {"mute": mute});
  }

  Future<void> setLoop(bool loop) async {
    if(_isNeedDisposed) return;
    await _initPlayer.future;
    await _channel.invokeMethod("setLoop", {"loop": loop});
  }

  Future<void> _release() async {
    await _initPlayer.future;
    await FTXPlayerPlugin._releasePlayer(_playerId);
  }

  @override
  void dispose() async{
    _isNeedDisposed = true;
    if(!_isDisposed){
      await _eventSubscription.cancel();
      _eventSubscription = null;

      await _release();
      _changeState(FtxState.disposed);
      _isDisposed = true;
      _stateStreamController.close();
      _warningStreamController.close();
    }

    super.dispose();
  }

  @override
  get value => _value;

  set value(FtxValue val){
    if (_value == val) return;
    _value = val;
    notifyListeners();
  }

  ///
  /// 设置是否在控制台打印 SDK 的相关日志输出
  ///
  static Future<void> setConsoleEnabled(bool enabled) async{
    await FTXPlayerPlugin._setConsoleEnabled(enabled);
  }
}

class FtxValue{
  final FtxState state;
  FtxValue.uninitialized():this(state:FtxState.idle);

  FtxValue({@required this.state});

  FtxValue copyWith({FtxState state}){
    return FtxValue(
        state:state ?? this.state
    );
  }
}

///
/// 直播类型
///
abstract class PlayType{

  ///
  /// see: https://cloud.tencent.com/document/product/454/7886
  ///
  static const LIVE_RTMP = 0;
  static const LIVE_FLV = 1;
  static const LIVE_RTMP_ACC = 5;
  static const VOD_HLS = 3;
}

enum LiveMode{
  Automatic, // 自动模式
  Speed,     // 极速模式
  Smooth     // 流畅模式
}

enum FtxState{
  idle,
  initialized,
  prepared,
  playing,
  paused,
  stopped,
  completed,
  disposed
}

enum FtxWarning{
  reconnect, // 网络中断，自动重连中
  disconnect, // 网络中断，重连失败
  dnsFail, // RTMP-DNS 解析失败
  severConnFail, // RTMP 服务器连接失败
  shakeFail, // RTMP 服务器握手失败
}