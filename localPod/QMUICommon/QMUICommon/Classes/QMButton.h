//
//  QMStateButton.h
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    QMMixedState = NSMixedState,
    QMOnState = NSOnState,
    QMOffState = NSOffState,
    QMMouseOver = 2,
    QMMouseDown = 3,
} QMButtonState;

@interface QMButton : NSButton
@property (nonatomic, assign) BOOL handCursor;
@property (nonatomic, assign) BOOL borderType;
@property (nonatomic, assign) BOOL pressState;
@property (nonatomic, retain) NSColor * borderButtonColor;
@property (nonatomic, retain) NSColor * mouseEnterColor;
@property (nonatomic, retain) NSColor * mouseExitColor;

- (NSInteger)state;
- (void)setState:(NSInteger)value;

- (void)setImage:(NSImage *)image state:(QMButtonState)state;

@end

@interface QMBlueButton : QMButton
@property (nonatomic,assign) BOOL selected;
@end
