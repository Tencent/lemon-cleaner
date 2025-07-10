//
//  OwlWhitelistFoldCell.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlWhitelistFoldCell.h"

@implementation OwlWhitelistFoldCell

- (NSImage *)imageFoldOrExpandButton {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [bundle imageForResource:@"owl_fold_arrow"];
}

@end
