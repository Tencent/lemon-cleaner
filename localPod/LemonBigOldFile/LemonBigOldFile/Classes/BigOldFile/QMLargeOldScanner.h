//
//  QMLargeOldScanner.h
//  FileCleanDemo
//
//  
//  Copyright (c) 2014年 yuanwen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QMLargeOldScannerDelegate <NSObject>

- (BOOL)progressRate:(float)value path:(NSString *)path;
- (void)largeOldFileSearchEnd;

@end

@interface QMLargeOldItem : NSObject

@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, assign) UInt64 fileSize;
@property (nonatomic, assign) BOOL isDir;
@property (nonatomic, assign) NSTimeInterval lastAccessTime;
@property (nonatomic, retain) QMLargeOldItem * parentItem;

- (NSArray *)childrenItemArray;

@end

typedef enum
{
    QMLargeOldOnlyFile,
    QMLargeOldOnlyFolder,
    QMLargeOldAll
}QMLargeOldType;

@interface QMLargeOldScanner : NSObject


- (void)start:(id<QMLargeOldScannerDelegate>)scanDelegate
         path:(NSString *)path
 excludeArray:(NSArray *)array;
- (void)stopScan;

- (NSArray *)resultWithType:(QMLargeOldType)type fileSize:(UInt64)size;

@end
