//
//  McDiskInfo.m
//  TestFunction
//
//  Created by developer on 11-1-25.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CmcDisk.h"
#import "McSystem.h"
#import "McDiskInfo.h"
#import "McLogUtil.h"

@implementation McVolumeInfo

@synthesize devName;
@synthesize volName;
@synthesize icnsPath;
@synthesize kindName;
@synthesize volPath;
@synthesize freeBytes;
@synthesize totalBytes;
@synthesize ejectable;
@synthesize internalDevice;
@synthesize networkDevice;
@synthesize writeble;

- (id) init
{
    if (self = [super init])
    {
        devName = @"";
        volName = @"";
        icnsPath = @"";
        kindName = @"";
        volPath = @"";
        freeBytes = 0;
        totalBytes = 0;
        ejectable = NO;
        internalDevice = NO;
        networkDevice = NO;
        writeble = YES;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:devName forKey:@"devName"];
    [encoder encodeObject:volName forKey:@"volName"];
    [encoder encodeObject:icnsPath forKey:@"icnsPath"];
    [encoder encodeObject:kindName forKey:@"kindName"];
    [encoder encodeObject:volPath forKey:@"volPath"];
    [encoder encodeInt64:freeBytes forKey:@"freeBytes"];
    [encoder encodeInt64:totalBytes forKey:@"totalBytes"];
    [encoder encodeBool:ejectable forKey:@"ejectable"];
    [encoder encodeBool:internalDevice forKey:@"internalDevice"];
    [encoder encodeBool:networkDevice forKey:@"networkDevice"];
}
- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super init];
    if (self != nil)
    {
        devName = [aCoder decodeObjectForKey:@"devName"];
        volName = [aCoder decodeObjectForKey:@"volName"];
        icnsPath = [aCoder decodeObjectForKey:@"icnsPath"];
        kindName = [aCoder decodeObjectForKey:@"kindName"];
        volPath = [aCoder decodeObjectForKey:@"volPath"];
        freeBytes = [aCoder decodeInt64ForKey:@"freeBytes"];
        totalBytes = [aCoder decodeInt64ForKey:@"totalBytes"];
        ejectable = [aCoder decodeBoolForKey:@"ejectable"];
        internalDevice = [aCoder decodeBoolForKey:@"internalDevice"];
        networkDevice = [aCoder decodeBoolForKey:@"networkDevice"];
        //str = [aCoder decodeObjectForKey:@"str"];
    }
    return self;
}

@end

@implementation McDiskInfo

// properties
@synthesize bytesRead;
@synthesize bytesWrite;

- (id) init
{
    if (self = [super init])
    {
        lastUpdateTime = 0.0;
        bytesRead = nil;
        bytesWrite = nil;
        volumesDic = [NSMutableDictionary dictionaryWithCapacity:10];
        
        // update values
        [self UpdateDiskReadWriteBytes];
    }
    
    return self;
}


- (NSString *) description
{
    NSString *descStr = [NSString stringWithFormat:@"McDiskInfo class"];
    return descStr;
}

