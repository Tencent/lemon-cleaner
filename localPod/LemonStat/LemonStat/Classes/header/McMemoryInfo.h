//
//  McMemoryInfo.h
//  TestFunction
//
//  Created by developer on 11-1-24.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface McMemoryInfo : NSObject 
{
    NSArray     *physMemInfo;
    NSString    *memSpeed;
    NSString    *memType;
    
    NSArray     *pageInfo;
    double      lastUpdateTime;
    uint64_t    oldPagein;
    uint64_t    oldPageout;
}

// update physical memory information
// index from 0 - 3: free / inactive / active / wired / total
// unsigned long long (B)
- (BOOL) UpdatePhysMemInfo;

// update memory speed and type
- (BOOL) UpdateMemSpeedType;

// property
/**
 0: free
 1:inacitve
 2:active
 3:wired
 4:物理总内存
 5:已使用内存（参考cleanmymac）
 */
@property (strong) NSArray    *physMemInfo;
@property (strong) NSString   *memSpeed;
@property (strong) NSString   *memType;
@property (strong) NSArray    *pageInfo;

@end
