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
    
    BOOL mDarkModeOn;
}

@property (nonatomic, assign) float upSpeed;
@property (nonatomic, assign) float downSpeed;
@property (nonatomic, assign) int statusNum;

#define STATUS_TYPE_LOGO 1
#define STATUS_TYPE_MEM  2
#define STATUS_TYPE_DISK 4
#define STATUS_TYPE_TEP  8
#define STATUS_TYPE_FAN  16
#define STATUS_TYPE_NET  32
#define STATUS_TYPE_CPU  64
-(void)setStatusType:(long)type;
-(void)onDarkModeChange;
@end
