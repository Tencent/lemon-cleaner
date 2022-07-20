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
static int OwlElementLeft = 20;

typedef NS_ENUM(NSInteger, OwlProtectType){
    OwlProtectVedio = 0,
    OwlProtectAudio = 1,
    OwlProtectVedioAndAudio = 2
};

/*****************************************************
 db or dictionary key string
 *****************************************************/
#define OwlAppWhiteTable               @"app_white"
#define OwlProcLogTable                @"proc_log"
#define OwlProBlockTable               @"proc_block"
#define OwlProcProfileTable            @"proc_profile"

#define OwlAppName                     @"appName"
#define OwlExecutableName              @"executableName"
#define OwlBubblePath                  @"bubblePath"
#define OwlIdentifier                  @"identifier"
#define OwlAppIcon                     @"appIcon"
#define OwlAppleApp                    @"appleApp"

#define OwlWatchCamera                 @"watchCamera"
#define OwlWatchAudio                  @"watchAudio"

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

#endif /* OwlConstant_h */
