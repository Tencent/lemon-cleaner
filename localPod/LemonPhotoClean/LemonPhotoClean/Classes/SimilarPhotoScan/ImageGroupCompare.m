//
//  ImageGroupCompare.m
//  QQMacMgr
//
//  
//  Copyright © 2018 Hank. All rights reserved.
//
#import "ImageGroupCompare.h"
#import "ImageComparator.h"
#import "NSDataProcessor.h"
#import <AVFoundation/AVAsset.h>

#import <AVFoundation/AVAssetImageGenerator.h>

#import <AVFoundation/AVTime.h>
#import "CalculatePictureFingerprint.h"

#import "LMSimilarPhotoDataCenter.h"
#import <QMCoreFunction/NSString+Extension.h>

@interface ImageGroupCompare ()
@property (nonatomic) ImageComparator *comparator;

@property (nonatomic,nonnull) NSString *sourcePathString;
@property (nonatomic) BOOL compareStatus;
@property (nonatomic) NSInteger stepOneTotleNum;
@property (atomic) NSInteger stepOneScanNum;
@property (atomic) NSInteger stepTwoScanNum;
@property (nonatomic) NSInteger stepTwoTotleNum;

@property (nonatomic) float completeProgress;
@property (nonatomic) BOOL isCancel;

@property (nonatomic,strong) NSTimer *scanCheckTimer;
@property (nonatomic) NSInteger scanCheckProgressNum;

@property (nonatomic) NSInteger scanCheckProgressNumCopy;
@property (nonatomic) NSInteger repeatTimes;
@property (nonatomic, strong) dispatch_queue_t sqlQueue;

//@property (strong, nonatomic) NSOperationQueue* stepOneQueue;
//@property (strong, nonatomic) NSOperationQueue* stepTwoQueue;

@end

@implementation ImageGroupCompare

-(instancetype)init{
    self = [super init];
    if (self) {
        self.sqlQueue = dispatch_queue_create("sql_serial_queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

-(void)photoCompareWithPathArray:(NSArray<NSString *> *)sourcePathArray{
    NSLog(@"LMPhotoCleaner-->stepCalater");
    self.comparator = [[ImageComparator alloc] init];
    self.compareStatus = YES;
    self.resultData = [[NSMutableArray alloc] init];
    //获取所有的图片路径
    NSMutableArray<NSString *> *sourcePaths = [self getPhotoSourcePathsWithSourcePathArray:sourcePathArray];
    if(sourcePaths == nil){
        NSLog(@"LMPhotoCleaner-->stepCalater-sourcePaths is nil");
        return;
    }
    [self startTimer]; //开启定时器，检查扫描进度
    self.stepOneTotleNum = sourcePaths.count - 1;
    NSMutableDictionary *datePicPathDic = [self groupPhotoByTimeWithPaths:sourcePaths];//将照片按照分钟分组
    
    NSArray *keysArray = [datePicPathDic allKeys];//key: 时间 "2019-08-12 19:14"
    NSArray *sortedArray = [keysArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    __weak ImageGroupCompare *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_apply(sortedArray.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
            if(weakSelf.isCancel){
                return;
            }
            NSString *keyString = sortedArray[index];
            NSArray *pathByOrderArray = [datePicPathDic[keyString] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSNumericSearch];
            }];

            if (pathByOrderArray == nil || pathByOrderArray.count <= 0) {
                return;
            }

            BOOL isHitDatabase = NO;
            //@autoreleasepool里面代码就是为了进行数据库缓存
            @autoreleasepool{
                NSString *md5_key = [weakSelf getMD5WithPathArray:pathByOrderArray];
                NSMutableArray *resultDictionaryArray = [[LMSimilarPhotoDataCenter shareInstance] getResultDictionaryArrayWithGroupPathKey:md5_key];
                if (resultDictionaryArray !=nil && resultDictionaryArray.count > 0) {
                    for (NSString *resultDictionaryString in resultDictionaryArray) {
                         isHitDatabase = YES;
                        if([resultDictionaryString isEqualToString:@"0"]){
                            continue;
                        }
                        if (resultDictionaryString.length > 0) {
                            NSMutableDictionary<NSString *,id> *dict = [weakSelf dictionaryWithJsonString:resultDictionaryString];
                            if (dict == nil) {
                                continue;
                            }
                            NSArray *childrenArray = [dict objectForKey:@"children"];
                            if (childrenArray == nil ||childrenArray.count <= 0) {
                                continue;
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf.resultData addObject:dict];
                            });
                        }
                    }
                    weakSelf.stepOneScanNum += pathByOrderArray.count;
                    weakSelf.stepTwoScanNum += pathByOrderArray.count;
                    NSString *progressValueStr = [NSString stringWithFormat:@"%f",(weakSelf.stepTwoScanNum + 1)*0.4/(weakSelf.stepOneTotleNum * 1.0) + (weakSelf.stepOneScanNum+1) * 0.6/(weakSelf.stepOneTotleNum * 1.0)];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanProgress object:progressValueStr];
                }
                NSLog(@"isHitDatabase:%hhd, md5_key:%@, path[0]:%@, resultDictionaryArrayCount:%lu",isHitDatabase,md5_key,pathByOrderArray[0],(unsigned long)resultDictionaryArray.count);
            }
           
            if (isHitDatabase) {
                return;
            }
            __block NSMutableArray <NSString *> *array = [pathByOrderArray mutableCopy];

            //开始去获取图片数据 以作对比图片的相似性
            if (array != nil) {
                [weakSelf getPictureData:[array mutableCopy]];
                [array removeAllObjects];
                array = nil;
            }
        });
    });
}

