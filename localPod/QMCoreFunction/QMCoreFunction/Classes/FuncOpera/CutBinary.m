//
//  CutBinary.m
//  libcleaner
//
//  Created by developer on 9/7/11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "CutBinary.h"
#import <mach-o/fat.h>
#import <libkern/OSByteOrder.h>

#define MAX_FAT_HEADER_SIZE (20*20)

// test if there are useless architecture data contained in the file
uint64_t testFileArch(const char *path)
{
    int size_to_read = MAX_FAT_HEADER_SIZE;
    char buffer[MAX_FAT_HEADER_SIZE] = {0};
    
    if (path == nil || path[0] == '\0') {
        return 0;
    }
    
    // read header of file
    int file = open(path, O_RDONLY);
    if (file == -1)
    {
        return 0;
    }
    if (read(file, buffer, size_to_read) == -1)
    {
        close(file);
        return 0;
    }
    close(file);
    
    // analyze fat header
    struct fat_header *pheader = (struct fat_header *)buffer;
    if (pheader->magic != FAT_CIGAM)
    {
        // not a fat file
        return 0;
    }
    
    int arch_count = OSSwapInt32(pheader->nfat_arch);
    if (arch_count <= 1 || arch_count >= 10)
    {
        return 0;
    }
    
    // loop all arch
    struct fat_arch *arch = (struct fat_arch *)(pheader + 1);
    uint64_t useless_size = 0;
    int useless_count = 0;
    for (int i = 0; i < arch_count; i++)
    {
        int cputype = OSSwapInt32(arch->cputype);
        if (cputype != CPU_TYPE_I386 && cputype != CPU_TYPE_X86_64)
        {
            // find useless arch
            useless_size += OSSwapInt32(arch->size);
            useless_count++;
            
            //            printf("[FD] arch: %x size: %x file: %s\n",
            //                   cputype, OSSwapInt32(arch->size), path);
        }
        
        arch++;
    }
    
    if (useless_count == arch_count)
    {
        // can't be all useless
        return 0;
    }
    
    // no architecture could be cut
    return  useless_size;
}

// clean useless architecture from file
BOOL removeFileArch(NSString *filePath)
{
    if (filePath == nil) {
        return NO;
    }
    
    // check first?
    if (testFileArch([filePath fileSystemRepresentation]) == 0)
    {
        NSLog(@"[ERR] no arch to cut: %@", filePath);
        return NO;
    }
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSData *fileData = [fileMgr contentsAtPath:filePath];
    if (fileData == nil)
    {
        NSLog(@"[ERR] read data fail: %@", filePath);
        return NO;
    }
    NSMutableData *newFileData = [NSMutableData dataWithCapacity:[fileData length]];
    [newFileData setData:fileData];
    
    //struct fat_header *pheader = (struct fat_header *)[newFileData mutableBytes];
    
    char buffer[MAX_FAT_HEADER_SIZE] = {0};
    memcpy(buffer, [fileData bytes], MAX_FAT_HEADER_SIZE);
    struct fat_header *pheader = (struct fat_header *)buffer;
    int arch_count = OSSwapInt32(pheader->nfat_arch);
    struct fat_arch *arch = (struct fat_arch *)(pheader + 1);
    
    // check file size first and make sure offset is growing
    uint64_t total_size = 0;
    uint32_t last_offset = 0;
    for (int i = 0; i < arch_count; i++)
    {
        if (last_offset >= OSSwapInt32(arch->offset))
        {
            NSLog(@"[ERR] offset is not growing, arch index: %d", i);
            return NO;
        }
        
        last_offset = OSSwapInt32(arch->offset);
        total_size = OSSwapInt32(arch->offset) + OSSwapInt32(arch->size);
        arch++;
    }
    if (total_size != [fileData length])
    {
        NSLog(@"[ERR] mismatch file size - %llx : %x", total_size, (uint32)[fileData length]);
        return NO;
    }
    
    //NSLog(@"start");
    
    // remove useless arch
    arch = (struct fat_arch *)(pheader + 1);    
    for (int i = 0; i < arch_count; i++)
    {
        int cputype = OSSwapInt32(arch->cputype);
        //uint32_t arch_size = OSSwapInt32(arch->size);
        uint32_t offset = OSSwapInt32(arch->offset);
        
        if (cputype != CPU_TYPE_I386 && cputype != CPU_TYPE_X86_64)
        {
            // remove it
            uint32_t cut_size = 0;
            
            int move_header_size = (arch_count - i - 1) * sizeof(struct fat_arch);
            if (move_header_size > 0)
            {
                // remove arch header if it is not the last one
                memcpy(arch, arch + 1, move_header_size);
            }
            // zero the last arch header
            memset((char *)arch + move_header_size, 0, sizeof(struct fat_arch));
            
            if (move_header_size > 0)
            {
                uint32_t next_offset = OSSwapInt32(arch->offset);
                
                // cut size
                cut_size = next_offset - offset;
            }
            else
            {
                cut_size = (uint32_t)(total_size - offset);
            }
            // remove file body
            NSRange cutRange = {offset, cut_size};
            [newFileData replaceBytesInRange:cutRange
                                   withBytes:NULL
                                      length:0];
            
            // cut size
            total_size -= cut_size;
            
            // change arch_header after it
            struct fat_arch *after_arch = arch;
            for (int j = 0; j < arch_count - i - 1; j++)
            {
                uint32_t new_offset = OSSwapInt32(after_arch->offset) - cut_size;
                after_arch->offset = OSSwapInt32(new_offset);
                
                after_arch++;
            }
            
            arch_count--;
            i--;
            pheader->nfat_arch = OSSwapInt32(arch_count);
        }
        else
        {
            arch++;
        }
    }
    
    // replace header
    NSRange headerRange = {0, sizeof(buffer)};
    [newFileData replaceBytesInRange:headerRange withBytes:buffer];
    
    if ([newFileData length] != total_size)
    {
        NSLog(@"[ERR] cut file size mismatch - %x : %llx", (uint32)[newFileData length], total_size);
    }
    
    //NSLog(@"end");
    
    // backup first, for test !!!
    //    [fileMgr copyItemAtPath:filePath
    //                     toPath:[filePath stringByAppendingString:@"_o"]
    //                      error:NULL];
    
    // save to new file
    if (![newFileData writeToFile:filePath atomically:YES])
    {
        NSLog(@"[ERR] overwrite file fail: %@", filePath);
        return NO;
    }
    
    return YES;
}
