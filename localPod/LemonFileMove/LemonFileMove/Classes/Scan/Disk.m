//
//  Disk.m
//  DiskArbitrator
//
//  Created by Aaron Burghardt on 1/10/10.
//  Copyright 2010 Aaron Burghardt. All rights reserved.
//

#import "Disk.h"

#import <DiskArbitration/DiskArbitration.h>
#import "DiskArbitrationPrivateFunctions.h"
#import <IOKit/kext/KextManager.h>
#include <sys/param.h>
#include <sys/mount.h>



////////////////////////////////////////////////////////////////////////////////

@interface Disk ()
{
    CFTypeRef disk;
}

@end

////////////////////////////////////////////////////////////////////////////////

@implementation Disk

@synthesize diskDescription = _diskDescription;
@synthesize BSDName;
@synthesize isMounting;
@synthesize rejectedMount;
@synthesize icon;
@synthesize parent;
@synthesize children;
@synthesize mountArgs;
@synthesize mountPath;

+ (void)initialize
{
    InitializeDiskArbitration();
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqual:@"isMountable"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"isMounted"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"isEjectable"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"isWritable"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"isRemovable"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"isFileSystemWritable"])
        return [NSSet setWithObject:@"diskDescription"];

    if ([key isEqual:@"icon"])
        return [NSSet setWithObject:@"diskDescription"];

    return [super keyPathsForValuesAffectingValueForKey:key];
}

+ (id)uniqueDiskForDADisk:(DADiskRef)diskRef create:(BOOL)create
{
    for (Disk *disk in uniqueDisks) {
        if (disk.hash == CFHash(diskRef))
            return disk;
    }

    return create ? [[self.class alloc] initWithDADisk:diskRef shouldCreateParent:YES] : nil;
}

- (id)initWithDADisk:(DADiskRef)diskRef shouldCreateParent:(BOOL)shouldCreateParent
{
    NSAssert(diskRef, @"No Disk Arbitration disk provided to initializer.");
    
    self = [super init];

    // Return unique instance
    Disk *uniqueDisk = [Disk uniqueDiskForDADisk:diskRef create:NO];
    if (uniqueDisk) {
        return uniqueDisk;
    }
    
    if (self)
    {
        disk = CFRetain(diskRef);
        const char *bsdName = DADiskGetBSDName(diskRef);
        BSDName = [[NSString alloc] initWithUTF8String:bsdName ? bsdName : ""];
        children = [NSMutableSet new];
        _diskDescription = (__bridge_transfer NSDictionary *)DADiskCopyDescription(diskRef);

        if (self.isWholeDisk == NO)
        {
            DADiskRef parentRef = DADiskCopyWholeDisk(diskRef);
            if (parentRef)
            {
                Disk *parentDisk = [Disk uniqueDiskForDADisk:parentRef create:shouldCreateParent];
                if (parentDisk)
                {
                    parent = parentDisk; // weak reference
                    [[parent mutableSetValueForKey:@"children"] addObject:self];
                }
            }
        }
        [uniqueDisks addObject:self];
    }
    return self;
}

- (void)dealloc {

}

- (NSUInteger)hash
{
    return CFHash(disk);
}

- (BOOL)isEqual:(id)object
{
    return (CFHash(disk) == [object hash]);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, 0x%p, BSDName=%@, mounting=%@, mounted=%@, rejectedMount=%@, parentName=%@, childrenCount=%lu, mountArgs=%@, mountPath=%@, desc=%@ >",
            self.class,
            self,
            self.BSDName,
            self.isMounting ? @"yes" : @"no",
            self.isMounted ? @"yes" : @"no",
            self.rejectedMount ? @"yes" : @"no",
            self.parent.BSDName,
            (unsigned long)self.children.count,
            self.mountArgs,
            self.mountPath,
            self.diskDescription
    ];
}

- (void)diskDidDisappear
{
    [uniqueDisks removeObject:self];
    [[parent mutableSetValueForKey:@"children"] removeObject:self];

    disk = NULL;

    self.parent = nil;
    [children removeAllObjects];
    
    self.rejectedMount = NO;
    self.mountArgs = [NSArray array];
    self.mountPath = nil;
}

