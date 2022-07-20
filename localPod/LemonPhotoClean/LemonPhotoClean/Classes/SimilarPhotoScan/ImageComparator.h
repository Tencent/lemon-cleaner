//
//  ImageComparator.h
//  FirmToolsDuplicatePhotoFinder
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageComparator : NSObject
//@property (nonatomic) BOOL checkExtension;
//@property (nonatomic,nonnull) NSMutableDictionary<NSString *,NSDictionary *> *vectorCache;
@property (nonatomic,nonnull) NSMutableArray<NSString *> *allPaths;
- (NSArray<NSString *> *)collectImagePathsInRootPath:(NSArray<NSString *> *)rootPath;

- (void)cancelCollectPath;
@end
