//
//  LMItem.m
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LMItem.h"
#import "LMThemeManager.h"

@implementation LMItem

- (id)init {
    self = [super init];
    if (self) {
        _childItems = [NSMutableArray array];
        _fileName = @"";
        _fullPath = @"";
        _sizeInBytes = 0;
        _isDirectory = NO;
        
    }
    return self;
}

- (id)initWithFullPath:(NSString *)path {
    self = [self init];
    if (self) {
        self.fullPath = path;
    }
    return self;
}

- ( long long )calculateSizeInBytesRecursively {
    __block long long total = 0;
    if (self.isDirectory == YES) {
        
        [self.childItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            LMItem *item = obj;
            if (item.isDirectory == YES) {
                total = total + [item calculateSizeInBytesRecursively];
            }else{
                total = total + [item sizeInBytes];
            }
            
        }];
        self.sizeInBytes = total;
        if([self.fileName hasSuffix:@".app"] ||[self.fileName hasSuffix:@".bundle"]) {
            self.childItems = [NSMutableArray array];
            self.isDirectory = NO;
        }
        return total;
    }else{
        return self.sizeInBytes;
    }
}

- (void)compareChild {
    if (self.isDirectory == YES) {
        if (self.childItems != nil && self.childItems.count > 0) {
            self.childItems = [self compareArr:self.childItems];
            
            [self.childItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                LMItem *item = obj;
                if (item.isDirectory == YES) {
                    [item compareChild];
                }
            }];
        }
    }

}

- (NSMutableArray *)compareArr:(NSMutableArray *)array {
    [array sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        LMItem *item1 = (LMItem *)obj1;
        LMItem *item2 = (LMItem *)obj2;
            if (item1.sizeInBytes > item2.sizeInBytes) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
    }];
    return [array copy];
}

@end
