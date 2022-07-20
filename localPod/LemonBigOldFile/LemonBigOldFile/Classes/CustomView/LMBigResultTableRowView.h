//
//  LMBigResultTableRowView.h
//  QMCleaner
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol RowViewDelegate <NSObject>
-(BOOL) isPreviewing;
@end

@interface LMBigResultTableRowView : NSTableRowView
{
    NSColor * m_selectedColor;
    CGFloat _textWidth;
    BOOL _previewing;
}

@property(nonatomic, weak) id<RowViewDelegate> rowViewDelegate;

@end
