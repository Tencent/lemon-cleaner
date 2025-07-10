//
//  OwlTableRowView.m
//  Lemon
//
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlTableRowView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>
@implementation OwlTableRowView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _selectedColor =  [LMAppThemeHelper getTableViewRowSelectedColor];
    }
    return self;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [_selectedColor set];
    [path fill];
}

@end

extern CGFloat const OwlWLCellFoldHeight;
extern CGFloat const OwlWLCellExpandHeight;

@interface OwlWLTableRowView ()
@property (nonatomic, strong) NSView *expandBgView;
@end

@implementation OwlWLTableRowView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.expandBgView = [[NSView alloc] initWithFrame:NSZeroRect];
        self.expandBgView.wantsLayer = YES;
        BOOL isDarkMode = [LMAppThemeHelper isDarkMode];
        self.expandBgView.layer.backgroundColor = [NSColor colorWithHex:(isDarkMode?0x9A9A9A:0xF3F3F3) alpha:(isDarkMode?0.2:1)].CGColor;
        self.expandBgView.hidden = YES;
        [self addSubview:self.expandBgView];
    }
    return self;
}

- (void)layout {
    [super layout];
    self.expandBgView.frame = NSMakeRect(0, OwlWLCellFoldHeight, self.frame.size.width, OwlWLCellExpandHeight);
}

- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    BOOL isDarkMode = [LMAppThemeHelper isDarkMode];
    self.expandBgView.layer.backgroundColor = [NSColor colorWithHex:(isDarkMode?0x9A9A9A:0xF3F3F3) alpha:(isDarkMode?0.2:1)].CGColor;
}

- (void)setIsExpand:(BOOL)isExpand {
    self.expandBgView.hidden = !isExpand;
    _isExpand = isExpand;
}

@end
