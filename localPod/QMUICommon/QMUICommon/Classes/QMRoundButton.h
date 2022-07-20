//
//  QMRoundButton.h
//  QMApplication
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseButton.h>

@interface QMRoundButton : QMBaseButton

@property (nonatomic, assign) CGFloat borderWidth;

@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, strong) NSColor *titleColor;

@property (nonatomic, strong) NSColor *borderColorHL;
@property (nonatomic, strong) NSColor *titleColorHL;

@property (nonatomic, strong) NSColor *borderColorDisable;
@property (nonatomic, strong) NSColor *titleColorDisable;

@end

@interface QMMainRoundButton : QMRoundButton
{
    NSColor *borderInnerColor;
}

@property (nonatomic,assign) BOOL warning;

@end
