//
//  PreferenceViewController.h
//  Lemon
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseViewController.h>
#define IS_ENABLE_TRASH_WATCH @"enable_trash_watch"

@class PreferenceWindowController;

@interface PreferenceViewController : QMBaseViewController

@property (weak, nonatomic) PreferenceWindowController* myWC;


-(id)initWithPreferenceWindowController:(PreferenceWindowController *)wdControler;

- (instancetype)init;
#define STATUS_TYPE_LOGO (1 << 0)
#define STATUS_TYPE_MEM  (1 << 1)
#define STATUS_TYPE_DISK (1 << 2)
#define STATUS_TYPE_TEP  (1 << 3)
#define STATUS_TYPE_FAN  (1 << 4)
#define STATUS_TYPE_NET  (1 << 5)
#define STATUS_TYPE_CPU  (1 << 6)
#define STATUS_TYPE_GPU  (1 << 7)
#define STATUS_TYPE_GLOBAL (0x80000000)
#define STATUS_TYPE_BOOTSHOW (0x40000000)
#define kLemonStatusOptionsChanged @"kLemonStatusOptionsChanged"
#define kStatusChangedNotification @"StatusChangedNotification"

//sharepreference key
#define APPEARANCE_IS_DARK_MODE @"appearance_dark_mode"

@property(nonatomic) NSInteger myStatusType;
@property(nonatomic) NSMutableDictionary* myStatusControls;
@property(nonatomic) NSMutableDictionary* myRadioControls;
@end
