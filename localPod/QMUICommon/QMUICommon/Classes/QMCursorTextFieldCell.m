//
//  QMCursorTextFieldCell.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMCursorTextFieldCell.h"

@implementation QMCursorTextFieldCell
@synthesize cursorColor;

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    NSText *textView = [super setUpFieldEditorAttributes:textObj];
    if (cursorColor && [textView respondsToSelector:@selector(setInsertionPointColor:)])
    {
        [(NSTextView*)textView setInsertionPointColor:cursorColor];
    }
    return textView;
}

@end
