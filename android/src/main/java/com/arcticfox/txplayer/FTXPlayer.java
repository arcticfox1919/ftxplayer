package com.arcticfox.txplayer;

import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.util.Log;
import android.view.Surface;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.TextureRegistry;

import com.tencent.rtmp.ITXLivePlayListener;
import com.tencent.rtmp.ITXVodPlayListener;
import com.tencent.rtmp.TXLiveConstants;
import com.tencent.rtmp.TXLivePlayConfig;
import com.tencent.rtmp.TXLivePlayer;
import com.tencent.rtmp.TXVodPlayer;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

public class FTXPlayer implements MethodChannel.MethodCallHandler, ITXLivePlayListener, ITXVodPlayListener {
    private static final AtomicInteger mAtomicId = new AtomicInteger(0);

    final private PluginRegistry.Registrar registrar;
    private final int mPlayerId;
    private final EventChannel mEventChannel;
    private TextureRegistry.SurfaceTextureEntry mSurfaceTextureEntry;
    final private MethodChannel mMethodChannel;
    private SurfaceTexture mSurfaceTexture;
    private Surface mSurface;

    final private QueuingEventSink mEventSink = new QueuingEventSink();
    private TXVodPlayer mVodPlayer;
    private TXLivePlayConfig mLivePlayConfig;


    public FTXPlayer(PluginRegistry.Registrar registrar) {
        this.registrar = registrar;
        mPlayerId = mAtomicId.incrementAndGet();
        mMethodChannel = new MethodChannel(registrar.messenger(), FlutterTXPlayerPlugin.channelName + "/" + mPlayerId);
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(registrar.messenger(), FlutterTXPlayerPlugin.channelName + "/event/" + mPlayerId);
        mEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object o, EventChannel.EventSink eventSink) {
                mEventSink.setEventSinkProxy(eventSink);
            }

