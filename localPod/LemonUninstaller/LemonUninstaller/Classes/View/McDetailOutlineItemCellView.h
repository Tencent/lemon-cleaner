//
//  McDetailOutlineItemCellView.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/LMPathBarView.h>

NS_ASSUME_NONNULL_BEGIN

@interface McDetailOutlineItemCellView : NSTableCellView
@property (weak) IBOutlet LMCheckboxButton *checkButton;
@property (weak) IBOutlet NSImageView     *icon;
@property (weak) IBOutlet NSTextField     *textFileName;
@property (weak) IBOutlet NSTextField     *textVersion;
@property (weak) IBOutlet NSTextField     *textSize;
@property (weak) IBOutlet LMPathBarView   *pathBarView;
@property (weak) IBOutlet NSButton        *btnShowFinder;
@property (nonatomic, strong) NSString    *path;

@property (nonatomic, assign) BOOL        needShowPath;


@end

NS_ASSUME_NONNULL_END
