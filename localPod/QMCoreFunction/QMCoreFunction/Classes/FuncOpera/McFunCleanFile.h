//
//  McFunCleanFile.h
//  McCoreFunction
//
//  Created by developer on 12-1-12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "McCoreFunctionCommon.h"
#import "CutBinary.h"

@interface McFunCleanFile : NSObject

- (BOOL)cleanItemAtPath:(NSString *)path
                  array:(NSArray *)pathArray
               delegate:(id<McCleanDelegate>)cleanDelegate
             removeType:(McCleanRemoveType)type;

- (void)cutunlessBinary:(NSArray *)filePaths
             removeType:(int)type;

- (void)startClean:(NSArray *)path1
         cutBinary:(NSArray *)path2
          delegate:(id<McCleanDelegate>)cleanDelegate
        removeType:(McCleanRemoveType)type;

- (int)moveFileItem:(NSString *)path1 toPath:(NSString *)path2;
- (int)copyFileItem:(NSString *)path1 toPath:(NSString *)path2;

-(void)removeFileByDaemonWithPath: (NSString *)path;
@end
