//
//  CalculatePictureFingerprint.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Hank. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef double Similarity;

@interface CalculatePictureFingerprint : NSObject

+ (float) compareDataA:(NSMutableArray*)dataA andDataB:(NSMutableArray*)dataB;
+ (NSMutableArray *)getdataArray:(NSString *)imgStr;

@end