- (void)stepCalater:(NSArray<NSString *> *)sourcePathArray{
    self.comparator = [[ImageComparator alloc] init];
    self.compareStatus = YES;
    self.resultData = [[NSMutableArray alloc] init];
    
    //获取所有的图片路径
    NSMutableArray<NSString *> *sourcePaths = [[NSMutableArray alloc] init];
    @autoreleasepool {
        NSArray<NSString *> * collectPaths = [self.comparator collectImagePathsInRootPath:sourcePathArray];
        [sourcePaths addObjectsFromArray:[collectPaths mutableCopy]];
        collectPaths  = nil;
    }
    
    if(sourcePaths.count <= 1 && self.isCancel == NO){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ReloadSimilatorImageTableView object:self.resultData];
        });
        return;
    }
    self.stepOneTotleNum = sourcePaths.count - 1;
    //    以天为单位把所有照片路径和日期按key value归并储存起来
    //    主要目的是为了按照天为维度  将所有照片分组  每个组内进行相似性对比  而不是全量对比x
    NSMutableDictionary *datePicPathDic = [NSMutableDictionary new];
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    
    for(int index = 0;index < sourcePaths.count;index ++){
        if(self.isCancel){
            break;
        }
        @autoreleasepool{
            NSString *path = sourcePaths[index];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                continue;
            
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
            //                NSLog(@"createDate:%@",createDate);
            NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:createTime];
            NSString* dateString = [fmt stringFromDate:createDate];
            if (dateString == nil) {
                continue;
            }
            NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
            if(datePicPathDic[dateString]){
                mutableArray = [datePicPathDic[dateString] mutableCopy];
            }
            
            if([mutableArray containsObject:path]){
                
            } else {
                [mutableArray addObject:path];
                [datePicPathDic setValue:mutableArray forKey:dateString];
            }
        }
    }
    
    //把所有的key 通过时间大小进行排序
    //    <__NSSingleObjectArrayI 0x600000024ad0>(
    //        2019-01-23 11:09
    //        2019-01-24 11:09
    //    )
    NSArray *keysArray = [datePicPathDic allKeys];
    NSArray *sortedArray = [keysArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    __weak ImageGroupCompare *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_apply(sortedArray.count, dispatch_get_global_queue(0, 0), ^(size_t index) {
            if(weakSelf.isCancel){
                return;
            }
            NSString *keyString = sortedArray[index];
            NSArray *pathByoOrderArray = [datePicPathDic[keyString] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1 compare:obj2 options:NSNumericSearch];
            }];
            
            if (pathByoOrderArray == nil || pathByoOrderArray.count <= 0) {
                return;
            }
            
            BOOL isHitDatabase = NO;
            //            dispatch_sync(sqlQueue, ^{
            //@autoreleasepool里面代码就是为了进行数据库缓存
            @autoreleasepool{
                NSString *md5_key = [weakSelf getMD5WithPathArray:pathByoOrderArray];
                if ([[LMSimilarPhotoDataCenter shareInstance] isExistResultWithGroupPathKey:md5_key]) {
                    [weakSelf startTimer];
                    
                    NSMutableArray *md5_array = [NSMutableArray arrayWithCapacity:pathByoOrderArray.count];
                    for (NSString *passPath in pathByoOrderArray) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanPath object:passPath];
                        if ([weakSelf getMD5WithPathArray:@[passPath]] != nil) {
                            [md5_array addObject:[weakSelf getMD5WithPathArray:@[passPath]]];
                        }
                    }
                    
                    NSMutableArray *resultDictionaryArray = [[LMSimilarPhotoDataCenter shareInstance] getResultDictionaryWithKey:md5_array];
                    
                    for (NSString *resultDictionaryString in resultDictionaryArray) {
                        if([resultDictionaryString isEqualToString:@"0"]){
                            continue;
                        }
                        if (resultDictionaryString.length > 0) {
                            NSMutableDictionary<NSString *,id> *dict = [weakSelf dictionaryWithJsonString:resultDictionaryString];
                            if (dict == nil) {
                                continue;
                            }
                            NSArray *childrenArray = [dict objectForKey:@"children"];
                            if (childrenArray == nil ||childrenArray.count <= 0) {
                                continue;
                            }
                            //判断是否子路径中是否其中一个存在  否则就continue掉
                            BOOL isExistPath = NO;
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            for (NSDictionary *childDic in childrenArray) {
                                NSString *childPath = [childDic objectForKey:@"targetpath"];
                                if ([fileManager fileExistsAtPath:childPath]) {
                                    isExistPath = YES;
                                    for (NSString *scanPath in sourcePathArray) {
                                        if (![childPath containsString:scanPath]) {
                                            isExistPath = NO;
                                        }
                                    }
                                }
                            }
                            if (!isExistPath) {
                                continue;
                            }
                            isHitDatabase = YES;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf.resultData addObject:dict];
                            });
                        }
                    }
                    
                    weakSelf.stepOneScanNum += pathByoOrderArray.count;
                    weakSelf.stepTwoScanNum += pathByoOrderArray.count;
                    NSString *progressValueStr = [NSString stringWithFormat:@"%f",(weakSelf.stepTwoScanNum + 1)*0.4/(weakSelf.stepOneTotleNum * 1.0) + (weakSelf.stepOneScanNum+1) * 0.6/(weakSelf.stepOneTotleNum * 1.0)];
                    [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanProgress object:progressValueStr];
                }
            }
            //            });
            
            if (isHitDatabase) {
                return;
            }
            __block NSMutableArray <NSString *> *array = [pathByoOrderArray mutableCopy];
            
            //开始去获取图片数据 以作对比图片的相似性
            //            [self.stepOneQueue addOperationWithBlock:^{
            //                @autoreleasepool {
            if (array != nil) {
                [weakSelf getPictureData:[array mutableCopy]];
                [array removeAllObjects];
                array = nil;
            }
            
            //                }
            //            }];
        });
    });
}

