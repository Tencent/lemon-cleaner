//
//  LMCleanViewController.h
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMBaseViewController.h"

@interface LMRemoveViewController : LMBaseViewController
{
    __weak IBOutlet NSView *cleaningView;
    __weak IBOutlet NSView *doneView;
    
    __weak IBOutlet NSTextField *pathText;
    
    __weak IBOutlet NSTextField *removedDescText;
}

- (void)showCleaningView;

@end
