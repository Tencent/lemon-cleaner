//
//  QMTableRowView.h
//  QMCleaner
//

//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMResultTableRowView : NSTableRowView
{
    NSColor * m_selectedColor;
    CGFloat _textWidth;
}

- (void)moveExpandButtonToFront;

@end
