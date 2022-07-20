//
//  QMRadioButtonGroup.h
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QMRadioButtonGroup : NSObject
@property (readonly, nonatomic) NSArray *buttons;
+ (instancetype)buttonGroupWithButtons:(NSArray *)buttons keyPathForState:(NSString *)keyPath;
@end
