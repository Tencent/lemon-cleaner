//
//  LMCleanerDataCenter.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMCleanerDataCenter.h"
#import "LMCleanerDataCenter+LMCleanPatch.h"
#import <FMDB/FMDB.h>
#import "DeamonTimeHelper.h"
#include <semaphore.h>
#import "QMCategoryItem.h"
#import <QMCoreFunction/McCoreFunction.h>
#import "CleanerCantant.h"

@interface LMCleanerDataCenter()
{
    NSArray *_categoryArr;
    CleanStatus _cleanerStatus;
}
@end

@implementation LMCleanerDataCenter

+(id)shareInstance{
    static LMCleanerDataCenter * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMCleanerDataCenter alloc] init];
        [instance createLemonCleanTable];
        [instance createLemonCleanerStatusTable];
    });
    return instance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.m_subCategoryDict = [[NSMutableDictionary alloc] init];
        self.subcateStatusArr = [[NSMutableArray alloc] init];
        if ([McCoreFunction isAppStoreVersion]) {
            [self copyDbToGroupContainers];
        }else{
            [self copyDbToMonitorContainers];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self lmClean_resetDownloadSelectStatus];
        });
    }
    
    return self;
}

-(void)copyDbToGroupContainers{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleId isEqualToString:@"com.tencent.LemonLite"]) {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbSrcPath = [self getDbPath];
    if (![fileManager fileExistsAtPath:dbSrcPath]) {
        NSLog(@"dbSrcPath is not exist return");
        return;
    }
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"88L2Q4487U.com.tencent"];
    NSString *groupPath = [url path];
    NSString *groupSupPath = [groupPath stringByAppendingPathComponent:@"Library/Application Support"];
    NSString *dstDbPath = [groupSupPath stringByAppendingPathComponent:@"LemonClean.db"];
    if ([fileManager fileExistsAtPath:dstDbPath]) {
        NSLog(@"exist group db delete");
        [fileManager removeItemAtPath:dstDbPath error:nil];
    }
    NSError *error = nil;
    BOOL isCopySuccess = [fileManager copyItemAtPath:dbSrcPath toPath:dstDbPath error:&error];
    if (isCopySuccess) {
        NSLog(@"copySuccess ");
    }else{
        NSLog(@"copyFailed error = %@", error);
    }
}

-(void)copyDbToMonitorContainers{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleId isEqualToString:@"com.tencent.Lemon"]) {
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbSrcPath = [self getDbPath];
    if (![fileManager fileExistsAtPath:dbSrcPath]) {
        NSLog(@"dbSrcPath is not exist return");
        return;
    }
    NSString *dstDbPath = @"~/Library/Application Support/com.tencent.LemonMonitor/LemonClean.db";
    dstDbPath = [dstDbPath stringByStandardizingPath];
    NSLog(@"dstdbPath = %@", dstDbPath);
    if ([fileManager fileExistsAtPath:dstDbPath]) {
        NSLog(@"exist monitor db delete");
        [fileManager removeItemAtPath:dstDbPath error:nil];
    }
    NSError *error = nil;
    BOOL isCopySuccess = [fileManager copyItemAtPath:dbSrcPath toPath:dstDbPath error:&error];
    if (isCopySuccess) {
        NSLog(@"copySuccess ");
    }else{
        NSLog(@"copyFailed error = %@", error);
    }
}

-(void)createLemonCleanTable{
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"create table if not exists clean_result ( result_id INTEGER primary key AUTOINCREMENT, total_size UNSIGNED BIG INT NOT NULL, sys_size UNSIGNED BIG INT NOT NULL,  app_size UNSIGNED BIG INT NOT NULL, int_size UNSIGNED BIG INT NOT NULL, clean_type TINYINT not null, file_num UNSIGNED BIG INT not null, oprate_time UNSIGNED BIG INT not null,  createTime UNSIGNED BIG INT not null)"];
        [db commit];
        if(result){
//            NSLog(@"open db success");
        }else{
            NSLog(@"open db failed");
        }
        [db close];
    }else{
        NSLog(@"open failed");
    }
}