-(NSMutableArray *)getPhotoSourcePathsWithSourcePathArray: (NSArray *)sourcePathArray{
    //获取所有的图片路径
    NSMutableArray<NSString *> *sourcePaths = [[NSMutableArray alloc] init];
    @autoreleasepool {
        NSArray<NSString *> * collectPaths = [self.comparator collectImagePathsInRootPath:sourcePathArray];
        [sourcePaths addObjectsFromArray:[collectPaths mutableCopy]];
        collectPaths  = nil;
    }
    if(sourcePaths.count <= 1 && self.isCancel == NO){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ReloadSimilatorImageTableView object:self.resultData];
        });
        return nil;
    }
    return sourcePaths;
}

/**
 将照片按照分钟进行分组
 
 @param sourcePaths 所有图片路径
 @return 分组后的Dictionary
 */
-(NSMutableDictionary *)groupPhotoByTimeWithPaths: (NSMutableArray *)sourcePaths{
    NSLog(@"LMPhotoCleaner-->stepCalater create group by time start");
    NSMutableDictionary *datePicPathDic = [NSMutableDictionary new];
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm";
    
//    double startTime = [[NSDate date]timeIntervalSince1970];
//    NSLog(@" groupPhotoByTimeWithPaths_startTime:%f",startTime);
    for(int index = 0;index < sourcePaths.count;index ++){
        if(self.isCancel){
            break;
        }
        @autoreleasepool{
            NSString *path = sourcePaths[index];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                continue;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
            NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:createTime];//createDate 2019-07-24 08:41:21 UTC
            NSString* dateString = [fmt stringFromDate:createDate];//dateString  @"2019-07-24 16:41"
            if (dateString == nil) {
                continue;
            }
            NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
            if(datePicPathDic[dateString]){
                mutableArray = [datePicPathDic[dateString] mutableCopy];
            }
            
            if([mutableArray containsObject:path]){
                
            } else {
                [mutableArray addObject:path];
                [datePicPathDic setValue:mutableArray forKey:dateString];
            }
        }
    }
    double endTime = [[NSDate date]timeIntervalSince1970];
    NSLog(@" groupPhotoByTimeWithPaths_endTime:%f",endTime);

    NSLog(@"LMPhotoCleaner-->stepCalater create group by time end");
    return datePicPathDic;
}

