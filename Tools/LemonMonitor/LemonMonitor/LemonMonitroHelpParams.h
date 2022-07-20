//
//  LemonMonitroHelpParams.h
//  LemonMonitor
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/McProcessInfoData.h>

@interface LemonMonitroHelpParams : NSObject
+ (LemonMonitroHelpParams*)sharedInstance;
@property NSInteger  startParamsCmd;
@property NSDictionary*  startParamsExtra;

@property (nonatomic, strong) NSMutableArray<McProcessInfoData*> *topMemoryArray;

- (void)startStatMemory;
- (void)stopStatMemory;

@end
