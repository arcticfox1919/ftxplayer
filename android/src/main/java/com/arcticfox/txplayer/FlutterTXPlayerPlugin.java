package com.arcticfox.txplayer;

import android.util.Log;
import android.util.SparseArray;

import com.tencent.rtmp.TXLiveBase;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;

/** FlutterTXPlayerPlugin */
public class FlutterTXPlayerPlugin implements MethodCallHandler {
  protected static final String channelName = "arcticfox.com/txplayer";

  final private SparseArray<FTXPlayer> mPlayers;
  final private Registrar registrar;

  public FlutterTXPlayerPlugin(Registrar registrar) {
    this.registrar = registrar;
    mPlayers = new SparseArray();
  }


  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), channelName);
    final FlutterTXPlayerPlugin plugin = new FlutterTXPlayerPlugin(registrar);
    channel.setMethodCallHandler(plugin);

    registrar.addViewDestroyListener(new PluginRegistry.ViewDestroyListener() {
      @Override
      public boolean onViewDestroy(FlutterNativeView flutterNativeView) {
        plugin.onDestroy();
        return false;
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d("**plugin**",call.method);
    if(call.method.equals("getSDKVersion")){
      result.success(TXLiveBase.getSDKVersionStr());
    } else if(call.method.equals("createPlayer")){
      FTXPlayer player = new FTXPlayer(registrar);
      int playerId = player.getPlayerId();
      mPlayers.append(playerId, player);
      result.success(playerId);
    }else if (call.method.equals("releasePlayer")) {
      Integer playerId = call.argument("playerId");
      FTXPlayer player = mPlayers.get(playerId);
      if (player!=null){
        player.release();
        mPlayers.remove(playerId);
      }
      result.success(null);
    }else if (call.method.equals("setConsoleEnabled")){
      Boolean enabled = call.argument("enabled");
      TXLiveBase.setConsoleEnabled(enabled);
    }else {
      result.notImplemented();
    }
  }

  void onDestroy(){
    for (int i = 0; i < mPlayers.size(); i++) {
      FTXPlayer player = mPlayers.valueAt(i);
      player.release();
    }
    mPlayers.clear();
  }


}