            @Override
            public void onCancel(Object o) {
                mEventSink.setEventSinkProxy(null);
            }
        });
    }

    private TXLivePlayer mLivePlayer;

    private static final int Uninitialized = -101;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("init")) {
            boolean onlyAudio = call.argument("onlyAudio");
            int playerType = call.argument("playerType");
            long id = init(onlyAudio, playerType);
            result.success(id);
        } else if (call.method.equals("play")) {
            String url = call.argument("url");
            Integer type = call.argument("playType");
            int r = startPlay(url, type == null ? -1 : type);
            result.success(r);
        } else if (call.method.equals("stop")) {
            Boolean isNeedClear = call.argument("isNeedClear");
            int r = stopPlay(isNeedClear);
            result.success(r);
        } else if (call.method.equals("isPlaying")) {
            boolean r = isPlaying();
            result.success(r);
        } else if (call.method.equals("pause")) {
            pause();
            result.success(null);
        } else if (call.method.equals("resume")) {
            resume();
            result.success(null);
        } else if (call.method.equals("setMute")) {
            boolean mute = call.argument("mute");
            setMute(mute);
            result.success(null);
        } else if (call.method.equals("setVolume")) {
            Integer volume = call.argument("volume");
            setVolume(volume);
            result.success(null);
        } else if (call.method.equals("setLiveMode")) {
            Integer type = call.argument("type");
            setLiveMode(type);
            result.success(null);
        } else if (call.method.equals("setLoop")) {
            boolean loop = call.argument("loop");
            setLoop(loop);
            result.success(null);
        }else {
            result.notImplemented();
        }
    }

    protected long init(boolean onlyAudio, int playerType) {
        if (playerType == 0) {
            if (mLivePlayer == null) {
                mLivePlayer = new TXLivePlayer(registrar.context());
                mLivePlayer.setPlayListener(this);
                setPlayer(onlyAudio);
            }
        } else {
            if (mVodPlayer == null) {
                mVodPlayer = new TXVodPlayer(registrar.context());
                mVodPlayer.setVodListener(this);
                setPlayer(onlyAudio);
            }
        }
//        Log.d("AndroidLog", "textureId :" + mSurfaceTextureEntry.id());
        return mSurfaceTextureEntry == null ? -1 : mSurfaceTextureEntry.id();
    }

    void setPlayer(boolean onlyAudio) {
        if (!onlyAudio) {
            TextureRegistry textureRegistry = registrar.textures();
            mSurfaceTextureEntry = textureRegistry.createSurfaceTexture();
            mSurfaceTexture = mSurfaceTextureEntry.surfaceTexture();
            mSurface = new Surface(mSurfaceTexture);

            if (mLivePlayer != null) {
                mLivePlayer.setSurface(mSurface);
                mLivePlayer.setSurfaceSize(1024,576);
                mLivePlayer.enableHardwareDecode(true);
            }

            if (mVodPlayer != null) {
                mVodPlayer.setSurface(mSurface);
                mVodPlayer.enableHardwareDecode(true);
            }
        }
    }

    protected void release() {
        if (mLivePlayer != null) {
            mLivePlayer.stopPlay(true);
            mLivePlayer = null;
        }

        if (mVodPlayer != null) {
            mVodPlayer.stopPlay(true);
            mVodPlayer = null;
        }

        if (mSurfaceTextureEntry != null) {
            mSurfaceTextureEntry.release();
            mSurfaceTextureEntry = null;
        }
        if (mSurfaceTexture != null) {
            mSurfaceTexture.release();
            mSurfaceTexture = null;
        }
        if (mSurface != null) {
            mSurface.release();
            mSurface = null;
        }
        mMethodChannel.setMethodCallHandler(null);
        mEventChannel.setStreamHandler(null);
    }

    void setLiveMode(int type) {
        if (mLivePlayConfig ==null) mLivePlayConfig = new TXLivePlayConfig();
        if (type == 0) {
            //自动模式
            mLivePlayConfig.setAutoAdjustCacheTime(true);
            mLivePlayConfig.setMinAutoAdjustCacheTime(1);
            mLivePlayConfig.setMaxAutoAdjustCacheTime(5);
        } else if (type == 1) {
            //极速模式
            mLivePlayConfig.setAutoAdjustCacheTime(true);
            mLivePlayConfig.setMinAutoAdjustCacheTime(1);
            mLivePlayConfig.setMaxAutoAdjustCacheTime(1);
        } else {
            //流畅模式
            mLivePlayConfig.setAutoAdjustCacheTime(false);
            mLivePlayConfig.setMinAutoAdjustCacheTime(5);
            mLivePlayConfig.setMaxAutoAdjustCacheTime(5);
        }

        if (mLivePlayer != null){
            mLivePlayer.setConfig(mLivePlayConfig);
        }
    }


    int startPlay(String url, int playType) {
        if (mLivePlayer != null) {
            return mLivePlayer.startPlay(url, playType);
        } else if (mVodPlayer != null) {
            return mVodPlayer.startPlay(url);
        }
        return Uninitialized;
    }

    int stopPlay(boolean isNeedClearLastImg) {
        if (mLivePlayer != null) {
            return mLivePlayer.stopPlay(isNeedClearLastImg);
        } else if (mVodPlayer != null) {
            return mVodPlayer.stopPlay(isNeedClearLastImg);
        }
        return Uninitialized;
    }

    boolean isPlaying() {
        if (mLivePlayer != null) {
            return mLivePlayer.isPlaying();
        } else if (mVodPlayer != null) {
            return mVodPlayer.isPlaying();
        }
        return false;
    }

    void pause() {
        if (mLivePlayer != null) {
            mLivePlayer.pause();
        } else if (mVodPlayer != null) {
            mVodPlayer.pause();
        }
    }

    void resume() {
        if (mLivePlayer != null) {
            mLivePlayer.resume();
        } else if (mVodPlayer != null) {
            mVodPlayer.resume();
        }
    }

    void setMute(boolean mute) {
        if (mLivePlayer != null) {
            mLivePlayer.setMute(mute);
        } else if (mVodPlayer != null) {
            mVodPlayer.setMute(mute);
        }
    }

    void setVolume(int volume) {
        if (mLivePlayer != null) {
            mLivePlayer.setVolume(volume);
        } else if (mVodPlayer != null) {
//            mVodPlayer.setVolume(volume);
        }
    }

    void setLoop(boolean loop){
        if (mVodPlayer != null){
            mVodPlayer.setLoop(loop);
        }
    }

    void setConfig() {
        mLivePlayConfig = new TXLivePlayConfig();
    }

    public int getPlayerId() {
        return mPlayerId;
    }


    /* see: https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6 */
    @Override
    public void onPlayEvent(int event, Bundle bundle) {
        switch (event) {
            case TXLiveConstants.PLAY_EVT_CONNECT_SUCC: //已经连接服务器
            case TXLiveConstants.PLAY_EVT_RTMP_STREAM_BEGIN: //已经连接服务器，开始拉流（仅播放 RTMP 地址时会抛送）
            case TXLiveConstants.PLAY_EVT_RCV_FIRST_I_FRAME: //收到首帧数据，越快收到此消息说明链路质量越好
            case TXLiveConstants.PLAY_EVT_PLAY_BEGIN: //视频播放开始，如果您自己做 loading，会需要它
            case TXLiveConstants.PLAY_EVT_PLAY_END: //播放结束，HTTP-FLV 的直播流不抛这个事件
            case TXLiveConstants.PLAY_ERR_NET_DISCONNECT: //网络断连，且经多次重连亦不能恢复，更多重试请自行重启播放
            case TXLiveConstants.PLAY_EVT_CHANGE_RESOLUTION: //视频分辨率发生变化（分辨率在 EVT_PARAM 参数中）

            case TXLiveConstants.PLAY_WARNING_RECONNECT:
            case TXLiveConstants.PLAY_WARNING_DNS_FAIL:
            case TXLiveConstants.PLAY_WARNING_SEVER_CONN_FAIL:
            case TXLiveConstants.PLAY_WARNING_SHAKE_FAIL:
                mEventSink.success(getParams(event, bundle));
                break;
            default:
        }
    }

    @Override
    public void onPlayEvent(TXVodPlayer txVodPlayer, int i, Bundle bundle) {

    }


    private Map<String, Object> getParams(int event, Bundle bundle) {
        Map<String, Object> param = new HashMap();
        param.put("event", event);

        if (bundle != null && !bundle.isEmpty()) {
            Set<String> keySet = bundle.keySet();
            for (String key : keySet) {
                Object val = bundle.get(key);
                param.put(key, val);
            }
        }

        return param;
    }

    @Override
    public void onNetStatus(Bundle bundle) {

    }

    @Override
    public void onNetStatus(TXVodPlayer txVodPlayer, Bundle bundle) {

    }
}
