//
//  ParagraphTextFieldCell.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ParagraphTextFieldCell.h"


@interface ESPasteView : NSTextView <NSTextViewDelegate>

@end

@implementation ESPasteView
- (void)paste:(id)sender{
    [super pasteAsPlainText:sender]; // rich text -> plain text
}

@end



@implementation ParagraphTextFieldCell

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj{
    NSLog(@"setUpFieldEditorAttributes ...");
    NSText *text = [super setUpFieldEditorAttributes:textObj];
    if([text isKindOfClass:NSTextView.class]){
        //更改光标颜色.
//        [(NSTextView*)text setInsertionPointColor:[NSColor greenColor]];
        
        NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
        CGFloat spacing = 50.0;
        textParagraph.alignment = NSTextAlignmentCenter;
        textParagraph.lineBreakMode = NSLineBreakByCharWrapping;
        [textParagraph setLineSpacing:50.0];
        [textParagraph setMinimumLineHeight:spacing];
        [textParagraph setMaximumLineHeight:spacing];
        ((NSTextView*)text).defaultParagraphStyle = textParagraph;
    }
    return text;
}

- (NSTextView *)fieldEditorForView:(NSView *)controlView{
    return [[ESPasteView alloc]init];
}
@end



