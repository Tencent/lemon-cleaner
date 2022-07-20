//
//  LMSpaceBaseViewController.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceBaseViewController.h"
#import <QMCoreFunction/NSColor+Extension.h>

@interface LMSpaceBaseViewController ()

@end

@implementation LMSpaceBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)windowWillClose:(NSNotification *)notification {
    
}

- (void)viewWillLayout {
    [super viewWillLayout];
    self.view.wantsLayer = YES;
    if([self isDarkMode]){
        self.view.layer.backgroundColor = [NSColor colorWithHex:0x242633].CGColor;
    }else{
        self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    }
}

- (Boolean)isDarkMode {
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance; // only 10.14
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    } else {
        return false;
    }
    return false;
}

- (void)setTitleColorForTextField:(NSTextField *)textField {
    if (@available(macOS 10.14, *)) {
        [textField setTextColor:[NSColor colorNamed:@"title_color" bundle:[NSBundle bundleForClass:[self class]]]];
    } else {
        [textField setTextColor:[NSColor colorWithHex:0x515151]];
    }
}


@end
