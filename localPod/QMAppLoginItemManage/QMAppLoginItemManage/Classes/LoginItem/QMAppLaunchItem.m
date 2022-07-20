//
//  LMAppLaunchItem.m
//  LemonGroup
//
//  
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "QMAppLaunchItem.h"

///launch service item
@implementation QMAppLaunchItem

- (instancetype)initWithLaunchFilePath:(NSString *)path
{
    return [self initWithAppPath:path loginItemType:LoginItemTypeSystemItem];
}

- (instancetype)initWithLaunchFilePath:(NSString *)path itemType:(LoginItemType)itemType
{
    self = [super init];
    if (self) {
        self.filePath = path;
        self.fileName = [self.filePath lastPathComponent];
        self.loginItemType = itemType;
        [self setDomainTypeWithPath:path];
    }
    return self;
}

- (void)setDomainTypeWithPath:(NSString *)path {
    if([path containsString:@"/Library/LaunchDaemons"]){
        self.domainType = LaunchServiceDomainTypeSystem;
    }else{
        self.domainType = LaunchServiceDomainTypeUser;
    }
}

@end