-(NSString *)getDbPath{
    NSString *appSuppPath = [self getApplicationSupportPath];
    NSString *dbPath = [appSuppPath stringByAppendingPathComponent:@"LemonClean.db"];
//    NSLog(@"dbPath = %@", dbPath);
    return dbPath;
}

-(NSString *)getApplicationSupportPath{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *bundleId = @"";
    bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *urlPaths = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleId isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
        [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return [appDirectory path];
}

-(FMDatabase *)getFMDB{
    NSString *dbPath = [self getDbPath];
//    NSString *dbPath = @"/Users/yangwenjun/Desktop/LemonClean.db";
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    return db;
}


-(void)addCleanRecordWithTotalSize:(UInt64) totalSize sysSize:(UInt64)sysSize appSize:(UInt64)appSize intSize:(UInt64)intSize cleanType:(NSInteger) cleanType fileNum:(NSUInteger) fileNum oprateTime:(NSUInteger) oprateTime{
    
    NSLog(@"addCleanRecordWithTotalSize enter");
    
    sem_t* semaphore = NULL;
    if (![McCoreFunction isAppStoreVersion]) {
        int iRet = 0;
        semaphore = sem_open("/LemonCleanerRecooder", O_CREAT, S_IRUSR|S_IWUSR|S_IXUSR|S_IRGRP|S_IWGRP|S_IXGRP, 1);
        if (semaphore == SEM_FAILED) {
            NSLog(@"addCleanRecordWithTotalSize sem_open failed");
            return;
        }
        
        iRet = sem_wait(semaphore);
        if (iRet != 0) {
            NSLog(@"addCleanRecordWithTotalSize sem_wait failed");
            return;
        }
    }
    
    NSLog(@"addCleanRecordWithTotalSize enter thread name = %@", [NSThread currentThread]);
    [self createLemonCleanTable];
    FMDatabase *db = [self getFMDB];
    if([db open]){
//        NSLog(@"open success");
        NSUInteger createTime = [[NSDate date] timeIntervalSince1970];
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"insert into clean_result (total_size, sys_size, app_size, int_size, clean_type, file_num, oprate_time, createTime) values (?, ?, ?, ?, ?, ?, ?, ?)", [NSNumber numberWithLongLong:totalSize], [NSNumber numberWithLongLong:sysSize], [NSNumber numberWithLongLong:appSize], [NSNumber numberWithLongLong:intSize], [NSNumber numberWithInteger:cleanType], [NSNumber numberWithUnsignedInteger:fileNum], [NSNumber numberWithUnsignedInteger:oprateTime], [NSNumber numberWithUnsignedInteger:createTime]];
        [db commit];
        if(result){
            NSLog(@"insert db success");
        }else{
            NSLog(@"insert db failed");
        }
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    
    NSLog(@"addCleanRecordWithTotalSize leave thread name = %@", [NSThread currentThread]);
    
    if (![McCoreFunction isAppStoreVersion]) {
        int iRet = sem_post(semaphore);
        if (iRet != 0) {
            NSLog(@"addCleanRecordWithTotalSize sem_post failed");
            //        sem_close(semaphore);
        }
        sem_close(semaphore);
    }
    
}

//创建一个记录上一次选择的db
-(void)createLemonCleanerStatusTable{
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"create table if not exists clean_status (status_id INTEGER primary key AUTOINCREMENT,  subcate_id varchar(20) not null,  status integer not null)"];
        [db commit];
        if(result){
//            NSLog(@"open db success");
        }else{
            NSLog(@"open db failed");
        }
        [db close];
    }else{
        NSLog(@"open failed");
    }
}

//根据subcate初始化记录 --- 第一次初始化时候
-(void)addRecordIfNotExist:(QMCategoryItem *)cateItem{
    if ((cateItem.m_categorySubItemArray != nil) && ([cateItem.m_categorySubItemArray count] != 0)) {
        for (QMCategorySubItem *subItem in cateItem.m_categorySubItemArray) {
            CleanSubcateSelectStatus status = [self getSubcateSelectStatus:subItem.subCategoryID];
            if (status == CleanSubcateSelectStatusNoSet) {
                [self addNewRecordWithId:subItem.subCategoryID recomment:subItem.recommend];
            }
            // Note: 二级目录增加入库初始化
            for (QMActionItem *actionItem in subItem.m_actionItemArray) {
                CleanSubcateSelectStatus astatus = [self getSubcateSelectStatus:actionItem.actionID];
                if (astatus == CleanSubcateSelectStatusNoSet) {
                    [self addNewRecordWithId:actionItem.actionID recomment:actionItem.recommend];
                }
            }
        }
    }
}

