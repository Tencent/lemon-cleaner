//
//  OwlConstant.h
//  Owl
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#ifndef OwlConstant_h
#define OwlConstant_h

/*****************************************************
 for ui
 *****************************************************/
static int OwlWindowWidth = 600;
static int OwlWindowHeight = 372;
static int OwlWindowTitleHeight = 40;

static int OwlLogCellWidth = 186;
static int OwlElementLeft = 24;

static CGFloat kOwlNPWindowWidth = 610;
static CGFloat kOwlNPWindowHeight = 510;

#ifdef __MAC_11_0
#define kOwlLeftRightMarginForTableCell 6
#else
#define kOwlLeftRightMarginForTableCell 0
#endif


#define kOwlTitleViewHeight 28 // 标题高度
#define kOwlTopViewHeight 40 // 顶部高度
#define kOwlBottomViewHeight 56 // 底部高度

#define kOwlHorizontalTextSpacing 6 // 文本水平间距

typedef NS_ENUM(NSInteger, OwlProtectType){
    OwlProtectVedio = 0,
    OwlProtectAudio = 1,
    OwlProtectVedioAndAudio = 2, // 废弃，不可能同时出现
    OwlProtectSystemAudio = 3,
    OwlProtectScreen = 4,
    OwlProtectAutomation = 5,
    
    OwlProtectScreenshotForReporter = 40,
    OwlProtectScreenRecordingForReporter = 41,
};

typedef NS_ENUM(NSUInteger, Owl2LogUserAction) {
    Owl2LogUserActionNone = 0, // 无操作
    Owl2LogUserActionClose, // 用户关闭
    Owl2LogUserActionContent, // 用户点击了内容
    Owl2LogUserActionDefaultAllow , // 无操作,20s后默认允许
    Owl2LogUserActionAllow, // 本次允许
    Owl2LogUserActionAlwaysAllowed, // 永久允许
    Owl2LogUserActionPrevent, // 阻止
};

typedef NS_ENUM(NSUInteger, Owl2LogThirdAppAction) {
    Owl2LogThirdAppActionNone = 0,
    Owl2LogThirdAppActionStart = 1, // 开始
    Owl2LogThirdAppActionStop = 2, // 结束
    
    Owl2LogThirdAppActionStartForScreenshot = 10, // 开始截屏
    Owl2LogThirdAppActionStartForScreenRecording = 11, // 开始录屏
    Owl2LogThirdAppActionStopForScreenshot = 20, // 结束截屏
    Owl2LogThirdAppActionStopForScreenRecording = 21, // 结束录屏
};

typedef NS_ENUM(NSUInteger, Owl2LogHardware) {
    Owl2LogHardwareVedio = OwlProtectVedio,
    Owl2LogHardwareAudio = OwlProtectAudio,
    Owl2LogHardwareSystemAudio = OwlProtectSystemAudio,
    Owl2LogHardwareScreen = OwlProtectScreen,
    Owl2LogHardwareAutomation = OwlProtectAutomation,
    
    Owl2LogHardwareScreenshotForReporter = OwlProtectScreenshotForReporter,
    Owl2LogHardwareScreenRecordingForReporter = OwlProtectScreenRecordingForReporter,
};

/*****************************************************
 db or dictionary key string
 *****************************************************/
#define OwlVersionTable                @"version_info"
#define OwlAppWhiteTable               @"app_white"
#define OwlProcLogTable                @"proc_log"
#define OwlProcLogTableNew             @"proc_log_New"
#define OwlProBlockTable               @"proc_block"
#define OwlProcProfileTable            @"proc_profile"

#define OwlAppName                     @"appName"
#define OwlExecutableName              @"executableName"
#define OwlBubblePath                  @"bubblePath"
#define OwlIdentifier                  @"identifier"
#define OwlAppIcon                     @"appIcon"
#define OwlAppleApp                    @"appleApp"
#define OwlAppIconPath                 @"appIconPath" // 数据库里用的

#define OwlWatchCamera                 @"watchCamera"
#define OwlWatchAudio                  @"watchAudio"
#define OwlWatchSpeaker                @"watchSpeaker"
#define OwlWatchScreen                 @"watchScreen"
#define OwlWatchAutomatic              @"watchAutomatic"

#define OwlUUID                        @"uuid"
#define OwlTime                        @"time"
#define OwlUserAction                  @"userAction"
#define OwlAppAction                   @"appAction"
#define OwlHardware                    @"hardware"

#define Owl2AppItemKey                 @"Owl2AppItemKey"
#define Owl2ParentAppItemKey           @"Owl2ParentAppItemKey"

/*****************************************************
 the constant string of main app process communication
 helper process(the parameter using NSDictionary)
 *****************************************************/
#define OWLMAINCLIENTNAME               @"owl_main_client_name"
#define OWLDAEMONNAME                   @"owl_daemon_name"
#define COM_TENCENT_OWLHELPER           @"com.tencent.LemonOwlHelper"

//common key of the parameter's NSDictionary
#define FUNCTIONKEY                     @"function_key"
#define PARAMETERKEY                    @"parameter_key"

//function key
#define APPLAUNCHED                     @"app_launched"
#define APPTERMINATE                    @"app_terminate"

//main app --> helper
#define CameraBecomeActive              @"camera_become_active"
#define CameraBecomeInActive            @"camera_become_inactive"
#define FindWitchProcessUseCamera       @"find_witch_process_use_camera"
#define PeerCameraConnectionId          @"peer_camera_connection_id"

//helper --> main app
#define FindWitchProcessUseCameraReply  @"find_witch_process_use_camera_replay"


#define AppleIBookIdentifier @"com.apple.iBooksX"

#define QMRetStrIfEmpty(obj) ((obj) ? (obj) : @"")

#endif /* OwlConstant_h */
