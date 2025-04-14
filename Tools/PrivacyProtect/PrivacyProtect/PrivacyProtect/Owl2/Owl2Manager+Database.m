//
//  Owl2Manager+Database.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "Owl2Manager+Database.h"
#import "OwlConstant.h"

@implementation Owl2Manager (Database)

- (void)createBlockTable
{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, %@ text NOT NULL);", OwlProBlockTable, OwlExecutableName]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_block table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}

- (void)createProfileTable
{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, %@ integer DEFAULT 0, %@ integer DEFAULT 0);", OwlProcProfileTable, OwlWatchCamera, OwlWatchAudio]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_profile table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}

- (void)createLogTable
{
    BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer PRIMARY KEY AUTOINCREMENT, time text NOT NULL, %@ text NOT NULL,  event text NOT NULL);", OwlProcLogTable, OwlAppName]];
    if (result)
    {
        
    } else {
        NSLog(@"Error owl create proc_log table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}

- (void)createWhiteAppTable
{
    NSString *strSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text NOT NULL, %@ text NOT NULL, %@ text NOT NULL, %@ text PRIMARY KEY NOT NULL, %@ text NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
    BOOL result = [db executeUpdate:strSQL];
    if (result)
    {
    } else {
        NSLog(@"Error owl create app_white table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
}

- (void)loadDB
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *home = NSHomeDirectory();
    NSString *support = [home stringByAppendingPathComponent:@"Library/Application Support/com.tencent.lemon/Owl"];
    dbPath = [support stringByAppendingPathComponent:@"owl.db"];
    if (![fm fileExistsAtPath:support]){
        NSError *error = nil;
        if (![fm createDirectoryAtPath:support withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"create owl support path fail");
        }
    }
    if (![fm fileExistsAtPath:dbPath]) {
        db = [FMDatabase databaseWithPath:dbPath];
        if ([db open])
        {
            [self createLogTable];
            [self createBlockTable];
            [self createProfileTable];
            
            NSString *strSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ text NOT NULL, %@ text NOT NULL, %@ text NOT NULL, %@ text PRIMARY KEY NOT NULL, %@ text NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL, %@ integer NOT NULL);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
            BOOL result = [db executeUpdate:strSQL];
            if (result)
            {
                NSString *appsPath = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)[0];
                NSError *error = nil;
                for (NSString *name in [fm contentsOfDirectoryAtPath:appsPath error:&error]) {
                    if ([[name pathExtension] isEqualToString:@"app"]) {
                        if ([name isEqualToString:@"Siri.app"] ||
                            [name isEqualToString:@"Photo Booth.app"] ||
                            [name isEqualToString:@"FaceTime.app"]) {
                            [self addAppWhiteItem:[self getAppInfoWithPath:appsPath appName:name]];
                        } else {
                            //[self getAppInfoWithPath:appsPath appName:name];
                        }
                    }
                }
                //[db executeUpdate:@"INSERT INTO t_student (appName,executableName,bubblePath,identifier,appIcon,appleApp) VALUES  (?,?,?,?,?,?);" withArgumentsInArray:_wlArray];
            } else {
                NSLog(@"Error owl create app_white table fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        } else {
            NSLog(@"Error owl open db fail %d: %@  path:%@", [db lastErrorCode], [db lastErrorMessage], dbPath);
        }
    } else {
        db = [FMDatabase databaseWithPath:dbPath];
        if ([db open])
        {
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlAppWhiteTable]];
            NSLog(@"[resultSet columnCount]: %d", [resultSet columnCount]);
            NSLog(@"columnNameToIndexMap: %@", [[resultSet columnNameToIndexMap] allKeys]);
            BOOL hasOwlWatchCameraAndAudio = NO;
            if ([[[resultSet columnNameToIndexMap] allKeys] containsObject:OwlWatchCamera] ||
                [[[resultSet columnNameToIndexMap] allKeys] containsObject:[OwlWatchCamera lowercaseString]]) {
                hasOwlWatchCameraAndAudio = YES;
            } else {
            }
            //NSLog(@"_wlArray: %@", _wlArray);
            while ([resultSet  next])
            {
                if (resultSet &&
                    [resultSet objectForColumn:OwlAppName] &&
                    [resultSet objectForColumn:OwlExecutableName] &&
                    [resultSet objectForColumn:OwlBubblePath] &&
                    [resultSet objectForColumn:OwlIdentifier] &&
                    [resultSet objectForColumn:OwlAppIcon]) {
                    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] initWithCapacity:8];
                    [appDic setObject:[resultSet objectForColumn:OwlAppName] forKey:OwlAppName];
                    [appDic setObject:[resultSet objectForColumn:OwlExecutableName] forKey:OwlExecutableName];
                    [appDic setObject:[resultSet objectForColumn:OwlBubblePath] forKey:OwlBubblePath];
                    [appDic setObject:[resultSet objectForColumn:OwlIdentifier] forKey:OwlIdentifier];
                    [appDic setObject:[resultSet objectForColumn:OwlAppIcon] forKey:OwlAppIcon];
                    if ([resultSet intForColumn:OwlAppleApp]) {
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlAppleApp]] forKey:OwlAppleApp];
                    } else {
                        [appDic setObject:[NSNumber numberWithInt:0] forKey:OwlAppleApp];
                    }
                    //NSLog(@"hasOwlWatchCameraAndAudio: %d, %d, %d", hasOwlWatchCameraAndAudio, [resultSet intForColumn:OwlWatchCamera], [resultSet intForColumn:OwlWatchAudio]);
                    if (hasOwlWatchCameraAndAudio) {
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlWatchCamera]] forKey:OwlWatchCamera];
                        [appDic setObject:[NSNumber numberWithInt:[resultSet intForColumn:OwlWatchAudio]] forKey:OwlWatchAudio];
                    } else {
                        [appDic setObject:[NSNumber numberWithInt:1] forKey:OwlWatchCamera];
                        [appDic setObject:[NSNumber numberWithInt:1] forKey:OwlWatchAudio];
                    }
                    BOOL isExist = NO;
                    for (NSDictionary *dic in self.wlArray) {
                        if ([[dic objectForKey:OwlIdentifier] isEqualToString:[resultSet objectForColumn:OwlIdentifier]]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [self.wlArray addObject:appDic];
                    }
                }
            }
            if (!hasOwlWatchCameraAndAudio) {
                [db executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", OwlAppWhiteTable]];
                [self createWhiteAppTable];
                [self resaveWhiteList];
            }
            //NSLog(@"_wlArray: %@", _wlArray);
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createWhiteAppTable];
            }
            
            FMResultSet *resultSetLog = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProcLogTable]];
            while ([resultSetLog  next])
            {
                if (resultSetLog &&
                    [resultSetLog objectForColumn:@"time"] &&
                    [resultSetLog objectForColumn:@"event"] &&
                    [resultSetLog objectForColumn:OwlAppName]) {
                    NSMutableDictionary *appDic = [[NSMutableDictionary alloc] initWithCapacity:3];
                    [appDic setObject:[resultSetLog objectForColumn:@"time"] forKey:@"time"];
                    [appDic setObject:[resultSetLog objectForColumn:@"event"] forKey:@"event"];
                    [appDic setObject:[resultSetLog objectForColumn:OwlAppName] forKey:OwlAppName];
                    [self.logArray addObject:appDic];
                }
            }
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createLogTable];
            }
            [self resortLogArray];
            
            FMResultSet *resultProfile = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProcProfileTable]];
            int iprofile = 0;
            while ([resultProfile  next])
            {
                if (iprofile == 0) {
                    self.isWatchVideo = [resultProfile intForColumn:OwlWatchCamera];
                    self.isWatchAudio = [resultProfile intForColumn:OwlWatchAudio];
                }
                iprofile++;
            }
            //兼容历史数据，删除多余的row
            if (iprofile > 1) {
                [db executeUpdate:[NSString stringWithFormat:@"delete from %@", OwlProcProfileTable]];
                NSString *strSQL = [NSString stringWithFormat:@"INSERT INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
                [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:self.isWatchVideo], [NSNumber numberWithInt:self.isWatchAudio]];
            }
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createProfileTable];
            }
            
            [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlProBlockTable]];
            if ([db hadError]) {
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                [self createBlockTable];
            }
        } else {
            NSLog(@"Error owl open db fail %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }
}

- (void)closeDB
{
    if (db) {
        [db close];
        db = nil;
    }
}

- (void)resortLogArray
{
    NSArray *tmpLogArray = [self.logArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[obj2 objectForKey:@"time"] compare:((NSString *)[obj1 objectForKey:@"time"])];
    }];
    self.logArray = [NSMutableArray arrayWithArray:tmpLogArray];
}

