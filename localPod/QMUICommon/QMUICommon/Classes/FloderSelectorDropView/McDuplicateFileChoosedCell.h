//
//  McDuplicateFileChoosedCell.h
//  McCleaner
//
//  Created by developer on 12-8-8.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface McDuplicateFileChoosedCell : NSView
{
    @private
    NSColor *bgColor;
    NSColor *choosedColor;
    NSDictionary *textFontAttribute;
    BOOL _highlight;
}
@property (nonatomic,assign) NSInteger allCount;
@property (nonatomic,assign) NSInteger choosedCount;
@property (nonatomic, retain) NSString * fileSizeStr;

- (void)showHighlight:(BOOL)highlight;

- (CGFloat)width;

@end