- (void)scanCheck{
    NSLog(@"scanCheck-->scanCheckProgressNum:%ld",self.scanCheckProgressNum);
//    NSLog(@"scanCheck-->stepOneScanNum:%ld",self.stepOneScanNum);
//    NSLog(@"scanCheck-->stepTwoScanNum:%ld",self.stepTwoScanNum);
    NSLog(@"scanCheck-->repeatTimes:%ld",self.repeatTimes);
    if(self.scanCheckProgressNum == self.stepOneScanNum + self.stepTwoScanNum){
        if(self.stepOneTotleNum < self.scanCheckProgressNum*0.6 ||  self.repeatTimes == 100){
            [self stopTimer];
            if(self.isCancel){
                return;
            }
            [self showResultView];
        } else {
            if (self.scanCheckProgressNumCopy == self.scanCheckProgressNum) {
                self.repeatTimes ++;
            } else {
                self.scanCheckProgressNumCopy = self.scanCheckProgressNum;
                self.repeatTimes = 0;
            }
        }
    }
    
    self.scanCheckProgressNum = self.stepOneScanNum + self.stepTwoScanNum;
}

- (void)cancelScan{
    self.isCancel = YES;
    [self.comparator cancelCollectPath];
    self.comparator = nil;
    //    [self.stepOneQueue cancelAllOperations];
    //    [self.stepTwoQueue cancelAllOperations];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.scanCheckTimer != nil){
            [self.scanCheckTimer invalidate];
            self.scanCheckTimer = nil;
        }
    });
    
    [self.resultData removeAllObjects];
}