- (void)addLogItem:(NSString*)log appName:(NSString*)appName
{
    NSLog(@"addVedioLogItem: %@", log);
    NSDate * currentDate = [NSDate date];
    NSDateFormatter * df = [[NSDateFormatter alloc] init ];
    [df setDateFormat:@"yyyy.MM.dd  HH:mm:ss"];
    NSString *na = [df stringFromDate:currentDate];
    [self.logArray addObject:@{@"time": na, OwlAppName:appName, @"event": log}];
    [self resortLogArray];
    
    [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (time,%@,event) VALUES  (?,?,?);", OwlProcLogTable, OwlAppName], na,appName,log];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OwlLogChangeNotication object:nil];
    });
}

- (void)setWatchVedioToDB:(BOOL)state
{
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
    //这里要传oc对象类型，不支持传基础数据类型
    [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:self.isWatchVideo], [NSNumber numberWithInt:self.isWatchAudio]];
//    [db executeUpdate:strSQL, _isWatchVedio ? 1 : 0, _isWatchAudio ? 1 : 0];
//    [db executeUpdate:strSQL, @"1", @"0"];
}

- (void)setWatchAudioToDB:(BOOL)state
{
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@) VALUES  (?,?,?);", OwlProcProfileTable, @"id", OwlWatchCamera, OwlWatchAudio];
    [db executeUpdate:strSQL, [NSNumber numberWithInt:1], [NSNumber numberWithInt:self.isWatchVideo], [NSNumber numberWithInt:self.isWatchAudio]];
}

