			//
//  QMMailScan.m
//  LemonClener
//

//  Copyright © 2018 Tencent. All rights reserved.
//

#import "QMMailUtil.h"

@implementation QMMailUtil


//  关于 download 目录和 attachment目录保存的内容.

//测试了下:(基于10.13.6的 mac os)
// attachment 目录
// mail 中带附件, 点击附件自动下载到~/Library/Mail/V5/3F887B96-AF7A-42A7-8C1C-20D7D6053692/Drafts.mbox/4EFA8E78-9A9C-4530-9BD2-84E3F78560A4/Data/7/Attachments/7445/1/xxxx附件
// mail 中带图片, 邮件展示的时候, 图片会自动下载到类似如上的目录.

// download 目录
// 在 mail 中的附件/图片 上右键菜单,点击  "save to Download Folder" 图片/附件 会保存在~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads 目录.


// 返回array 中的 item 有可能是文件夹
// Users/apple/Library/Containers/com.apple.mail/Data/Library/Mail Downloads
+(NSArray *) getMailDownloadFilePathArray:(NSString *) mailDownloadPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL downloadExist = [fileManager fileExistsAtPath:mailDownloadPath];
    if(!downloadExist){
        return nil;
    }
    NSError *error = nil;
    NSArray *contentsArray = [fileManager contentsOfDirectoryAtPath:mailDownloadPath error:&error];
    
    if(error){
        return nil;
    }
    
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    for(NSString *itemName in contentsArray){
        [returnArray addObject:[mailDownloadPath stringByAppendingPathComponent:itemName]];
    }
    return returnArray;
}

//mail attachments
// mailPath: "~/Library/Mail"
+(NSArray *) getMailAttachMentPathArray:(NSString *)mailPath withDelegate:(id<QMMailDelegate>) mailDelegate{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL mailExist = [fileManager fileExistsAtPath:mailPath];
    if(!mailExist){
        return nil;
    }
    
    NSString *mailPlistPath = [mailPath stringByAppendingPathComponent:@"/PersistenceInfo.plist"];
    BOOL mailPlistExist = [fileManager fileExistsAtPath:mailPlistPath];
    if(!mailPlistExist){
        return nil;
    }
    
    NSString *lastVersionName;
    NSDictionary *mailDict = [NSDictionary dictionaryWithContentsOfFile:mailPlistPath];
    if(mailDict){
       lastVersionName = mailDict[@"LastUsedVersionDirectoryName"];
    }
    
    if(!lastVersionName){
        return nil;
    }
    
    NSString *mailVersionPath = [mailPath stringByAppendingPathComponent:lastVersionName];
    BOOL mailVersionExist = [fileManager fileExistsAtPath:mailVersionPath];
    if(!mailVersionExist){
        return nil;
    }
    
    NSArray *subMailPathArry = [self getMailBoxPathArrayWithPath:mailVersionPath];
    if(!subMailPathArry){
        return nil;
    }
    
    NSMutableArray *attachments = [[NSMutableArray alloc] init];
    
    NSUInteger mailBoxNum = subMailPathArry.count;
    double index = 0;
    // 没有单独判断时 普通文件(非文件的 key) 只能曲线救国
    NSArray *keys = @[NSURLNameKey, NSURLIsDirectoryKey];
    for (NSString *mboxPath in subMailPathArry){
        NSURL *itemUrl = [[NSURL alloc] initFileURLWithPath:mboxPath];
        NSDirectoryEnumerator *dirEum = [fileManager enumeratorAtURL:itemUrl includingPropertiesForKeys:keys options:0 errorHandler:nil];
        
        NSMutableArray *subResultArray = [[NSMutableArray alloc]init];
        for (NSURL *url in dirEum){
            NSArray *itemUrlPathComponents = [url pathComponents];
            
             // 过滤掉文件夹
            NSNumber *isDirectory;
            [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
            if ([isDirectory boolValue]) {
                continue;
            }
            
            // 过滤掉隐藏文件 特别是 .DS_Store 应该忽略掉
            NSNumber *isHidden;
            [url getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:NULL];
            if ([isHidden boolValue]) {
                continue;
            }
            
            if([itemUrlPathComponents containsObject:@"Attachments"] ){
                [subResultArray addObject:url.path];
                [attachments addObject:url.path];
            }
        }
        
        index += 1;
        if(mailDelegate) [mailDelegate mailScanProcess: index/(double)mailBoxNum path:itemUrl.path pathResult:subResultArray];

    }
    
    NSLog(@"getMailAttachMentPathArray result is %@", attachments);
    return attachments;
}

// 没有按照邮箱去分类
+ (NSArray *)getMailBoxPathArrayWithPath:(NSString *)mailVersionPath{
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // fileManager contentsOfDirectoryAtPath返回的只是子文件的名字(不包含完整路径)
    NSArray *contentNameArray = [fileManager contentsOfDirectoryAtPath:mailVersionPath error:&error];
    
    if(error){
        NSLog(@"getSubMailPathArrayWithPath : can't get contens with  path: %@",mailVersionPath);
        return nil;
    }
    
    if(!contentNameArray){
        return nil;
    }
    
    NSMutableArray *subMailPaths = [[NSMutableArray alloc]init];
    for(NSString *itemName in contentNameArray){
        if([itemName isEqualToString:@"MailData"]){
            continue;
        }
        
        NSString *itemFullPath = [mailVersionPath stringByAppendingPathComponent:itemName];
        NSError *itemListError = nil;
        NSArray *itemContentNameArray = [fileManager contentsOfDirectoryAtPath:itemFullPath error:&itemListError];
        if(itemListError && itemContentNameArray == nil){
            continue;
        }
        
        for(NSString *mBoxName in itemContentNameArray){
            NSString *mboxFullPath = [itemFullPath stringByAppendingPathComponent:mBoxName];
            
            // Users/apple/Library/Mail/V5/3F887B96-AF7A-42A7-8C1C-20D7D6053692/Deleted Messages.mbox
            // NSURL will return nil for URLs that contain illegal chars, like spaces.
            NSURL *mBoxUrl = [[NSURL alloc]initFileURLWithPath:mboxFullPath];
            if(!mBoxUrl){
                continue;
            }
            if([[mBoxUrl pathExtension]caseInsensitiveCompare:@"mbox"] == NSOrderedSame ){
                NSLog(@"mBoxUrl is %@", [mBoxUrl path]);
                [subMailPaths addObject: [mBoxUrl path]];
            }
        }
        
    }

    return subMailPaths;
}

@end
