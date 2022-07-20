//
//  LMProcessPortRowView.h
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMBorderButton.h>
#import "LMProcessPortModel.h"

@interface LMProcessPortRowView : NSTableCellView
@property (weak) IBOutlet NSTextField *appName;
@property (weak) IBOutlet NSImageView *appIcon;
@property (weak) IBOutlet NSTextField *protocol;
@property (weak) IBOutlet NSTextField *socketType;
@property (weak) IBOutlet NSTextField *srcIpPort;
@property (weak) IBOutlet NSTextField *destIpPort;
@property (weak) IBOutlet NSTextField *connectState;
@property (weak) IBOutlet NSButton *btnKillProcess;
@property (nonatomic, copy) void(^actionHandler)(LMProcessPortModel *portModel);
@property (nonatomic, strong) LMProcessPortModel *portModel;
@end
