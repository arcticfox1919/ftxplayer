part of ftxplayer;

class FTXPlayerPlugin {
  static const String channelName = "arcticfox.com/txplayer";
  static const MethodChannel _channel = const MethodChannel(channelName);


  static Future<String> get sdkVersion async {
    final String version = await _channel.invokeMethod('getSDKVersion');
    return version;
  }

  static Future<int> _createPlayer() async{
    return await _channel.invokeMethod('createPlayer');
  }

  static Future<int> _releasePlayer(int playerId) async{
    return await _channel.invokeMethod('releasePlayer',{"playerId":playerId});
  }

  static Future<int> _setConsoleEnabled(bool enabled) async{
    return await _channel.invokeMethod('setConsoleEnabled',{"enabled":enabled});
  }
}
