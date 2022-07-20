//
//  LMBaseViewController.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMBaseViewController.h"
#import "NSColor+Extension.h"
#import "NSString+Extension.h"
#import "NSFont+Extension.h"

@interface LMBaseViewController ()

@end

@implementation LMBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)windowWillClose:(NSNotification *)notification {
    
}

- (void)viewWillLayout{
    [super viewWillLayout];
    self.view.wantsLayer = YES;
    if([self isDarkMode]){
        self.view.layer.backgroundColor = [NSColor colorWithHex:0x242633].CGColor;
    }else{
        self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
}

-(Boolean)isDarkMode{
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance; // only 10.14
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    } else {
        return false;
    }
    return false;
}

-(void)setTitleColorForTextField:(NSTextField *)textField{
    if (@available(macOS 10.14, *)) {
        [textField setTextColor:[NSColor colorNamed:@"title_color" bundle:[NSBundle mainBundle]]];
    } else {
        [textField setTextColor:[NSColor colorWithHex:0x515151]];
    }
}


@end
