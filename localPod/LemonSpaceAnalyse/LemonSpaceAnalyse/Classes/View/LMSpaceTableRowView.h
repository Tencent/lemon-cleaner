//
//  LMSpaceTableRowView.h
//  NSTableViewDemo
//
//  
//  Copyright © 2017年 Karthus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMBorderButton.h>
@class LMSpaceTableRowView;

@interface LMSpaceTableRowView : NSTableRowView

@property(nonatomic, strong) NSString *fullPath;

- (void)setIcon:(NSImage *)image isHidden:(BOOL)isHidden;
- (void)setNameStr:(NSString *)text;
- (void)setSizeStr:(long long)text;
- (void)setCountStr:(NSUInteger)num;
- (void)setType:(NSString *)type;
- (void)countStrIsHidden:(BOOL)result;
- (void)nextButtonIsHidden:(BOOL)result;
- (void)initUI;
@end
