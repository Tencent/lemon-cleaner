//
//  LMPathBarView.h
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMPathBarView : NSView
{
    NSString * m_path;
    NSMutableArray * m_pathArray;
    NSMutableDictionary * m_attrs;
    NSMutableDictionary * m_attrs_highlight;
    
    NSPoint m_curMousePoint;
    
    float m_xOffset;
    float m_strWidth;
    float m_drawOffset;
    
    NSInteger m_curIndex;
    BOOL m_rightAlignment;
}

@property (nonatomic, retain) NSString * path;
@property (nonatomic, assign) BOOL rightAlignment;


-(void)setNormalAttrs:(NSMutableDictionary *)attrs highlistAttrs:(NSMutableDictionary *)highlightAttrs;

@end
