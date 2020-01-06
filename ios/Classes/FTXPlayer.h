//
//  FTXPlayer.h
//  Runner
//
//  Created by arcticfox on 2020/1/3.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/FlutterPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXPlayer : NSObject<FlutterStreamHandler,TXLivePlayListener,TXVodPlayListener>

@property(atomic, readonly) NSNumber *playerId;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

-(void)destroy;
@end

NS_ASSUME_NONNULL_END
