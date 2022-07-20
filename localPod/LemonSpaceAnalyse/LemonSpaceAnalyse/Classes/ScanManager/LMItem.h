//
//  LMItem.h
//  Lemon
//
//  
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMItem : NSObject

@property(nonatomic, copy) NSMutableArray *childItems;
@property(nonatomic, weak) LMItem *parentDirectory;

@property(nonatomic, strong) NSString *fileName;
@property(nonatomic, strong) NSString *fullPath;
@property(nonatomic, assign) long long sizeInBytes;

@property(nonatomic) BOOL isDirectory;

-(void)compareChild;
- (long long)calculateSizeInBytesRecursively;
- (id)initWithFullPath:(id)arg1;
- (id)init;

@end
