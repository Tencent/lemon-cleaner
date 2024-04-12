//
//  LMPathBarView.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPathBarView.h"
#import "LMAppThemeHelper.h"

@implementation LMPathBarView{
    NSTrackingArea *trackingArea;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _rightAlignment = YES;
        // Initialization code here.
        m_pathArray = [[NSMutableArray alloc] init];
        
        m_attrs = [[NSMutableDictionary alloc] init];
        
        NSFont *font = [NSFont systemFontOfSize:12];
        [m_attrs setObject:font forKey:NSFontAttributeName];
        [m_attrs setObject:[NSColor colorWithHex:0x94979B] forKey:NSForegroundColorAttributeName];
        m_attrs_highlight = [m_attrs mutableCopy];
        [m_attrs_highlight setObject:[LMAppThemeHelper getTitleColor] forKey:NSForegroundColorAttributeName];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        _rightAlignment = YES;
        // Initialization code here.
        m_pathArray = [[NSMutableArray alloc] init];
        
        m_attrs = [[NSMutableDictionary alloc] init];
        
        NSFont *font = [NSFont systemFontOfSize:12];
        [m_attrs setObject:font forKey:NSFontAttributeName];
        [m_attrs setObject:[NSColor colorWithHex:0x94979B] forKey:NSForegroundColorAttributeName];
        m_attrs_highlight = [m_attrs mutableCopy];
        [m_attrs_highlight setObject:[LMAppThemeHelper getTitleColor] forKey:NSForegroundColorAttributeName];
    }
    
    return self;
}

-(void)setNormalAttrs:(NSMutableDictionary *)attrs highlistAttrs:(NSMutableDictionary *)highlightAttrs{
    m_attrs = attrs;
    m_attrs_highlight = highlightAttrs;
}

- (void)refreshXoffsetValue
{
    m_xOffset = MIN(m_curMousePoint.x - (m_curMousePoint.x / (self.bounds.size.width - 1)) * m_strWidth, 0);
    m_xOffset = (int)m_xOffset;
    if (_rightAlignment)
        m_xOffset += MAX(0, self.bounds.size.width - m_strWidth);
}

- (void)setHidden:(BOOL)flag
{
    [super setHidden:flag];
    if (!flag)
        [self refreshXoffsetValue];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if ([m_pathArray count] == 0){
        NSLog(@"LMPathBarView drawRect but m_pathArray count = 0 ");
        return;
    }
    if (self.layer){
        CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], YES);
    }
    
    // xcode15上直接draw会看到超出bounds范围的内容
    [[NSBezierPath bezierPathWithRect:self.bounds] addClip];
    
    //[self refreshXoffsetValue];
    if (self.bounds.size.width > m_strWidth && _rightAlignment) {
        m_xOffset = MAX(0, self.bounds.size.width - m_strWidth);
    }
    NSPoint point = NSMakePoint(m_xOffset, (self.bounds.size.height - [[m_pathArray objectAtIndex:0] size].height) / 2);
        
    for (NSMutableAttributedString * attrStr in m_pathArray)
    {
        [attrStr drawAtPoint:point];
        point.x += attrStr.size.width;
    }
}

- (void)setPath:(NSString *)path
{
    if ([m_path isEqualToString:path])
        return;
  
    // reset
    m_path = path;
    m_strWidth = 0;
    m_xOffset = 0;
    m_curIndex = 0;
    [m_pathArray removeAllObjects];
    
    
    NSArray * pathComponets = [m_path componentsSeparatedByString:@"/"];
    for (NSString * str in pathComponets)
    {
        if ([str isEqualToString:@""] || [str isEqualToString:@"/"])
            continue;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"/%@", str]
                                                                                    attributes:m_attrs];
        [m_pathArray addObject:attrStr];
        m_strWidth += attrStr.size.width;
    }
    [self setNeedsDisplay:YES];
}

- (void)refreshStrDisplay
{
    m_curIndex = 0;
    [self refreshXoffsetValue];
    NSPoint point = NSMakePoint(m_xOffset, 0);
    for (int i = 0; i < [m_pathArray count]; i++)
    {
        NSMutableAttributedString * curAttrStr = [m_pathArray objectAtIndex:i];
        NSRect rect;
        rect.origin = point;
        rect.size = curAttrStr.size;
        if (NSPointInRect(m_curMousePoint, rect))
        {
            m_curIndex = i;
            [curAttrStr setAttributes:m_attrs_highlight range:NSMakeRange(1, curAttrStr.length - 1)];
        }
        else
        {
            [curAttrStr setAttributes:m_attrs range:NSMakeRange(1, curAttrStr.length - 1)];
        }
        point.x += curAttrStr.size.width;
    }
    [self setNeedsDisplay:YES];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}


- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    location = [self convertPoint:location fromView:nil];
    m_curMousePoint = location;
    [self refreshStrDisplay];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    location = [self convertPoint:location fromView:nil];
    m_curMousePoint = location;
    [self refreshStrDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    for (NSMutableAttributedString * attrStr in m_pathArray)
    {
        NSMutableAttributedString * curAttrStr = attrStr;
        
        [curAttrStr setAttributes:m_attrs range:NSMakeRange(1, attrStr.length - 1)];
    }
    m_xOffset = 0;  // 鼠标移出，还原显示，不然会停留在最后鼠标的位置
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    if ([theEvent clickCount] == 2)
    {
        NSMutableString * selPath = [NSMutableString string];
        
        if(m_curIndex == 0){ //点击string 外部,显示全部路径.
            m_curIndex = m_pathArray.count - 1;
        }
        
        for (int i = 0; i <= m_curIndex; i++)
        {
            if(m_pathArray.count == 0 || m_pathArray.count <= m_curIndex){
                return;
            }
            
            NSString * str = [[m_pathArray objectAtIndex:i] string];
            [selPath appendString:str];
        }
        
        //        if (delegate)
        //            [delegate pathItemDidSelected:selPath];
        [[NSWorkspace sharedWorkspace] selectFile:selPath
                         inFileViewerRootedAtPath:[selPath stringByDeletingLastPathComponent]];
    }
}

@end
