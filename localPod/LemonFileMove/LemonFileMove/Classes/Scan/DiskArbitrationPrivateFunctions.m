/*
 *  DiskArbitrationPrivateFunctions.m
 *  DiskArbitrator
 *
 *  Created by Aaron Burghardt on 1/28/10.
 *  Copyright 2010 Aaron Burghardt. All rights reserved.
 *
 */

#import "DiskArbitrationPrivateFunctions.h"
//#import "AppError.h"

// Globals
NSMutableSet *uniqueDisks;
DASessionRef session;
static BOOL isInitialized = NO;

void InitializeDiskArbitration(void)
{
    
    if (isInitialized) return;
    
    isInitialized = YES;
    
    uniqueDisks = [NSMutableSet new];
    
    session = DASessionCreate(kCFAllocatorDefault);
    if (!session) {
        [NSException raise:NSInternalInconsistencyException format:@"Failed to create Disk Arbitration session."];
        return;
    }
    
    DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    CFMutableDictionaryRef matching = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(matching, kDADiskDescriptionVolumeNetworkKey, kCFBooleanFalse);

    DARegisterDiskAppearedCallback(session, matching, DiskAppearedCallback, (__bridge void *)[Disk class]);
    DARegisterDiskDisappearedCallback(session, matching, DiskDisappearedCallback, (__bridge void *)[Disk class]);
    DARegisterDiskDescriptionChangedCallback(session, matching, NULL, DiskDescriptionChangedCallback,(__bridge void *)[Disk class]);

}

void UnregisterDiskCallback(void)
{
    isInitialized = NO;
    DAUnregisterCallback(session, DiskAppearedCallback, (__bridge void *)[Disk class]);
    DAUnregisterCallback(session, DiskDisappearedCallback, (__bridge void *)[Disk class]);
    DAUnregisterCallback(session, DiskDescriptionChangedCallback, (__bridge void *)[Disk class]);
    CFRelease(session);
}


BOOL DADiskValidate(DADiskRef diskRef)
{
    //
    // Reject certain disk media
    //
    
    BOOL isOK = YES;
    
    // Reject if no BSDName
    if (DADiskGetBSDName(diskRef) == NULL) {
//        [NSException raise:NSInternalInconsistencyException format:@"Disk without BSDName"];
        return NO;
    }
    
    CFDictionaryRef desc = DADiskCopyDescription(diskRef);
    //    CFShow(desc);
    
    // Reject if no key-value for Whole Media
    CFBooleanRef wholeMediaValue = CFDictionaryGetValue(desc, kDADiskDescriptionMediaWholeKey);
    if (isOK && !wholeMediaValue) isOK = NO;
        
        // If not a whole disk, then must be a media leaf
        if (isOK && CFBooleanGetValue(wholeMediaValue) == false)
        {
            CFBooleanRef mediaLeafValue = CFDictionaryGetValue(desc, kDADiskDescriptionMediaLeafKey);
            if (!mediaLeafValue || CFBooleanGetValue(mediaLeafValue) == false) isOK = NO;
        }
    
    return isOK;
}

void DiskAppearedCallback(DADiskRef diskRef, void *context)
{
    
    if (context != (__bridge void *)[Disk class]) return;
    
    if (DADiskValidate(diskRef))
    {
        Disk *disk = [Disk uniqueDiskForDADisk:diskRef create:YES];
        if (disk.isInternal == NO && disk.isWholeDisk == NO && disk.isDMG == NO) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DADiskDidAppearNotification object:disk];
        }
        
    }
}

void DiskDisappearedCallback(DADiskRef diskRef, void *context)
{
    if (context != (__bridge void *)[Disk class]) return;
    
    Disk *tmpDisk = [Disk uniqueDiskForDADisk:diskRef create:NO];
    if (!tmpDisk) {
        return;
    }
    if (tmpDisk.isInternal == NO && tmpDisk.isWholeDisk == NO && tmpDisk.isDMG == NO) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DADiskDidDisappearNotification object:tmpDisk];
        [tmpDisk diskDidDisappear];
    }
    
}

void DiskDescriptionChangedCallback(DADiskRef diskRef, CFArrayRef keys, void *context)
{
    if (context != (__bridge void *)[Disk class]) return;
    
    for (Disk *disk in uniqueDisks) {
        if (CFHash(diskRef)    == disk.hash) {
            CFDictionaryRef desc = DADiskCopyDescription(diskRef);
            disk.diskDescription = (__bridge_transfer NSDictionary *)desc;
            if (disk.isInternal == NO && disk.isWholeDisk == NO && disk.isDMG == NO) {
                [[NSNotificationCenter defaultCenter] postNotificationName:DADiskDidChangeNotification object:disk];
            }
        }
    }
}


NSString * const DADiskDidAppearNotification = @"DADiskDidAppearNotification";
NSString * const DADiskDidDisappearNotification = @"DADiskDidDisppearNotification";
NSString * const DADiskDidChangeNotification = @"DADiskDidChangeNotification";

NSString * const DAStatusErrorKey = @"DAStatusErrorKey";
