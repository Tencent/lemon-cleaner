//
//  AudioProcessStat.h
//  com.tencent.OwlHelper
//

//  Copyright © 2018年 Tencent. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface AudioProcessStat : NSObject
- (id)initWithWhiteArray:(NSArray*)array;
- (NSMutableArray*)gradAudioProcessInfo;
- (void)startCollectProcessInfo;
- (void)stopCollectProcessInfo;
- (int)getAudioAsistantPid;
#pragma mark deal audio

@end