//依次获取每个图片的特征数据，并且通过key-value（path ：图片数据）的形式放入vectorTemp字典
//然后统一调用【stepForSimilar: vectorTemp:】方法来进行相似性对比
- (void)getPictureData:(NSMutableArray<NSString *> *)sourcePaths{
    __block NSMutableDictionary<NSString *,NSMutableArray *> *vectorTemp = [[NSMutableDictionary alloc] initWithCapacity:sourcePaths.count];
    __weak typeof(self)weakSelf = self;
    
    for(int index = 0; index < sourcePaths.count; index ++){
        if (self.isCancel == YES) {
            [vectorTemp removeAllObjects];
            vectorTemp = nil;
            return ;
        }
        __block NSString *path = sourcePaths[index];
        
        if(self.compareStatus == NO){
            break;
        }
        @autoreleasepool{
            NSMutableArray *sourceVectorAry = [CalculatePictureFingerprint getdataArray:path];
            if(sourceVectorAry.count == 0){
            } else {
                [vectorTemp setObject:sourceVectorAry forKey:path];
                sourceVectorAry = nil;
            }
            self.stepOneScanNum++;
            
            if (index == sourcePaths.count - 1){
                //                [self.stepTwoQueue addOperationWithBlock:^{
                @autoreleasepool{
                    //相似对比
                    [weakSelf stepForSimilar:[sourcePaths mutableCopy] vectorTemp:[vectorTemp mutableCopy]];
                }
                [vectorTemp removeAllObjects];
                [sourcePaths removeAllObjects];
                vectorTemp = nil;
                //                }];
            }
            //回调主界面进度数据和路径数据
            NSString *progressValueStr = [NSString stringWithFormat:@"%f",(self.stepTwoScanNum+1)*0.4/(self.stepOneTotleNum*1.0) + (self.stepOneScanNum+1)* 0.6/(self.stepOneTotleNum*1.0)];
            [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanProgress object:progressValueStr];
            [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanPath object:path];
        }
        path = nil;
    }
}

- (void) setSectionHeader:(NSMutableDictionary* )sectionDic {
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    fmt.dateFormat = NSLocalizedStringFromTableInBundle(@"ImageGroupCompare_setSectionHeader_1553065843_1", nil, [NSBundle bundleForClass:[self class]], @"");
    
    NSString *path = sectionDic[SOURCE_PATH];
    //    MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef)path);
    //    if(item){
    //        NSDate *createDate = (__bridge_transfer NSDate *)MDItemCopyAttribute(item, kMDItemContentCreationDate);
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return;
    
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
    //                NSLog(@"createDate:%@",createDate);
    NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:createTime];
    NSString* dateString = [fmt stringFromDate:createDate];
    [sectionDic setValue:dateString forKey:SECTION_HEADER];
    createDate = nil;
    dateString = nil;
    //        CFRelease(item);
    //    }
    //    path = nil;
    //    fmt = nil;
}

// 取最老的照片作为推荐照片
- (void) setPreferPhoto:(NSMutableDictionary* )sectionDic {
    NSMutableArray *sumTempArray = [[NSMutableArray alloc] init];
    [sumTempArray addObject:sectionDic[SOURCE_PATH]];
    
    NSArray *sectionArray = sectionDic[CHILDREN];
    for (NSMutableDictionary *dicTemp in sectionArray) {
        [sumTempArray addObject:[dicTemp objectForKey:TARGET_PATH]];
    }
    NSDate *latestDate;
    NSString *preferPath;
    for (NSString *path in sumTempArray) {
        @autoreleasepool{
            //            MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef)path);
            //            if(item){
            //                NSDate *createDate = (__bridge_transfer NSDate *)MDItemCopyAttribute(item, kMDItemContentModificationDate);
            if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                continue;
            
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSTimeInterval createTime = [[attr objectForKey:NSFileCreationDate] timeIntervalSince1970];
            //                NSLog(@"createDate:%@",createDate);
            NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:createTime];
            if (!latestDate) {
                latestDate = createDate;
                preferPath = path;
            } else {
                if ([createDate compare:latestDate] == NSOrderedDescending) {
                    latestDate = createDate;
                    preferPath = path;
                }
            }
            //                CFRelease(item);
            //            }
        }
    }
    sumTempArray = nil;
    [sectionDic setValue:preferPath forKey:PREFER_PATH];
    preferPath = nil;
}