//是否需要提示用户记录选择状态
-(BOOL)needTipUserSaveSubcateStatus{
    if ([self.subcateStatusArr count] == 0) {
        return NO;
    }else{
        //依次与数据库目前的状态进行对比  如果有不一样的 就提示YES
        for (NSDictionary *dic in self.subcateStatusArr) {
            if (dic == nil) {
                continue;
            }
            NSArray *keyArr = dic.allKeys;
            if ((keyArr == nil) || ([keyArr count] == 0)) {
                continue;
            }
            NSString *subcateId = [keyArr objectAtIndex:0];
            NSInteger selectStatus = [[dic objectForKey:subcateId] integerValue];
            if (selectStatus == 0) {
                continue;
            }
            CleanSubcateSelectStatus storeStatus = [self getSubcateSelectStatus:subcateId];
            if (selectStatus != storeStatus) {
                return YES;
            }
            
        }
        return NO;
    }
}

//添加一条选中状态 到 待写入数据库中
-(void)addSubcateStatusToDatabaseWithId:(NSString *)subCateId selectStatus:(CleanSubcateSelectStatus) selectStatus{
    if ([self.subcateStatusArr count] == 0) {
        NSDictionary *dic = @{subCateId : [NSNumber numberWithInteger:selectStatus]};
        [self.subcateStatusArr addObject:dic];
    }else{
        BOOL isHit = NO;
        NSDictionary *hitDic;
        for (NSDictionary *dic in self.subcateStatusArr) {
            NSInteger value = [[dic objectForKey:subCateId] integerValue];
            if (value != 0) {
                if (value == selectStatus) {
                    return;
                }
                isHit = YES;
                hitDic = dic;
            }
        }
        if (isHit) {
            [self.subcateStatusArr removeObject:hitDic];
        }
        NSDictionary *dic = @{subCateId : [NSNumber numberWithInteger:selectStatus]};
        [self.subcateStatusArr addObject:dic];
    }
}

//获取一条subcate选中状态
-(CleanSubcateSelectStatus)getSubcateStatusWithSubcateId:(NSString *)subCateId{
    if([self.subcateStatusArr count] == 0){
        return CleanSubcateSelectStatusNoSet;
    }
    BOOL isHit = NO;
    NSDictionary *hitDic;
    for (NSDictionary *dic in self.subcateStatusArr) {
        NSInteger value = [[dic objectForKey:subCateId] integerValue];
        if (value != 0) {
            isHit = YES;
            hitDic = dic;
        }
    }
    if (!isHit) {
        return CleanSubcateSelectStatusNoSet;
    }else{
        NSInteger value = [[hitDic objectForKey:subCateId] integerValue];
        if (value == 1) {
            return CleanSubcateSelectStatusSelect;
        }else if(value == 2){
            return CleanSubcateSelectStatusDeselect;
        }
    }
    
    return CleanSubcateSelectStatusNoSet;
}

//remove all item
-(void)removeAllItemInSubCateArr{
    [self.subcateStatusArr removeAllObjects];
}

//add to db
-(void)storeSubcateArrToDb{
    for (NSDictionary *dic in self.subcateStatusArr) {
        NSArray *keyArr = [dic allKeys];
        if ((keyArr == nil) || ([keyArr count] == 0)) {
            continue;
        }
        NSString *subcateId = [[dic allKeys] objectAtIndex:0];
        NSInteger selectStatus = [[dic objectForKey:subcateId] integerValue];
        [self changeSubcate:subcateId selectStatus:(CleanSubcateSelectStatus)selectStatus];
    }
    if ([McCoreFunction isAppStoreVersion]) {//每次变化都会去进行设置一次
        [self copyDbToGroupContainers];
    }else{
        [self copyDbToMonitorContainers];
    }
    
}

