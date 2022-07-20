//
//  QMBaseWindowController.h
//  QMUICommon
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QMWindowDelegate<NSObject>

-(void)windowWillDismiss:(NSString *)clsName;

@end

@interface QMBaseWindowController : NSWindowController

@property (weak, nonatomic) id<QMWindowDelegate> delegate;

-(void)setWindowCenterPositon:(CGPoint) centerPoint;

@end