- (void)startTimer{
    if(nil == self.scanCheckTimer){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.scanCheckTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(scanCheck) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.scanCheckTimer forMode:NSRunLoopCommonModes];
            [self.scanCheckTimer fire];
        });
    }
}

-(void)stopTimer{
    if(self.scanCheckTimer){
        [self.scanCheckTimer invalidate];
        self.scanCheckTimer = nil;
    }
}

//两两对比来对比相似性
- (void)stepForSimilar:(NSMutableArray<NSString *> *)sourcePaths vectorTemp:(NSMutableDictionary<NSString *,NSMutableArray *> *)vectorTemp{
    //    等到第二步启动扫描是否结束定时器
    [self startTimer];
    NSMutableArray<NSString *> *alreadyInResultPaths = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *targetPaths = [sourcePaths mutableCopy];
    self.stepTwoTotleNum = self.stepTwoTotleNum + sourcePaths.count;
    NSLock* lock = [[NSLock alloc] init];
    
    NSUInteger similarNum = 0;
    NSString *md5_key = [self getMD5WithPathArray:sourcePaths];
    for (NSString *sourcePath in sourcePaths) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanPath object:sourcePath];
        
        if(self.isCancel){
            break;
        }
        [lock lock];
        self.stepTwoScanNum++;
        [lock unlock];
        
        NSString *progressValueStr = [NSString stringWithFormat:@"%f",(self.stepTwoScanNum + 1)*0.4/(self.stepOneTotleNum * 1.0) + (self.stepOneScanNum+1) * 0.6/(self.stepOneTotleNum * 1.0)];
        [[NSNotificationCenter defaultCenter] postNotificationName:SimilatorImageScanProgress object:progressValueStr];
        progressValueStr = nil;
        
        if([alreadyInResultPaths containsObject:sourcePath]){
            continue;
        }
        BOOL isExist = NO;
        id sourcePathDicIdObject;
        for (NSInteger index = 0;index<self.resultData.count;index++) {
            if(self.isCancel){
                break;
            }
            if (index >= [self.resultData count]) {
                break;
            }
            @try {
                sourcePathDicIdObject = self.resultData[index];
            } @catch (NSException *exception) {
                NSLog(@"ImageGroupComare_stepForSimilar_resultData[index]_exception = %@", exception);
                break;
            }
            if (sourcePathDicIdObject == nil) {
                continue;
            }
            if ([sourcePathDicIdObject isEqual:[NSNull class]]) {
                continue;
            }
            
            NSMutableDictionary *sourcePathDic = (NSMutableDictionary *)sourcePathDicIdObject;
            
            @try{
                if (sourcePathDic.allKeys.count == 0 || ![sourcePathDic.allKeys containsObject:CHILDREN]) {
                    continue;
                }
            }@catch (NSException *exception) {
                NSLog(@"sourcePathDic exception = %@", exception);
                continue;
            }
            
            NSArray *childrenArray = sourcePathDic[CHILDREN];
            for (NSDictionary *childrenDic in childrenArray){
                if([childrenDic[@"targetpath"] isEqualToString:sourcePath]){
                    isExist = YES;
                }
            }
            childrenArray = nil;
            sourcePathDic = nil;
            sourcePathDicIdObject = nil;
        }
        
        if(isExist == YES){
            continue;
        }
        
        NSMutableDictionary<NSString *,NSNumber *> *similarityMap = [NSMutableDictionary dictionary];
        
        for (NSString *targetPath in targetPaths) {
            if(self.isCancel){
                break;
            }
            if([alreadyInResultPaths containsObject:targetPath]){
                continue;
            }
            NSNumber *similarity = 0;
            
            if([targetPath isEqualToString:sourcePath]||sourcePath.length == 0||targetPath.length == 0){
                continue;
            }
            
            if (self.compareStatus == YES && [sourcePath isEqualToString:targetPath]) {
                continue;
            }
            
            //获取相似性
            @autoreleasepool{
                similarity = @([CalculatePictureFingerprint compareDataA:[vectorTemp objectForKey:sourcePath] andDataB:[vectorTemp objectForKey:targetPath]]);
                similarityMap[targetPath]=similarity;
            }
        }
        @autoreleasepool{
            NSMutableArray<NSDictionary<NSString *,NSString *> *> *children = [[NSMutableArray alloc] init];
            
            //大于0.88才认为是相似照片
            [similarityMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                if (obj.doubleValue > 0.88) {
                    @autoreleasepool{
                        @try {
                            [alreadyInResultPaths addObject:key];
                            [children addObject:@{TARGET_PATH:key, SIMILARITY:[NSString stringWithFormat:@"%.02f%%",obj.doubleValue*100]}];
                        } @catch (NSException *exception) {
                            NSLog(@"ImageGroupComare_stepForSimilar_[alreadyInResultPaths addObject]_exception = %@", exception);
                        }
                    }
                    
                }
            }];
            [similarityMap removeAllObjects];
            similarityMap = nil;
            if(children.count > 0){
                similarNum ++;
                [alreadyInResultPaths addObject:sourcePath];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:sourcePath, SOURCE_PATH, children, CHILDREN, nil];
                if (![dict isKindOfClass:[NSDictionary class]]) {
                    continue;
                }
                [self setSectionHeader:dict];
                //设置一张默认不选中的图片
                [self setPreferPhoto:dict];
                if(self.isCancel || self.resultData == nil)
                    break;
                [self.resultData addObject:dict];
                NSString *resultDictionaryString = [self convertToJsonData:dict];
                
                dispatch_async(self.sqlQueue, ^{
                    NSLog(@"LMSimilarPhotoDataCenter sourcePath:%@",sourcePath);
                    NSLog(@"LMSimilarPhotoDataCenter md5_key:%@",md5_key);
                    [[LMSimilarPhotoDataCenter shareInstance] addNewResultWithSourcePathKey:[self getMD5WithPathArray:@[sourcePath]] groupPathKey:md5_key dictionary:resultDictionaryString];
                });
                
                dict = nil;
            }
            children = nil;
        }
        if((self.stepTwoScanNum >= self.stepTwoTotleNum - 1)&&(self.stepOneScanNum >= self.stepOneTotleNum - 1)){
            [self stopTimer];
            [self showResultView];
        }
    }
    if(similarNum==0){
        dispatch_async(self.sqlQueue, ^{
//            [LMSimilarPhotoDataCenter shareInstance] addNewResultWithSourcePathKey:<#(nonnull NSString *)#> groupPathKey:<#(nonnull NSString *)#> dictionary:<#(nonnull NSString *)#>
            [[LMSimilarPhotoDataCenter shareInstance] addNewResultWithSourcePathKey:[self getMD5WithPathArray:@[@""]] groupPathKey:md5_key dictionary:@"0"];
        });
    }
    [sourcePaths  removeAllObjects];
    [targetPaths removeAllObjects];
    [vectorTemp removeAllObjects];
    [alreadyInResultPaths removeAllObjects];
    
    sourcePaths = nil;
    targetPaths = nil;
    vectorTemp = nil;
    alreadyInResultPaths = nil;
}


