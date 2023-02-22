//
//  LMAboutWindow.h
//  Lemon
//
//  Copyright © 2022 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMAboutWindow : NSWindow

+ (instancetype)window;
+ (instancetype)windowWithVersionDate:(NSDate *_Nullable)versionDate;
+ (instancetype)windowWithVersionTimeString:(NSString *_Nullable)versionTimeString;

@end

NS_ASSUME_NONNULL_END
