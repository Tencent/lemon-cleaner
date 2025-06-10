//
//  NSAlert+OwlExtend.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "NSAlert+OwlExtend.h"
#import "Owl2Manager.h"

@implementation NSAlert (OwlExtend)

+ (void)owl_showScreenPrivacyProtection {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedStringFromTableInBundle(@"屏幕信息保护仅支持15.0及以上macOS版本，建议版本升级后继续开启。", nil, [NSBundle bundleForClass:[Owl2Manager class]], nil);
    
   
    [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"确认", nil, [NSBundle bundleForClass:[Owl2Manager class]], nil)];
    [alert runModal];
}
@end
