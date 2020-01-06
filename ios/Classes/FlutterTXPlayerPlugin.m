#import <TXLiteAVSDK_Player/TXLiveBase.h>
#import "FlutterTXPlayerPlugin.h"
#import "FTXPlayer.h"



@implementation FlutterTXPlayerPlugin{
    NSObject<FlutterPluginRegistrar> *_registrar;
    NSMutableDictionary<NSNumber *, FTXPlayer *> *_players;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"arcticfox.com/txplayer"
            binaryMessenger:[registrar messenger]];
    
    FlutterTXPlayerPlugin* instance = [[FlutterTXPlayerPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _players = [NSMutableDictionary new];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if([@"getSDKVersion" isEqualToString:call.method]){
      result([TXLiveBase getSDKVersionStr]);
  }else if([@"createPlayer" isEqualToString:call.method]){
      FTXPlayer* player = [[FTXPlayer alloc] initWithRegistrar:_registrar];
      NSNumber *playerId = player.playerId;
      _players[playerId] = player;
      result(playerId);
  }else if([@"releasePlayer" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      NSNumber *pid = args[@"playerId"];
      FTXPlayer *player = [_players objectForKey:pid];
      [player destroy];
      if (player != nil) {
          [_players removeObjectForKey:pid];
      }
      result(nil);
  }else if([@"setConsoleEnabled" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      BOOL enabled = [args[@"enabled"] boolValue];
      [TXLiveBase setConsoleEnabled:enabled];
      result(nil);
  }else {
    result(FlutterMethodNotImplemented);
  }
}

@end
