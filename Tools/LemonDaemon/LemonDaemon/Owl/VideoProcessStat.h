//
//  VideoProcessStat.h
//  OwlHelper
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoProcessStat : NSObject

- (id)initWithWhiteArray:(NSArray*)array;
- (NSMutableArray*)gradVedioProcessInfo;
- (void)startCollectProcessInfo;
- (void)stopCollectProcessInfo;
- (int)getVedioAsistantPid;
#pragma mark deal vedio
- (NSMutableDictionary*)findWitchProcessUseCamera:(NSDictionary*)message;

#pragma mark deal audio

@end
