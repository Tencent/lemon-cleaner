//
//  RegisterWindowController.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^RegisterSuccesCallback)(void);

@interface RegisterWindowController : NSWindowController

@property (nonatomic)  RegisterSuccesCallback successCallback;

- (instancetype)initWithCallback:(RegisterSuccesCallback)callback;
@end
