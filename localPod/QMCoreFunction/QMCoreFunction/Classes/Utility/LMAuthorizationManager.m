//
//  LMAuthorizationManager.m
//  QMCoreFunction
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMAuthorizationManager.h"
#import "NSString+Extension.h"
#import "QMShellExcuteHelper.h"
@implementation LMAuthorizationManager

+(PhotoAccessState)checkAuthorizationForAccessAlbum{
    NSString *photoPath = [NSString stringWithFormat:@"%@/Pictures/Photos Library.photoslibrary", [NSString getUserHomePath]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:photoPath];
    if(!isExist){
        photoPath = [NSString stringWithFormat:@"%@/Pictures/照片图库.photoslibrary",[NSString getUserHomePath]];
        isExist = [fileManager fileExistsAtPath:photoPath];
    }
    if(!isExist){
        return PhotoNotExist;
    }
    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:photoPath];
    if([dirEnum nextObject]){
        return PhotoAccessed;
    }
    return PhotoDenied;
}


+(Boolean)checkAuthorizationForCreateAlbum{
    NSString *fileName = [[NSUUID new] UUIDString];
    NSString* creatAlbum = [NSString stringWithFormat:@"tell application \"Photos\" \n"
                            "make new album named \"%@\" \n"
                            "return \"succeed\" \n"
                            "end tell",fileName];
    NSString* deleteAlbum = [NSString stringWithFormat:@"tell application \"Photos\" \n"
                             "delete album named \"%@\" \n"
                             "return \"succeed\" \n"
                             "end tell",fileName];
    NSAppleScript *script = [[NSAppleScript alloc]initWithSource:creatAlbum];
    NSDictionary *dict = nil;
    @try{
        NSAppleEventDescriptor *result = [script executeAndReturnError:&dict];
        if (dict || !result) {
            NSLog(@"checkAuthorizationForCreateAlbum_dict create error =%@", dict);
            return false;
        }else{
            script = [[NSAppleScript alloc]initWithSource:deleteAlbum];
            [script executeAndReturnError:&dict];
            NSLog(@"checkAuthorizationForCreateAlbum_dict_dict delete error =%@", dict);
            return true;
        }
    }
    @catch(NSException *exception){
        NSLog(@"checkAuthorizationForCreateAlbum_dict_dict addAlbumsWith exception = %@", exception);
        return false;
    }
    
}

+(void)openPrivacyAutomationPreference{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

+(void)openPrivacyPhotoPreference{
    NSURL *URL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

@end
