//
//  McUninstallSoftManager.h
//  McSoftwareScanner
//
//  
//  Copyright (c) 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/McUninstallSoft.h>

enum
{
    McLocalSortName = 0,
    McLocalSortSize,
    McLocalSortModifyDate,
    McLocalSortCreateDate
};
typedef NSInteger McLocalSort;

extern NSString *McUninstallSoftManagerChangedNotification;

@interface McUninstallSoftManager : NSObject
@property (nonatomic,assign) McLocalSort sortFlag;
@property (nonatomic,assign) BOOL ascending;
@property (nonatomic,strong) NSString *filterString;

+ (McUninstallSoftManager *)sharedManager;
- (NSArray *)softsWithType:(McLocalType)type;
- (BOOL)loading;
- (BOOL)refresh;
- (void)uninstall:(McUninstallSoft*)soft;
- (void)sortby:(McLocalSort)type isAscending:(BOOL)isAscending;

@end
