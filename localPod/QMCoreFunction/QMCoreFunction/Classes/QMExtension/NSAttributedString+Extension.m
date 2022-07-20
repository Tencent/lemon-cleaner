//
//  NSAttributedString+Extension.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "NSAttributedString+Extension.h"
#import "NSColor+Extension.h"

@implementation NSAttributedString(StringSize)

- (NSSize)sizeForWidth:(float)width height:(float)height
{
    NSSize retSize = NSZeroSize;
    if (self.length > 0)
    {
        NSSize size = NSMakeSize(width, height);
        NSTextContainer * textContrainer = [[NSTextContainer alloc] initWithContainerSize:size];
        NSTextStorage * textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
        NSLayoutManager * layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContrainer];
        [textStorage addLayoutManager:layoutManager];
        [layoutManager setHyphenationFactor:0.0];
        [layoutManager glyphRangeForTextContainer:textContrainer];
        
        retSize = [layoutManager usedRectForTextContainer:textContrainer].size;
        
        NSSize extraLineSize = [layoutManager extraLineFragmentRect].size;
        if (extraLineSize.height > 0)
            retSize.height -= extraLineSize.height;
    }
    return retSize;
}

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithHex:0x057cff] range:NSMakeRange(0, inString.length)];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    
    [attrString endEditing];
    
    return attrString;
}


@end
