//
//  QMMonitorNumberLayer.h
//  QQMacMgrMonitor
//
//  Created by tanhao on 14-7-8.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface QMMonitorNumberLayer : CATextLayer
{
    NSString *showText;
}
@property (nonatomic,assign) double progress;

@end
