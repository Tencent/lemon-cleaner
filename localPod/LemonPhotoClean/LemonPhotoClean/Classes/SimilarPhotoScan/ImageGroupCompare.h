//
//  ImageGroupCompare.h
//  QQMacMgr
//
//  
//  Copyright © 2018 Hank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DefineHeader.h"

@interface ImageGroupCompare : NSObject

@property (nonnull,nonatomic) NSMutableArray<NSMutableDictionary<NSString *,id> *> *resultData;

- (void)stepCalater:(NSArray<NSString *> *_Nonnull)sourcePathArray;

-(void)photoCompareWithPathArray:(NSArray<NSString *> *_Nullable)sourcePathArray;

- (void)cancelScan;
@end
