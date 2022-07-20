//
//  McUninstallSoft.h
//  QMUnintallDemo
//
//  
//  Copyright (c) 2013年 haotan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMCoreFunction/McLocalSoft.h"
#import "QMCoreFunction/McSoftwareFileScanner.h"


enum
{
    McUninstallRemoveFinished = -1,
    McUninstallRemovingNone = 0
};

extern NSString *McUninstallSoftStateNotification;
extern NSString *McUninstallSoftFileSizeKey;
extern NSString *McUninstallSoftProgress;
extern NSString *McUninstallSoftPathKey;



@interface McUninstallSoft : NSObject
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, readonly) NSArray *flatItems;
@property (nonatomic, readonly) uint64_t size;
@property (nonatomic, readonly) NSDate *modifyDate;
@property (nonatomic, readonly) NSDate *createDate;
@property (nonatomic, readonly) NSString *showName;
@property (nonatomic, readonly) NSString *bundleID;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) McLocalType type;

+ (id)uninstallSoftWithSoft:(McLocalSoft *)localsoft;
+ (id)uninstallSoftWithPath:(NSString *)filePath;

- (void)appendItem:(id)item;
- (McSoftwareFileType)removingType;
- (void)removeItems:(NSArray *)array :(void(^)(double progress))progressHandler :(void(^)(BOOL removeAll))finishHandler;
- (void)delSelectedItems:(void(^)(double progress))progressHandler :(void(^)(BOOL removeAll))finishHandler;

@end

@interface McUninstallSoftGroup : McUninstallSoft
@property (nonatomic, strong) NSDictionary *groupInfo;
@end
