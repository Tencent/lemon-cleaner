//
//  McDuplicateFileChoosedCell.m
//  McCleaner
//
//  Created by developer on 12-8-8.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McDuplicateFileChoosedCell.h"

@implementation McDuplicateFileChoosedCell

- (void)awakeFromNib
{
    bgColor = [NSColor colorWithDeviceRed:12/255.0
                                    green:14/255.0
                                     blue:16/255.0
                                    alpha:1.0];
    
    choosedColor = [NSColor colorWithDeviceRed:66/255.0
                                         green:72/255.0
                                          blue:84/255.0 
                                         alpha:1.0];
    
    NSMutableParagraphStyle *_pStyle = [[NSMutableParagraphStyle alloc] init];
    _pStyle.alignment = NSTextAlignmentCenter;
    
    NSFont *font = [NSFont safeFontWithName:@"Hiragino Sans GB" size:12];
    textFontAttribute = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSColor colorWithHex:0x616c72],NSForegroundColorAttributeName,
                         font,NSFontAttributeName,
                         _pStyle,NSParagraphStyleAttributeName,
                         nil];
}


- (CGFloat)width
{
    NSString * chooseStr = [NSString stringWithFormat:@"已选%ld项",_choosedCount];
    NSString * allStr = [NSString stringWithFormat:@"%ld",_allCount];
    
    if (_choosedCount > 0)
        return [[NSString stringWithFormat:@"%@%@", chooseStr, allStr] sizeWithAttributes:textFontAttribute].width + 29;
    else
        return [[NSString stringWithFormat:@"%@%@", _fileSizeStr, allStr] sizeWithAttributes:textFontAttribute].width + 25;
}

- (void)setAllCount:(NSInteger)allCount
{
    if (_allCount == allCount)
        return;
    _allCount = allCount;
    [self setNeedsDisplay:YES];
}

- (void)setChoosedCount:(NSInteger)choosedCount
{
    if (_choosedCount == choosedCount)
        return;
    _choosedCount = choosedCount;
    [self setNeedsDisplay:YES];
}


- (void)showHighlight:(BOOL)highlight
{
    if (_highlight == highlight)
        return;
    _highlight = highlight;
    [self setNeedsDisplay:YES];
}

- (NSRect)_drawBorderText:(NSString *)text color:(NSColor *)color offset:(CGFloat)offset
{
    // display string
    NSString *displayStr = text;
    NSSize textSize = [displayStr sizeWithAttributes:textFontAttribute];
    
    NSRect textRect = NSZeroRect;
    textRect.size.height = (int)textSize.height + 2;
    textRect.size.width = (int)textSize.width + 11;
    textRect.origin.x = self.bounds.size.width - offset - textRect.size.width - 2;
    textRect.origin.y = (int)((self.bounds.size.height - textRect.size.height) * 0.5);
    
    NSRect bgRect = NSInsetRect(textRect, 0.5, 0.5);
    bgRect.origin.y += 1;
    NSBezierPath * bgPath = [NSBezierPath bezierPathWithRoundedRect:bgRect
                                                            xRadius:(int)(bgRect.size.height * 0.5)
                                                            yRadius:(int)(bgRect.size.height * 0.5)];
    [color set];
    [bgPath stroke];
    
    //draw all string
    NSMutableDictionary * dict = [textFontAttribute mutableCopy];
    [dict setObject:color forKey:NSForegroundColorAttributeName];
//    textRect.origin.y -= 1;
    [displayStr drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin attributes:dict];
    return textRect;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //[super drawWithFrame:cellFrame inView:controlView];
    if (_allCount == 0)
    {
        return;
    }
    
    NSColor * color = (_highlight ? [NSColor colorWithHex:0x0091ff] : [NSColor colorWithHex:0x616c72]);
    
    NSString * chooseStr = [NSString stringWithFormat:@"已选%ld项",_choosedCount];
    NSString * allStr = [NSString stringWithFormat:@"%ld",_allCount];
    
    NSRect textRect = NSZeroRect;
    if (_choosedCount > 0)
    {
        textRect = [self _drawBorderText:chooseStr
                                   color:color
                                  offset:0];
        [self _drawBorderText:allStr
                        color:color
                       offset:textRect.size.width + 6];
    }
    else
    {
        
        textRect = [self _drawBorderText:allStr
                                   color:color
                                  offset:0];
        NSMutableDictionary * dict = [textFontAttribute mutableCopy];
        [dict setObject:color forKey:NSForegroundColorAttributeName];
        textRect.size = [_fileSizeStr sizeWithAttributes:dict];
        textRect.origin.x -= textRect.size.width + 2;
        textRect.origin.y = (int)((self.bounds.size.height - textRect.size.height) * 0.5) + 1;
        [_fileSizeStr drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin attributes:dict];
    }
}


@end
