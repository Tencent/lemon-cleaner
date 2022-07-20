//
//  file: consts.h
//  project: OverSight (shared)
//  description: #defines and what not
//
//  created by Patrick Wardle
//  copyright (c) 2020 Objective-See. All rights reserved.
//

#ifndef consts_h
#define consts_h

//start at login
#define PREF_AUTOSTART_MODE @"startAtLogin"

//disable 'inactive' alerts
#define PREF_DISABLE_INACTIVE @"disableInactive"

//pref
// execute action
#define PREF_EXECUTE_ACTION @"executeAction"

//pref
// execution path
#define PREF_EXECUTE_PATH @"executePath"

//pref
// execute action
#define PREF_EXECUTE_ACTION_ARGS @"executeActionArgs"

//cs consts
// from: cs_blobs.h
#define CS_VALID 0x00000001
#define CS_ADHOC 0x0000002
#define CS_RUNTIME 0x00010000

//patreon url
#define PATREON_URL @"https://www.patreon.com/join/objective_see"

//sentry crash reporting URL
#define SENTRY_DSN @"https://729ac84fd0014ea1aa48ca46386546b6@o130950.ingest.sentry.io/5745525"

//app name
#define PRODUCT_NAME @"OverSight"

//bundle ID
#define BUNDLE_ID "com.objective-see.oversight"

//main app bundle id
#define MAIN_APP_ID @"com.objective-see.oversight"

//helper (login item) ID
#define HELPER_ID @"com.objective-see.oversight.helper"

//installer (app) ID
#define INSTALLER_ID @"com.objective-see.oversight.installer"

//installer (helper) ID
#define CONFIG_HELPER_ID @"com.objective-see.oversight.uninstallHelper"

//signing auth
#define SIGNING_AUTH @"Developer ID Application: Objective-See, LLC (VBG97UB4TA)"

//product version url
#define PRODUCT_VERSIONS_URL @"https://objective-see.com/products.json"

//product url
#define PRODUCT_URL @"https://objective-see.com/products/oversight.html"

//error(s) url
#define ERRORS_URL @"https://objective-see.com/errors.html"

//close category
#define CATEGORY_CLOSE @"close"

//action category
#define CATEGORY_ACTION @"action"

//support us button tag
#define BUTTON_SUPPORT_US 100

//more info button tag
#define BUTTON_MORE_INFO 101

//install cmd
#define CMD_INSTALL @"-install"

//uninstall cmd
#define CMD_UNINSTALL @"-uninstall"

//install cmd
#define CMD_UPGRADE @"-upgrade"

//flag to uninstall
#define ACTION_UNINSTALL_FLAG 0

//flag to install
#define ACTION_INSTALL_FLAG 1

//flag for partial uninstall
// leave preferences file, etc.
#define UNINSTALL_PARTIAL 0

//flag for full uninstall
#define UNINSTALL_FULL 1

//add rule, block
#define BUTTON_BLOCK 0

//add rule, allow
#define BUTTON_ALLOW 1

//prefs
// disabled status
#define PREF_IS_DISABLED @"disabled"

//prefs
// passive mode
#define PREF_PASSIVE_MODE @"passiveMode"

//prefs
// icon mode
#define PREF_NO_ICON_MODE @"noIconMode"

//prefs
// update mode
#define PREF_NO_UPDATE_MODE @"noupdateMode"

//allowed items (key)
#define PREFS_ALLOWED_ITEMS @"allowedItems"

//general error URL
#define FATAL_ERROR_URL @"https://objective-see.com/errors.html"

//key for exit code
#define EXIT_CODE @"exitCode"

//rules changed
#define RULES_CHANGED @"com.objective-see.oversight.rulesChanged"

//first time flag
#define INITIAL_LAUNCH @"-initialLaunch"

/* INSTALLER */

//menu: 'about'
#define MENU_ITEM_ABOUT 0

//menu: 'quit'
#define MENU_ITEM_QUIT 1

//app name
#define APP_NAME @"OverSight.app"

//apps folder
#define APPS_FOLDER @"/Applications"

//frame shift
// for status msg to avoid activity indicator
#define FRAME_SHIFT 45

//flag to close
#define ACTION_CLOSE_FLAG -1

//cmdline flag to uninstall
#define ACTION_UNINSTALL @"-uninstall"

//flag to uninstall
#define ACTION_UNINSTALL_FLAG 0

//cmdline flag to uninstall
#define ACTION_INSTALL @"-install"

//flag to install
#define ACTION_INSTALL_FLAG 1

//button title: upgrade
#define ACTION_UPGRADE @"Upgrade"

//button title: close
#define ACTION_CLOSE @"Close"

//button title: next
#define ACTION_NEXT @"Next »"

//show friends
#define ACTION_SHOW_SUPPORT 4

//support us
#define ACTION_SUPPORT 5

//path to xattr
#define XATTR @"/usr/bin/xattr"

//path to open
#define OPEN @"/usr/bin/open"

//path to launchctl
#define LAUNCHCTL @"/bin/launchctl"

//path to defaults
#define DEFAULTS @"/usr/bin/defaults"

//path to kill all
#define KILL_ALL @"/usr/bin/killall"

//path to facetime
#define FACE_TIME @"/System/Applications/FaceTime.app/Contents/MacOS/FaceTime"

//path to avconferenced
#define AV_CONFERENCED @"/usr/libexec/avconferenced"

//path to Siri
#define SIRI_APP @"/System/Applications/Siri.app/Contents/MacOS/Siri"
#define SIRI_SYS @"/System/Library/CoreServices/Siri.app/Contents/MacOS/Siri"

//path to corespeechd
#define CORE_SPEECHD @"/System/Library/PrivateFrameworks/CoreSpeech.framework/corespeechd"

//rules window
#define WINDOW_RULES 0

//preferences window
#define WINDOW_PREFERENCES 1

//key for stdout output
#define STDOUT @"stdOutput"

//key for stderr output
#define STDERR @"stdError"

//key for exit code
#define EXIT_CODE @"exitCode"

//event keys
#define EVENT_DEVICE @"device"
#define EVENT_TIMESTAMP @"timeStamp"
#define EVENT_DEVICE_STATUS @"status"
#define EVENT_PROCESS_ID @"processID"
#define EVENT_PROCESS_PATH @"processPath"

#define NOTIFICATION_ERROR -1
#define NOTIFICATION_SPURIOUS 0
#define NOTIFICATION_SKIPPED 1
#define NOTIFICATION_DELIVER 2

//av devices
typedef enum {Device_Camera, Device_Microphone} AVDevice;

//log levels
typedef enum {Log_Level_Default, Log_Level_Info, Log_Level_Debug} LogLevels;

#endif
