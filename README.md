# ftxplayer
腾讯云播放器SDK的Flutter插件

支持直播与点播

### 使用:

`pubspec.yaml`中增加配置

```yaml
  ftxplayer:
    git:
      url: git@github.com:arcticfox1919/ftxplayer.git
```

然后更新依赖包

添加原生配置

在Android的`AndroidManifest.xml`中增加如下配置
```xml
    <!--网络权限-->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

在iOS的`Info.plist`中增加如下配置
```xml
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
```

Flutter 中调用

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ftxplayer/ftxplayer.dart';

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
    // 开启调试日志
    await FTXPlayerController.setConsoleEnabled(true);
    // 初始化播放器
    await _controller.initialize(onlyAudio: true);
    // 设置循环播放
    await _controller.setLoop(true);
    // 开始播放
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
```
