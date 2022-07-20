/*
 *  DiskArbitrationPrivateFunctions.h
 *  DiskArbitrator
 *
 *  Created by Aaron Burghardt on 1/28/10.
 *  Copyright 2010 Aaron Burghardt. All rights reserved.
 *
 */

#import <DiskArbitration/DiskArbitration.h>
#import "Disk.h"

void InitializeDiskArbitration(void);
void UnregisterDiskCallback(void);
BOOL DADiskValidate(DADiskRef diskRef);
void DiskAppearedCallback(DADiskRef diskRef, void *context);
void DiskDisappearedCallback(DADiskRef diskRef, void *context);
void DiskDescriptionChangedCallback(DADiskRef diskRef, CFArrayRef keys, void *context);


@interface Disk (DiskPrivate)

+ (id)uniqueDiskForDADisk:(DADiskRef)diskRef create:(BOOL)create;

- (id)initWithDADisk:(DADiskRef)diskRef shouldCreateParent:(BOOL)shouldCreateParent;
- (void)refreshFromDescription;
- (void)diskDidDisappear;
@end

extern NSMutableSet *uniqueDisks;
