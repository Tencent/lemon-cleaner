//
//  SizeHelper.m
//  LemonDuplicateFile
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "SizeHelper.h"

#define SizeThousand  1000.0  // mac上的文件 大小显示的时候显示的是1000进制,而不是1024

@implementation SizeHelper

+ (NSString *)getFileSizeStringBySize:(double)fileSize {
    if (fileSize < 0) {
        return @"unknown size";
    }
    if (fileSize < (SizeThousand * SizeThousand)) {
        return [[NSString alloc] initWithFormat:@"%.2f KB", fileSize / (SizeThousand)];
    } else if (fileSize < SizeThousand * SizeThousand * SizeThousand) {
        return [[NSString alloc] initWithFormat:@"%.2f MB", fileSize / (SizeThousand * SizeThousand)];
    } else if (fileSize < SizeThousand * SizeThousand * SizeThousand * SizeThousand) {
        return [[NSString alloc] initWithFormat:@"%.2f GB", fileSize / (SizeThousand * SizeThousand * SizeThousand)];
    } else {
        return @"too large size";
    }
}
@end