//增加一条是否选中的记录
-(void)addNewRecordWithId:(NSString *)subcateId recomment:(BOOL) recommend{
    if (subcateId == nil) {
        return;
    }
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        NSInteger status1 = recommend ? 1 : 2;
        BOOL result = [db executeUpdate:@"insert into clean_status (subcate_id, status) values (?, ?)", subcateId, [NSNumber numberWithInteger:status1]];
        [db commit];
        if(result){
//            NSLog(@"open db success");
        }else{
            NSLog(@"open db failed");
        }
        [db close];
    }else{
        NSLog(@"open failed");
    }
}

//修改subcate的选中状态
-(void)changeSubcate:(NSString *)subCateId selectStatus:(CleanSubcateSelectStatus) selectStatus{
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"update clean_status set status = ? where subcate_id = ?", [NSNumber numberWithInteger:selectStatus], subCateId];
        [db commit];
        if(result){
            NSLog(@"open db success");
        }else{
            NSLog(@"open db failed");
        }
        [db close];
    }else{
        NSLog(@"open failed");
    }
}

//获取subcate选中状态
-(CleanSubcateSelectStatus)getSubcateSelectStatus:(NSString *)subCateId{
    FMDatabase *db = [self getFMDB];
    CleanSubcateSelectStatus status = 0;
    if([db open]){
        FMResultSet *resutSet = [db executeQuery:@"select * from clean_status where subcate_id = ?", subCateId];
        while ([resutSet next]) {
            status = [resutSet intForColumn:@"status"];
        }
        [db close];
    }else{
        NSLog(@"open failed");
    }
    
    return status;
}

//传入一个时间戳，获取最近七天总共数组值
-(UInt64)getSevenDaysTotalCleanSizeByTimeInterval:(NSTimeInterval) timeInterval{
    
    UInt64 totalSize = 0;
    NSArray *array = [self getSevenDaysShowModelByTimeInterval:timeInterval];
    for (LMCleanShowModel *model in array) {
        totalSize += model.totalSize;
    }
    
    return totalSize;
}

//传入一个时间戳，获取最近七天的清理数值数组
-(NSArray *)getSevenDaysTotalCleanSizeArrByTimeInterval:(NSTimeInterval) timeInterval{
    NSMutableArray *totalCleanSizeArr = [[NSMutableArray alloc] init];
    
    NSArray *array = [self getSevenDaysShowModelByTimeInterval:timeInterval];
    for (LMCleanShowModel *model in array) {
        UInt64 size = model.totalSize;
        NSString *sizeString = [NSString stringWithFormat:@"%llu", size];
        [totalCleanSizeArr addObject:sizeString];
    }
    
    return totalCleanSizeArr;
}

//传入一个时间戳，获取最近七天下表数组
-(NSArray *)getSevenDaysDateStrlByTimeInterval:(NSTimeInterval) timeInterval{
    NSMutableArray *totalDateStrArr = [[NSMutableArray alloc] init];
    
    NSArray *array = [self getSevenDaysShowModelByTimeInterval:timeInterval];
    for (LMCleanShowModel *model in array) {
        [totalDateStrArr addObject:model.dateTime];
    }
    
    return totalDateStrArr;
}

//传入一个时间戳 往前推七天获取cleanShowModel
-(NSArray *)getSevenDaysShowModelByTimeInterval:(NSTimeInterval) timeInterval{
    NSUInteger time = (NSUInteger)timeInterval;
    NSMutableArray *showModelArr = [[NSMutableArray alloc] init];
    for(NSInteger i = 6; i >= 0; i--){
        NSUInteger currentTime = time - ONE_DAY_TIME_INTERVAL * i;
        LMCleanShowModel *showModel = [self getCleanShowModelByTimeInterval:currentTime];
        if (showModel != nil) {
            [showModelArr addObject:showModel];
        }
    }
    
    return showModelArr;
}