- (NSNumber *)isExistAlreadyCompareData:(NSDictionary *)alreadyCompareData needCompare:(NSArray *)needCompareArray{
    NSString *sourcePath = needCompareArray[0];
    NSString *targetPath = needCompareArray[1];
    @autoreleasepool{
        NSNumber * oneSimilarity = [self checkData:alreadyCompareData path:sourcePath withPath:targetPath];
        if(oneSimilarity > 0){
            return oneSimilarity;
        }
        
        NSNumber * anotherSimilarity = [self checkData:alreadyCompareData path:targetPath withPath:sourcePath];
        if(anotherSimilarity > 0){
            return anotherSimilarity;
        }
    }
    
    return 0;
}

- (NSNumber *)checkData:(NSDictionary *)alreadyCompareData path:(NSString *)path withPath:(NSString *)anotherpath{
    NSNumber *similarity = 0;
    
    NSDictionary *targetPathDicFromSaveData = [NSDictionary new];
    for (NSDictionary *dic in alreadyCompareData){
        if([path isEqualToString:dic[SOURCE_PATH]]){
            targetPathDicFromSaveData = [dic mutableCopy];
        }
    }
    
    if(targetPathDicFromSaveData&&targetPathDicFromSaveData.allKeys.count > 0){
        NSArray *chilrenArray = targetPathDicFromSaveData[CHILDREN];
        for(NSDictionary *dic in chilrenArray){
            if([dic[TARGET_PATH] isEqualToString:anotherpath]){
                NSString *similarityStr = dic[SIMILARITY];
                float value = [similarityStr floatValue]/1.0;
                similarity = [[NSNumber alloc] initWithFloat: value];
                return similarity;
            }
        }
    }
    return 0;
}

