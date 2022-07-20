//
//  AudioObserver.h
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioObserver : NSObject

@property (nonatomic, strong) NSString *audioName;
- (BOOL)isAudioDeviceActive;
- (void)startAudioObserver;
- (void)stopAudioObserver;

@end
