//
//  QMLazyImageView.h
//  LazyImageView
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QMLazyImageView : NSImageView
@property (strong) NSImage *defaultImage;
@property (strong) NSImage *loadingImage;
@property (strong) NSImage *errorImage;
@property (strong) NSString *link;
@end
