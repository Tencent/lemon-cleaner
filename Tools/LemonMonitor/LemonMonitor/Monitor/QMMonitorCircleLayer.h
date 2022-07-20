//
//  QMMonitorCircleLayer.h
//  QQMacMgrMonitor
//
//  Created by tanhao on 14-7-8.
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface QMMonitorCircleLayer : CALayer
@property (nonatomic, assign) double progress;

- (id)initWithCGImage:(CGImageRef)image;

@end
