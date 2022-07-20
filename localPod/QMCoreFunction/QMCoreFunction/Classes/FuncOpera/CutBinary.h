//
//  CutBinary.h
//  libcleaner
//
//  Created by developer on 9/7/11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// test if there are useless architecture data contained in the file
uint64_t testFileArch(const char *path);

// clean useless architecture from file
BOOL removeFileArch(NSString *filePath);
