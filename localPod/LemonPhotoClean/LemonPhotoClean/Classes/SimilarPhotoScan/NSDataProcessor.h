//
//  NSImage+Processor.h
//  FirmToolsDuplicatePhotoFinder
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define KEY_ASPECT_RATIO @"aspect ratio"
#define KEY_PIXELVECTOR @"pixel vector" 
@interface NSDataProcessor:NSObject
+ (NSDictionary *)abstractVector:(NSData*)data;

@end
