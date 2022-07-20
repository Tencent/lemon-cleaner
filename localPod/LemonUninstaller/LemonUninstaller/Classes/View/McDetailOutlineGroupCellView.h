//
//  McDetailOutlineGroupCellView.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface McDetailOutlineGroupCellView : NSTableCellView
@property (weak) IBOutlet NSTextField *groupName;
@property (weak) IBOutlet LMCheckboxButton *checkButton;

@end

NS_ASSUME_NONNULL_END
