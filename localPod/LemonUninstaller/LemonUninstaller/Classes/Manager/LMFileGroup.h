//
//  LMFileGroup.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>
#import "LMFileItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMFileGroup : NSObject <NSCopying>

@property (nonatomic, assign) LMFileType                    fileType;
@property (nonatomic, assign, readonly) NSInteger           totalSize;
@property (nonatomic, strong) NSArray<LMFileItem *>         *filePaths;
@property (nonatomic, assign, readonly) NSInteger           selectedCount;  //都是实时计算的属性.
@property (nonatomic, assign, readonly) NSInteger           selectedSize;
@property (nonatomic, assign, readonly) NSControlStateValue selectedState;

- (void)removeItem:(LMFileItem *)item;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)addFileItem:(LMFileItem *)item;
- (void)merge:(LMFileGroup *)group;
- (BOOL)containsPath:(NSString *)path;
- (void)delSelectedItem:(void(^)(LMFileItem *deletedItem))itemDeletedHandler;
- (void)cleanDeletedItem;

@end

NS_ASSUME_NONNULL_END