// get device name and volume name
- (NSArray *) GetVolumesInformation
{
    NSMutableArray *volumesArray = [NSMutableArray arrayWithCapacity:10];
    
    const int name_len = 300;
    char dev_name[name_len] = {0};
    char vol_name[name_len] = {0};
    char icns_path[name_len] = {0};
    char kind_name[name_len] = {0};
    uint64_t total = 0;
    uint64_t free = 0;
    
    // enum all possible paths
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *volumeRoot = @"/Volumes";
    NSArray *volumeNames = [fileMgr contentsOfDirectoryAtPath:volumeRoot error:nil];
    NSString *volumePath;
    McVolumeInfo *volumeInfo;
    for (NSString *name in volumeNames)
    {
        if ([name characterAtIndex:0] == '.')
            continue;
        
        // filter /Volumes/MobileBackups
        if ([name isEqualToString:@"MobileBackups"])
            continue;
        
        free = 0;
        total = 0;
        // already got information
        volumeInfo = [volumesDic objectForKey:name];
        if (volumeInfo != nil)
        {
            // only refresh free size
            //            if (CmcGetFsStat([volumeInfo.volPath fileSystemRepresentation], &free, &total) == 0)
            if (CmcGetFsStatByFM(volumeInfo.volPath, &free, &total) == 0)
            {
                volumeInfo.freeBytes = free;
                volumeInfo.totalBytes = total;
            }
            [volumesArray addObject:volumeInfo];
            continue;
        }
        
        volumeInfo = [[McVolumeInfo alloc] init];
        volumePath = [volumeRoot stringByAppendingPathComponent:name];
        
        // get bytes
        //        if (CmcGetFsStat([volumePath fileSystemRepresentation], &free, &total) == 0)
        if (CmcGetFsStatByFM(volumePath, &free, &total) == 0)
        {
            volumeInfo.freeBytes = free;
            volumeInfo.totalBytes = total;
        }
        
        // default values
        Boolean isEjectable = true;
        Boolean isNetwork = false;
        Boolean isInternal = false;
        Boolean isWriteable = true;
        memset(dev_name, 0, name_len);
        memset(vol_name, 0, name_len);
        memset(icns_path, 0, name_len);
        memset(kind_name, 0, name_len);
        // get root path device
        if (CmcGetDiskDescr([volumePath fileSystemRepresentation],
                            dev_name,
                            vol_name,
                            icns_path,
                            kind_name,
                            name_len,
                            &isEjectable,
                            &isInternal,
                            &isNetwork,
                            &isWriteable) == 0)
        {
            volumeInfo.volPath = [volumePath copy];
            volumeInfo.devName = [NSString stringWithUTF8String:dev_name];
            volumeInfo.volName = [NSString stringWithUTF8String:vol_name];
            volumeInfo.icnsPath = [NSString stringWithUTF8String:icns_path];
            volumeInfo.kindName = [NSString stringWithUTF8String:kind_name];
            volumeInfo.ejectable = isEjectable;
            volumeInfo.internalDevice = isInternal;
            volumeInfo.networkDevice = isNetwork;
            volumeInfo.writeble = isWriteable;
            
            // Disk Image
            if ([volumeInfo.devName isEqualToString:@"Disk Image"])
            {
                NSString *diskIcnsFile = [volumePath stringByAppendingPathComponent:@".VolumeIcon.icns"];
                if ([fileMgr fileExistsAtPath:diskIcnsFile])
                {
                    // actual icns file
                    volumeInfo.icnsPath = diskIcnsFile;
                }
            }
            
            // remember what we have got
            [volumesDic setObject:volumeInfo forKey:name];
            [volumesArray addObject:volumeInfo];
        }
    }
    
    return volumesArray;
}

// update disk read and write bytes information
- (BOOL) UpdateDiskReadWriteBytes
{
    uint64_t read;
    uint64_t write;
    
    if (CmcGetDiskReadWriteBytes(&read, &write) == -1)
        return NO;
    
    // record last update time
    lastUpdateTime = McGetAbsoluteNanosec()/(1000*1000*1000);
    
    bytesRead = [NSNumber numberWithUnsignedLongLong:read];
    
    bytesWrite = [NSNumber numberWithUnsignedLongLong:write];
    
    return YES;
}

// get speed (B/s)
// index 0:read 1:write
- (NSArray *) GetDiskReadWriteSpeed
{
    if (bytesRead == nil || bytesWrite == nil)
    {
        return nil;
    }
    
    uint64_t oldBytesRead = [bytesRead unsignedLongLongValue];
    uint64_t oldBytesWrite = [bytesWrite unsignedLongLongValue];
    double oldUpdateTime = lastUpdateTime;
    
    if (![self UpdateDiskReadWriteBytes])
        return nil;
    
    // maybe one disk is reject, than current bytes may become smaller
    double readSpeed = 0.0;
    if ([bytesRead unsignedLongLongValue] > oldBytesRead
        && lastUpdateTime > oldUpdateTime)
    {
        readSpeed = ([bytesRead unsignedLongLongValue] - oldBytesRead) / (lastUpdateTime - oldUpdateTime);
    }
    double writeSpeed = 0.0;
    if ([bytesWrite unsignedLongLongValue] > oldBytesWrite
        && lastUpdateTime > oldUpdateTime)
    {
        writeSpeed = ([bytesWrite unsignedLongLongValue] - oldBytesWrite) / (lastUpdateTime - oldUpdateTime);
    }
    
    return ([NSArray arrayWithObjects:
             [NSNumber numberWithDouble:readSpeed],
             [NSNumber numberWithDouble:writeSpeed],
             nil]);
}

@end