//按照当天的时间戳来获取当日的LMCleanShowModel
-(LMCleanShowModel *)getCleanShowModelByTimeInterval:(NSUInteger) timeInterval{
//
    NSString *dateStr = [DeamonTimeHelper getDataStrByInterval:timeInterval];
    LMCleanShowModel *showModel = [[LMCleanShowModel alloc] initWithDateTime:dateStr];
    FMDatabase *db = [self getFMDB];

    if([db open]){
        NSMutableArray *resultModelArr = [[NSMutableArray alloc] init];
//        NSLog(@"open success");
        
        NSUInteger earlyTimeinterval = [DeamonTimeHelper get0diantimeInterval:dateStr];
        NSUInteger lateTimeinterval = [DeamonTimeHelper getTwelveTimerIntervalWithDateStr:dateStr];
        long long totalSize = 0;
        long long totalSysSize = 0;
        long long totalAppSize = 0;
        long long totalIntSize = 0;
        FMResultSet *resutSet = [db executeQuery:@"select * from clean_result where createTime < ? AND createTime > ?",[NSNumber numberWithUnsignedInteger:lateTimeinterval], [NSNumber numberWithUnsignedInteger:earlyTimeinterval]];
        while ([resutSet next]) {
            NSInteger clean_type = [resutSet intForColumn:@"clean_type"];
            if(clean_type == 1){
                continue;
            }
            NSInteger result_id = [resutSet intForColumn:@"result_id"];
            long long total_size = [resutSet unsignedLongLongIntForColumn:@"total_size"];
            long long  sys_size = [resutSet unsignedLongLongIntForColumn:@"sys_size"];
            long long  app_size = [resutSet unsignedLongLongIntForColumn:@"app_size"];
            long long  int_size = [resutSet unsignedLongLongIntForColumn:@"int_size"];
            NSUInteger file_num = [resutSet intForColumn:@"file_num"];
            long long  oprateTime = [resutSet unsignedLongLongIntForColumn:@"oprate_time"];
            long long  create_time = [resutSet unsignedLongLongIntForColumn:@"createTime"];
            
            totalSize += total_size;
            totalSysSize += sys_size;
            totalAppSize += app_size;
            totalIntSize += int_size;
            CleanResultType cleanType = (CleanResultType)clean_type;
            LMCleanResultModel *model = [[LMCleanResultModel alloc] initWithResultId:result_id totalSize:total_size sysSize:sys_size appSize:app_size intSize:int_size cleanType:cleanType fileNum:file_num oprateTime:oprateTime createTime:create_time];
            [resultModelArr addObject:model];
        }
        
        NSString *noYearDateStr = [DeamonTimeHelper getDataStrNoYearByInterval:timeInterval];
        showModel = [[LMCleanShowModel alloc] initTotalSize:totalSize sysJunkModel:totalSysSize appJunkModel:totalAppSize interJunkModel:totalIntSize dateTime:noYearDateStr];
        
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    
    return showModel;
}

-(void)refreshTotalSelectSize{
    UInt64 totalSelectSize = 0;
    for (QMCategoryItem * categoryItem in _categoryArr)
    {
        totalSelectSize += categoryItem.resultSelectedFileSize;
    }
    _totalSelectSize = totalSelectSize;
}

-(void)setCategoryArray:(NSArray *)categoryArr{
    _categoryArr = categoryArr;
    for (QMCategoryItem *categoryItem in categoryArr) {
        for (QMCategorySubItem * categorySubItem in categoryItem.m_categorySubItemArray)
        {
            [self.m_subCategoryDict setObject:categorySubItem forKey:categorySubItem.subCategoryID];
        }
    }
}

-(NSArray *)getCategoryArray{
    return _categoryArr;
}

-(void)setCurrentCleanerStatus:(CleanStatus) status{
    _cleanerStatus = status;
}

-(CleanStatus)getCurrentCleanerStatus{
    return _cleanerStatus;
}

//删除自适配软件 item size为0的项目
-(void)removeSoftAdaptSubItemSizeIsZero{
    for (QMCategoryItem *cateItem in _categoryArr) {
        if([cateItem.categoryID integerValue] == CategoryIdTypeApplication){
            NSMutableArray *showArr = [[NSMutableArray alloc] init];
            for (QMCategorySubItem *subItem in cateItem.m_categorySubItemArray) {
                if(([subItem resultFileSize] != 0) || (subItem.bundleId == nil)){
                    [showArr addObject:subItem];
                }else{
//                    NSLog(@"remove subitem = %@", [subItem title]);
                }
            }
            
            cateItem.m_categorySubItemArray = showArr;
        }
    }
}

@end
