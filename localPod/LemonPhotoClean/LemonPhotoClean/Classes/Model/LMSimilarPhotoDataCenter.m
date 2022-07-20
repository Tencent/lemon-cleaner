//
//  LMSimilarPhotoDataCenter.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMSimilarPhotoDataCenter.h"
#import <FMDB/FMDB.h>

@implementation LMSimilarPhotoDataCenter

+(id)shareInstance{
    static LMSimilarPhotoDataCenter * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMSimilarPhotoDataCenter alloc] init];
        [instance createPictureSimilarResultTable];
    });
    return instance;
}

-(NSString *)getDbPath{
    NSString *appSuppPath = [self getApplicationSupportPath];
    NSString *dbPath = [appSuppPath stringByAppendingPathComponent:@"LMSimilarPhotos.db"];
    return dbPath;
}

-(NSString *)getApplicationSupportPath{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *urlPaths = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appDirectory = [[urlPaths objectAtIndex:0] URLByAppendingPathComponent:bundleId isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:[appDirectory path]]) {
        [fileManager createDirectoryAtURL:appDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
//    NSLog(@"appdirectory path = %@", [appDirectory path]);
    return [appDirectory path];
}

-(FMDatabase *)getFMDB{
    NSString *dbPath = [self getDbPath];
    //    NSString *dbPath = @"/Users/yangwenjun/Desktop/LemonClean.db";
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    return db;
}

-(void)createPictureSimilarResultTable{
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"create table if not exists picture_similar_result ( group_path_md5 varchar(200) not null, source_path_md5 varchar(200) not null ,result_dictionary varchar(5000) not null)"];
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
//md5_key:由一个sourcepath生成 dateString：由所有的path生成
-(void)addNewResultWithSourcePathKey:(NSString *)sourcePath groupPathKey:(NSString *)groupPathKey dictionary:(NSString *) result_dictionary{
    FMDatabase *db = [self getFMDB];
    if([db open]){
        [db beginTransaction];
        BOOL result = [db executeUpdate:@"insert into picture_similar_result (source_path_md5, group_path_md5,result_dictionary) values (?, ?, ?)", sourcePath, groupPathKey, result_dictionary];
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

-(NSMutableArray *)getResultDictionaryWithKey:(NSMutableArray *) md5_keyArray{
    FMDatabase *db = [self getFMDB];
    NSMutableArray *result_Array = [NSMutableArray new];
    if([db open]){
        for (NSString *md5_key in md5_keyArray) {
            FMResultSet *resutSet = [db executeQuery:@"select * from picture_similar_result where source_path_md5 = ?",md5_key];
            while ([resutSet next]) {
                [result_Array addObject: [resutSet stringForColumn:@"result_dictionary"]];
            }
        }
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    
    return result_Array;
}

-(NSMutableArray *)getResultDictionaryArrayWithGroupPathKey:(NSString *) groupPathKey{
    FMDatabase *db = [self getFMDB];
    NSMutableArray *result_Array = [NSMutableArray new];
    if([db open]){
        FMResultSet *resutSet = [db executeQuery:@"select * from picture_similar_result where group_path_md5 = ?",groupPathKey];
        while ([resutSet next]) {
            [result_Array addObject: [resutSet stringForColumn:@"result_dictionary"]];
        }
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    
    return result_Array;
}

-(BOOL)isExistResultWithGroupPathKey:(NSString *) groupPathKey{
    FMDatabase *db = [self getFMDB];
    NSString *result_dictionary = [[NSString alloc]init];
    if([db open]){        
        FMResultSet *resutSet = [db executeQuery:@"select * from picture_similar_result where group_path_md5 = ?",groupPathKey];
        while ([resutSet next]) {
            result_dictionary = [resutSet stringForColumn:@"result_dictionary"];
        }
        
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    
    return result_dictionary.length > 0?TRUE:FALSE;
}

-(NSString *)getResultDictionaryByGroupPathKey: (NSString*)groupPathKey{
    FMDatabase *db = [self getFMDB];
    NSString *result_dictionary = [[NSString alloc]init];
    if([db open]){
        FMResultSet *resutSet = [db executeQuery:@"select * from picture_similar_result where group_path_md5 = ?",groupPathKey];
        while ([resutSet next]) {
            result_dictionary = [resutSet stringForColumn:@"result_dictionary"];
        }
        
        [db close];
    }else{
        NSLog(@"addNewRecord open db faild");
    }
    return result_dictionary;
}
@end
