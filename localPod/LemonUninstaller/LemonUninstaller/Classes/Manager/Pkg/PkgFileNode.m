//
//  PkgFileNode.m
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "PkgFileNode.h"

@implementation PkgFileNode


- (NSString *)description
{
    NSString * stringDebug = [[self.subNodes valueForKey:@"description"] componentsJoinedByString:@"\n"];
    return [NSString stringWithFormat:@"path:%@ \n\nsubPath:%@", self.path, stringDebug];

}

- (NSString *)debugDescription
{
    NSString * stringDebug = [[self.subNodes valueForKey:@"description"] componentsJoinedByString:@"\n"];
    return [NSString stringWithFormat:@"path:%@ \nsubPath:%@", self.path, stringDebug];

}

- (id)debugQuickLookObject
{
    NSString * stringDebug = [[self.subNodes valueForKey:@"description"] componentsJoinedByString:@"\n"];
    return [NSString stringWithFormat:@"path:%@ \nsubPath:%@", self.path, stringDebug];
}

@end


