//
//  AppDelegate.h
//  Lemon
//

//  Copyright © 2018  Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface AppDelegate : NSObject <NSApplicationDelegate>


-(IBAction)asPrefrecesSet:(id)sender;

- (IBAction)collectLemonLogInfoAction:(id)sender;

- (void)showMainWCAfterRegister;

-(void)clearSplashWC;

@property(assign)  BOOL hasShowSplashPage;  //是否显示引导页

@end

