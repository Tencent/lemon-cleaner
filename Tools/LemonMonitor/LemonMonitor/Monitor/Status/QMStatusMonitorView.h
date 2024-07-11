//
//  QMStatusMonitorView.h
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMMonitorView2.h"

@class QMStatusCircleView;
@class QMStatusTextField;
@interface QMStatusMonitorView : QMMonitorView2
{
    NSImageView* logo;
    
    __weak NSTextField* mUpSpeedField;
    __weak NSTextField* mDownSpeedField;
    __weak NSTextField* mMemUsageField;
    __weak NSTextField* mDiskUsageField;
    __weak NSTextField* mCpuTempField;
    __weak NSTextField* mCpuFanSpeedField;
    __weak NSTextField* mCpuUsageField;
    __weak NSTextField* mGpuUsageField;
    
    BOOL mDarkModeOn;
}

@property (nonatomic, assign) float upSpeed;
@property (nonatomic, assign) float downSpeed;
@property (nonatomic, assign) int statusNum;

#define STATUS_TYPE_LOGO (1 << 0)
#define STATUS_TYPE_MEM  (1 << 1)
#define STATUS_TYPE_DISK (1 << 2)
#define STATUS_TYPE_TEP  (1 << 3)
#define STATUS_TYPE_FAN  (1 << 4)
#define STATUS_TYPE_NET  (1 << 5)
#define STATUS_TYPE_CPU  (1 << 6)
#define STATUS_TYPE_GPU  (1 << 7)

-(void)setStatusType:(long)type;
-(void)onDarkModeChange;
@end
