//
//  LMSpacePathView.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpacePathView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMThemeManager.h"

@interface LMSpacePathView ()

@property(nonatomic, strong) NSString *m_path;
@property(nonatomic, strong) NSMutableArray *m_pathArray;
@property(nonatomic, strong) NSMutableDictionary *m_attrs;
@property(nonatomic, strong) NSMutableDictionary *m_attrs_highlight;

@property(nonatomic, assign) NSPoint m_curMousePoint;
@property(nonatomic, assign) float m_xOffset;
@property(nonatomic, assign) float m_strWidth;
@property(nonatomic, assign) float m_drawOffset;

@property(nonatomic, assign) NSInteger m_curIndex;
@property(nonatomic, assign) BOOL m_rightAlignment;
@property(nonatomic, strong) NSTrackingArea *trackingArea;

@end

@implementation LMSpacePathView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _rightAlignment = YES;
        // Initialization code here.
        self.m_pathArray = [[NSMutableArray alloc] init];
        

        self.m_attrs_highlight = [self.m_attrs mutableCopy];
//        [self.m_attrs_highlight setObject:[LMAppThemeHelper getTitleColor] forKey:NSForegroundColorAttributeName];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        _rightAlignment = YES;
        // Initialization code here.
        self.m_pathArray = [[NSMutableArray alloc] init];
        

        self.m_attrs_highlight = [self.m_attrs mutableCopy];
//        [self.m_attrs_highlight setObject:[LMAppThemeHelper getTitleColor] forKey:NSForegroundColorAttributeName];
    }
    
    return self;
}

- (void)setNormalAttrs:(NSMutableDictionary *)attrs highlistAttrs:(NSMutableDictionary *)highlightAttrs {
    self.m_attrs = attrs;
    self.m_attrs_highlight = highlightAttrs;
}

- (void)refreshXoffsetValue {
    self.m_xOffset = MIN(self.m_curMousePoint.x - (self.m_curMousePoint.x / (self.bounds.size.width - 1)) * self.m_strWidth, 0);
    self.m_xOffset = (int)self.m_xOffset;
    if (_rightAlignment)
        self.m_xOffset += MAX(0, self.bounds.size.width - self.m_strWidth);
}

- (void)setHidden:(BOOL)flag {
    [super setHidden:flag];
    if (!flag)
        [self refreshXoffsetValue];
}

- (void)drawRect:(NSRect)dirtyRect {
    if ([self.m_pathArray count] == 0){
        NSLog(@"LMPathBarView drawRect but self.m_pathArray count = 0 ");
        return;
    }
    if (self.layer){
        CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], YES);
    }
    //[self refreshXoffsetValue];
    if (self.bounds.size.width > self.m_strWidth && _rightAlignment) {
        self.m_xOffset = MAX(0, self.bounds.size.width - self.m_strWidth);
    }
    NSPoint point = NSMakePoint(self.m_xOffset, (self.bounds.size.height - [[self.m_pathArray objectAtIndex:0] size].height) / 2);
    
    
    for (NSMutableAttributedString * attrStr in self.m_pathArray)
    {
        //Note:本类由LMPathBarView改造而得，之前代码在每个string后面会新增“/”符号，而“/”不需要变色，故变色长度为attrStr.length-1。
        //Note:现将增加“/”代码删除，故变色长度为attrStr.length。
        [attrStr setAttributes:self.m_attrs range:NSMakeRange(0, attrStr.length)];
        [attrStr drawAtPoint:point];
        
        
        point.x += attrStr.size.width;
    }
}

- (void)setPath:(NSString *)path {
//    if ([self.m_path isEqualToString:path])
//        return;
  
    // reset
    self.m_path = path;
    self.m_strWidth = 0;
    self.m_xOffset = 0;
    self.m_curIndex = 0;
    [self.m_pathArray removeAllObjects];
    
//    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", self.m_path] attributes:self.m_attrs];
//    [self.m_pathArray addObject:attrStr];
//    self.m_strWidth = attrStr.size.width;
    
    NSArray * pathComponets = [self.m_path componentsSeparatedByString:@"/"];
    for (NSString * str in pathComponets)
    {
        if ([str isEqualToString:@""] || [str isEqualToString:@"/"])
            continue;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", str]
                                                                                    attributes:self.m_attrs];
        [self.m_pathArray addObject:attrStr];
        self.m_strWidth += attrStr.size.width;
    }
    [self setNeedsDisplay:YES];
}

- (void)refreshStrDisplay {
    self.m_curIndex = 0;
    [self refreshXoffsetValue];
    NSPoint point = NSMakePoint(self.m_xOffset, 0);
    for (int i = 0; i < [self.m_pathArray count]; i++)
    {
        NSMutableAttributedString * curAttrStr = [self.m_pathArray objectAtIndex:i];
        NSRect rect;
        rect.origin = point;
        rect.size = curAttrStr.size;
        if (NSPointInRect(self.m_curMousePoint, rect))
        {
            self.m_curIndex = i;
            //Note:本类由LMPathBarView改造而得，之前代码在每个string后面会新增“/”符号，而“/”不需要变色，故变色长度为attrStr.length-1。
            //Note:现将增加“/”代码删除，故变色长度为attrStr.length。
            [curAttrStr setAttributes:self.m_attrs range:NSMakeRange(0, curAttrStr.length)];
        }
        else
        {
            //Note:本类由LMPathBarView改造而得，之前代码在每个string后面会新增“/”符号，而“/”不需要变色，故变色长度为attrStr.length-1。
            //Note:现将增加“/”代码删除，故变色长度为attrStr.length。
            [curAttrStr setAttributes:self.m_attrs range:NSMakeRange(0, curAttrStr.length)];
        }
        point.x += curAttrStr.size.width;
    }
    [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:self.trackingArea]) {
        [self addTrackingArea:self.trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSPoint location = [theEvent locationInWindow];
    location = [self convertPoint:location fromView:nil];
    self.m_curMousePoint = location;
    [self refreshStrDisplay];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    NSPoint location = [theEvent locationInWindow];
    location = [self convertPoint:location fromView:nil];
    self.m_curMousePoint = location;
    [self refreshStrDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent {
    for (NSMutableAttributedString * attrStr in self.m_pathArray)
    {
        NSMutableAttributedString * curAttrStr = attrStr;
        
        //Note:本类由LMPathBarView改造而得，之前代码在每个string后面会新增“/”符号，而“/”不需要变色，故变色长度为attrStr.length-1。
        //Note:现将增加“/”代码删除，故变色长度为attrStr.length。
        [curAttrStr setAttributes:self.m_attrs range:NSMakeRange(0, attrStr.length)];
    }
    self.m_xOffset = 0;
    self.m_curIndex = 0;
    [self setNeedsDisplay:YES];
}

- (NSMutableDictionary *)m_attrs {
    if (!_m_attrs) {
        _m_attrs = [[NSMutableDictionary alloc] init];
        NSFont *font = [NSFont systemFontOfSize:12];
        [_m_attrs setObject:font forKey:NSFontAttributeName];
    }
    if ([LMThemeManager cureentTheme] == YES) {
        [_m_attrs setObject:[NSColor colorWithHex:0xFFFFFF] forKey:NSForegroundColorAttributeName];
    }else{
        [_m_attrs setObject:[NSColor colorWithHex:0x515151] forKey:NSForegroundColorAttributeName];
    }
    return _m_attrs;
}

@end