- (void)addAppWhiteItemToDB:(NSDictionary*)dic
{
//    FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@", OwlAppWhiteTable]];
//    NSLog(@"[resultSet columnCount]: %d", [resultSet columnCount]);
//    NSLog(@"columnNameToIndexMap: %@", [resultSet columnNameToIndexMap]);
//    BOOL hasNewOwlWatchCamera = YES;
//    if (![[[resultSet columnNameToIndexMap] allKeys] containsObject:OwlWatchCamera]) {
//        hasNewOwlWatchCamera = NO;
//    }
    NSString *strSQL = [NSString stringWithFormat:@"REPLACE INTO %@ (%@,%@,%@,%@,%@,%@,%@,%@) VALUES  (?,?,?,?,?,?,?,?);", OwlAppWhiteTable, OwlAppName, OwlExecutableName, OwlBubblePath, OwlIdentifier, OwlAppIcon, OwlAppleApp, OwlWatchCamera, OwlWatchAudio];
    [db executeUpdate:strSQL, [dic objectForKey:OwlAppName],[dic objectForKey:OwlExecutableName],[dic objectForKey:OwlBubblePath],[dic objectForKey:OwlIdentifier],[dic objectForKey:OwlAppIcon],[dic objectForKey:OwlAppleApp],[dic objectForKey:OwlWatchCamera],[dic objectForKey:OwlWatchAudio]];
}

- (void)resaveWhiteListToDB
{
    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@", OwlAppWhiteTable]];
    for (NSDictionary *dic in self.wlArray) {
        [self addAppWhiteItemToDB:dic];
    }
}

- (void)removeAppWhiteItemToDB:(NSDictionary*)dic
{
    [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", OwlAppWhiteTable, OwlIdentifier], [dic objectForKey:OwlIdentifier]];
}

@end
