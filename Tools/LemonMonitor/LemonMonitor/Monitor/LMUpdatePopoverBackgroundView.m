//
//  MyPopoverBackgroundView.m
//  LemonSpaceAnalyse
//

//

#import "LMUpdatePopoverBackgroundView.h"
#import <QMCoreFunction/NSColor+Extension.h>

@implementation LMUpdatePopoverBackgroundView

-(void)drawRect:(NSRect)dirtyRect
{
    if([self isDarkMode]){
        [[NSColor colorWithHex:0x242633 alpha:1.0] set];
    }else{
        [[NSColor whiteColor] set];
    }
    
    NSRectFill(self.bounds);
}

-(Boolean)isDarkMode{
    if (@available(macOS 10.14, *)) {
        NSAppearance *apperance = NSApp.effectiveAppearance;
        return  [apperance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua,NSAppearanceNameAqua]] == NSAppearanceNameDarkAqua;
    } else {
        return false;
    }
    return false;
}

@end
