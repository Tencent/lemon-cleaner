//
//  HardwareTableRowView.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HardwareTableRowView : NSTableRowView
{
    NSColor * m_selectedColor;
    CGFloat _textWidth;
}

- (void)moveExpandButtonToFront;

@end
