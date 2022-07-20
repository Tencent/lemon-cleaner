//
//  LMPhotoCollectionViewHeader.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>

@interface LMPhotoCollectionViewHeader : NSView
typedef void(^CheckButtonEvent)(void);

@property (weak) IBOutlet NSTextField *textTitle;
@property (weak) NSButton *btnSelect;//需求变更，已弃用
//@property (weak) NSButton *checkBtn;

@property (weak) IBOutlet LMCheckboxButton *checkBtn;

@property (nonatomic, copy) void(^selectActionHandler)(void);
@property CheckButtonEvent checkButtonEvent;
@end