- (BOOL)isMountable
{

    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionVolumeMountableKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isMounted
{
    CFStringRef value = self.diskDescription ?
        (__bridge_retained CFStringRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionVolumePathKey] : NULL;
    
    return value ? YES : NO;
}

- (BOOL)isWholeDisk
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionMediaWholeKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isLeaf
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionMediaLeafKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isNetworkVolume
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionVolumeNetworkKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isWritable
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionMediaWritableKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isEjectable
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionMediaEjectableKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isRemovable
{
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionMediaRemovableKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}


- (BOOL)isHFS
{
    CFStringRef volumeKind = self.diskDescription ?
        (__bridge_retained CFStringRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionVolumeKindKey] : NULL;
    return volumeKind ? CFEqual(CFSTR("hfs"), volumeKind) : NO;
}

- (BOOL)isFileSystemWritable
{
    BOOL retval = NO;
    struct statfs fsstat;
    CFURLRef volumePath;
    UInt8 fsrep[MAXPATHLEN];

    // if the media is not writable, the file system cannot be either
    if (self.isWritable == NO)
        return NO;

    volumePath = (__bridge_retained CFURLRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionVolumePathKey];
    if (volumePath) {

        if (CFURLGetFileSystemRepresentation(volumePath, true, fsrep, sizeof(fsrep))) {

            if (statfs((char *)fsrep, &fsstat) == 0)
                retval = (fsstat.f_flags & MNT_RDONLY) ? NO : YES;
        }
    }

    return retval;
}

- (BOOL)isInternal {
    CFBooleanRef value = self.diskDescription ?
        (__bridge_retained CFBooleanRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionDeviceInternalKey] : NULL;
    return value ? CFBooleanGetValue(value) : NO;
}

- (BOOL)isDMG {
    CFStringRef deviceModel = self.diskDescription ?
        (__bridge_retained CFStringRef)[self.diskDescription objectForKey:(__bridge_transfer NSString *)kDADiskDescriptionDeviceModelKey] : NULL;
    return deviceModel ? CFEqual(CFSTR("Disk Image"), deviceModel) : NO;
}

- (void)setDiskDescription:(NSDictionary *)desc
{
    NSAssert(desc, @"A NULL disk description is not allowed.");
    
    if (desc != _diskDescription)
    {
        [self willChangeValueForKey:@"diskDescription"];

        _diskDescription = desc ? [desc copy]: nil;

        [self didChangeValueForKey:@"diskDescription"];
    }
}

- (NSImage *)icon
{
    if (!icon)
    {
        if (self.diskDescription)
        {
            CFDictionaryRef iconRef = (__bridge_retained CFDictionaryRef)[self.diskDescription
                objectForKey:(NSString *)kDADiskDescriptionMediaIconKey];
            if (iconRef)
            {

                CFStringRef identifier = CFDictionaryGetValue(iconRef, CFSTR("CFBundleIdentifier"));
                NSURL *url = (__bridge_transfer NSURL *)KextManagerCreateURLForBundleIdentifier(kCFAllocatorDefault, identifier);
                if (url) {
                    NSString *bundlePath = [url path];

                    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
                    if (bundle) {
                        NSString *filename = (NSString *) CFDictionaryGetValue(iconRef, CFSTR("IOBundleResourceFile"));
                        NSString *basename = [filename stringByDeletingPathExtension];
                        NSString *fileext =  [filename pathExtension];

                        NSString *path = [bundle pathForResource:basename ofType:fileext];
                        if (path) {
                            icon = [[NSImage alloc] initWithContentsOfFile:path];
                        }
                    }
                    else {
                        NSLog(@"Failed to load bundle with URL: %@", [url absoluteString]);
                    }
                }
                else {
                    NSLog(@"Failed to create URL for bundle identifier: %@", (__bridge_transfer NSString *)identifier);
                }
            }
        }
    }
    
    return icon;
}

- (int)BSDNameNumber
{
    // Take the BSDName and convert it into a number that can be compared with other disks for sorting.
    // For example, "disk2s1" would become 2 * 1000 + 1 = 2001.
    // If we just compare by the string value itself, then disk10 would come after disk1, instead of disk9.
    NSString *s = self.BSDName;
    int device = 0;
    int slice = 0;
    const int found = sscanf(s.UTF8String, "disk%ds%d", &device, &slice);
    if (found == 0 || device < 0 || slice < 0) {
        NSLog(@"Invalid BSD Name %@", s);
    }
    return (device * 1000) + slice;
}

@end