- (NSString *)getDataFilePath:(NSString *)fileName{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [documentPath stringByAppendingPathComponent:fileName];
}

- (void)showResultView{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ReloadSimilatorImageTableView object:[weakSelf.resultData mutableCopy]];
        [weakSelf cancelScan];
    });
}
//相似视频相关
//+ (NSArray <NSImage*>*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
//
//    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
//    NSParameterAssert(asset);
//    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
//    assetImageGenerator.appliesPreferredTrackTransform = YES;
//    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
//    CGSize maximumSize = assetImageGenerator.maximumSize;
//
//    CMTime totalTime = [asset duration];
//    int seconds = ceil(totalTime.value/totalTime.timescale);
//    NSLog(@"-----%d----------",seconds);
//    if (seconds < 5){
//        return nil;
//    }
//
//    MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef)[videoURL absoluteString]);
//    NSDate *createDate = (__bridge_transfer NSDate *)MDItemCopyAttribute(item, kMDItemContentCreationDate);
//    NSLog(@"-----%@---------",createDate);
//
//    NSMutableArray <NSImage*> *mutableArray = [NSMutableArray new];
//    for (NSInteger secondsIndex = 0; secondsIndex<seconds; secondsIndex++){
//        CGImageRef thumbnailImageRef = NULL;
//        CFTimeInterval thumbnailImageTime = secondsIndex;
//        NSError *thumbnailImageGenerationError = nil;
//        thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
//
//        if(!thumbnailImageRef)
//            NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
//
//        NSImage *thumbnailImage = thumbnailImageRef ? [[NSImage alloc]initWithCGImage:thumbnailImageRef size:NSSizeFromCGSize(maximumSize)]:nil ;
//        [mutableArray addObject:thumbnailImage];
//    }
//
//    return mutableArray;
//}


-(void)dealloc{
    NSLog(@"Super Dealloc _______________________ ，%@",[self className]);
}

- (NSString *)getMD5WithPathArray:(NSArray *)array {
    NSString *paths = @"";
    for (NSUInteger index = 0; index < array.count; index++) {
        NSString *path = array[index];
        if (paths) {
            paths = [paths stringByAppendingString:path];
        }
    }
    return [paths md5String];
}

-(NSString *)convertToJsonData:(NSDictionary *)dict{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
        
    }else{
        
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    //    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    
    //    [mutStr replaceOccurrencesOfString:@" " withString:@" " options:NSLiteralSearch range:range];
    
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
    
}


- (NSMutableDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}


@end

