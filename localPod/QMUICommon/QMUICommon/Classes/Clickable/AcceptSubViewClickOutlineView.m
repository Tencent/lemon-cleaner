//
//  AcceptSubViewClickOutlineView.m
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "AcceptSubViewClickOutlineView.h"

@implementation AcceptSubViewClickOutlineView{
    NSMutableArray *acceptSubviewType;
}

- (void)addAcceptSubViewType:(Class)class
{
    if(acceptSubviewType == nil){
        acceptSubviewType = [[NSMutableArray alloc]init];
    }
    
    [acceptSubviewType addObject:class];
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    
    for(Class class in acceptSubviewType){
        if ([responder isKindOfClass:class])
            return YES;
    }
    
    return [super validateProposedFirstResponder:responder forEvent:event];
}

@end
