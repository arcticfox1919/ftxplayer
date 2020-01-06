//
//  FTXPlayer.m
//  Runner
//
//  Created by arcticfox on 2020/1/3.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <stdatomic.h>
#import "FTXPlayer.h"
#import "QueuingEventSink.h"

static atomic_int atomicId = 0;
static const int uninitialized = -1;

@implementation FTXPlayer{
    QueuingEventSink *_eventSink;
    FlutterMethodChannel *_methodChannel;
    FlutterEventChannel *_eventChannel;

    id<FlutterPluginRegistrar> _registrar;
//    id<FlutterTextureRegistry> _textureRegistry;
//
//    CVPixelBufferRef volatile _latestPixelBuffer;
//    CVPixelBufferRef _lastBuffer;
    
    TXLivePlayer *_txLivePlayer;
    TXVodPlayer *_txVodPlayer;
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
        _eventSink = [QueuingEventSink new];
//        _latestPixelBuffer = nil;
//        _lastBuffer = nil;


        _methodChannel = [FlutterMethodChannel
            methodChannelWithName:[@"arcticfox.com/txplayer/"
                                      stringByAppendingString:[_playerId
                                                                  stringValue]]
                  binaryMessenger:[registrar messenger]];

        __block typeof(self) weakSelf = self;
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall *call,
                                               FlutterResult result) {
          [weakSelf handleMethodCall:call result:result];
        }];

        _eventChannel = [FlutterEventChannel
            eventChannelWithName:[@"arcticfox.com/txplayer/event/"
                                     stringByAppendingString:[_playerId
                                                                 stringValue]]
                 binaryMessenger:[registrar messenger]];

        [_eventChannel setStreamHandler:self];
    }

    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;
    
    if([@"init" isEqualToString:call.method]){
        int playerType = [args[@"playerType"] intValue];
        BOOL onlyAudio = [args[@"onlyAudio"] boolValue];
        NSNumber* textureId = [self createPlayer:playerType onlyAudio:onlyAudio];
        result(textureId);
    }else if([@"play" isEqualToString:call.method]){
        NSString *url = args[@"url"];
        int type = -1;
        if(![[args objectForKey:@"playType"] isEqual:[NSNull null]]){
            type = [args[@"playType"] intValue];
        }
        int r = [self startPlay:url type:type];
        result(@(r));
    }else if([@"stop" isEqualToString:call.method]){
        BOOL r = [self stopPlay];
        result([NSNumber numberWithBool:r]);
    }else if([@"isPlaying" isEqualToString:call.method]){
        result([NSNumber numberWithBool:[self isPlaying]]);
    }else if([@"pause" isEqualToString:call.method]){
        [self pause];
        result(nil);
    }else if([@"resume" isEqualToString:call.method]){
        [self resume];
        result(nil);
    }else if([@"setMute" isEqualToString:call.method]){
        BOOL mute = [args[@"mute"] boolValue];
        [self setMute:mute];
        result(nil);
    }else if([@"setVolume" isEqualToString:call.method]){
        int volume = [args[@"volume"] intValue];
        [self setVolume:volume];
        result(nil);
    }else if([@"setLiveMode" isEqualToString:call.method]){
        int type = [args[@"type"] intValue];
        [self setLiveMode:type];
        result(nil);
    }else if([@"setLoop" isEqualToString:call.method]){
        BOOL loop = [args[@"loop"] boolValue];
        [self setLoop:loop];
        result(nil);
    }else {
      result(FlutterMethodNotImplemented);
    }
}


- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:
                                           (nonnull FlutterEventSink)events {
    [_eventSink setDelegate:events];
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    [_eventSink setDelegate:nil];
    return nil;
}

- (NSNumber*)createPlayer:(int)playerType onlyAudio:(BOOL)onlyAudio{
    if (playerType == 0) {
        if (_txLivePlayer == nil) {
            _txLivePlayer = [TXLivePlayer new];
            _txLivePlayer.delegate = self;
        }
    }else{
        if (_txVodPlayer == nil){
            _txVodPlayer = [TXVodPlayer new];
            _txVodPlayer.vodDelegate = self;
        }
    }
    return [NSNumber numberWithInt:-1];
}

- (int)startPlay:(NSString *)url type:(TX_Enum_PlayType)playType  {
    if (_txLivePlayer != nil) {
        return [_txLivePlayer startPlay:url type:playType];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer startPlay:url];
    }
    return uninitialized;
}

- (BOOL)stopPlay{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer stopPlay];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer stopPlay];
    }
    return NO;
}

-(BOOL)isPlaying{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer isPlaying];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer isPlaying];
    }
    return NO;
}

-(void)pause{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer pause];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer pause];
    }
}

-(void)resume{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer resume];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer resume];
    }
}

- (void)setMute:(BOOL)bEnable {
    if (_txLivePlayer != nil) {
        return [_txLivePlayer setMute:bEnable];
    }else if(_txVodPlayer != nil){
        return [_txVodPlayer setMute:bEnable];
    }
}

- (void)setVolume:(int)volume{
    if (_txLivePlayer != nil) {
        return [_txLivePlayer setVolume:volume];
    }
}

-(void)setLiveMode:(int)type{
    TXLivePlayConfig*  _config = [TXLivePlayConfig new];
    
    if (type == 0) {
        //自动模式
        _config.bAutoAdjustCacheTime   = YES;
        _config.minAutoAdjustCacheTime = 1;
        _config.maxAutoAdjustCacheTime = 5;
    }else if(type == 1){
        //极速模式
        _config.bAutoAdjustCacheTime   = YES;
        _config.minAutoAdjustCacheTime = 1;
        _config.maxAutoAdjustCacheTime = 1;
    }else{
        //流畅模式
        _config.bAutoAdjustCacheTime   = NO;
        _config.minAutoAdjustCacheTime = 5;
        _config.maxAutoAdjustCacheTime = 5;
    }
    [_txLivePlayer setConfig:_config];
}

-(void)setLoop:(BOOL)bLoop{
    if (_txVodPlayer != nil) {
        _txVodPlayer.loop = bLoop;
    }
}

/**
 * 直播事件通知
 * @param EvtID 参见 TXLiveSDKEventDef.h
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary *)param{
    switch (EvtID) {
        case PLAY_EVT_CONNECT_SUCC: //已经连接服务器
        case PLAY_EVT_RTMP_STREAM_BEGIN: //已经连接服务器，开始拉流（仅播放 RTMP 地址时会抛送）
        case PLAY_EVT_RCV_FIRST_I_FRAME: //收到首帧数据，越快收到此消息说明链路质量越好
        case PLAY_EVT_PLAY_BEGIN: //视频播放开始，如果您自己做 loading，会需要它
        case PLAY_EVT_PLAY_END: //播放结束，HTTP-FLV 的直播流不抛这个事件
        case PLAY_ERR_NET_DISCONNECT: //网络断连，且经多次重连亦不能恢复，更多重试请自行重启播放
        case PLAY_EVT_CHANGE_RESOLUTION: //视频分辨率发生变化（分辨率在 EVT_PARAM 参数中）
        case PLAY_WARNING_RECONNECT:
        case PLAY_WARNING_DNS_FAIL:
        case PLAY_WARNING_SEVER_CONN_FAIL:
        case PLAY_WARNING_SHAKE_FAIL:
            [_eventSink success:[FTXPlayer getParamsWithEvent:EvtID withParams:param]];
            break;
        default:
            break;
    }
}

+(NSDictionary *)getParamsWithEvent:(int)EvtID withParams:(NSDictionary *)params{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtID) forKey:@"event"];
    
    if (params != nil && params.count != 0) {
        for (NSString *key in params) {
            NSObject* value = params[key];
            dict[key] = value;
        }
    }
    return dict;
}
/**
 * 网络状态通知
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onNetStatus:(NSDictionary *)param{
    
}

/**
 * 点播事件通知
 *
 * @param player 点播对象
 * @param EvtID 参见TXLiveSDKTypeDef.h
 * @param param 参见TXLiveSDKTypeDef.h
 * @see TXVodPlayer
 */
-(void) onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param{
    
}

/**
 * 网络状态通知
 *
 * @param player 点播对象
 * @param param 参见TXLiveSDKTypeDef.h
 * @see TXVodPlayer
 */
-(void) onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary*)param{
    
}

-(void)destroy{
    [self stopPlay];
    _txLivePlayer = nil;
    _txVodPlayer = nil;
    
    [_methodChannel setMethodCallHandler:nil];
    _methodChannel = nil;

    [_eventSink setDelegate:nil];
    _eventSink = nil;
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
}
@end
