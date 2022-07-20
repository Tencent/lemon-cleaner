//
//  LMSimilarPhotoDataCenter.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMSimilarPhotoDataCenter : NSObject

+(id)shareInstance;

-(void)addNewResultWithSourcePathKey:(NSString *)md5_key groupPathKey:(NSString *)dateString dictionary:(NSString *) result_dictionary;

-(NSMutableArray *)getResultDictionaryWithKey:(NSMutableArray *) md5_keyArray;

-(BOOL)isExistResultWithGroupPathKey:(NSString *) dateString;

-(NSString *)getResultDictionaryByGroupPathKey: (NSString*)dateString;

-(NSMutableArray *)getResultDictionaryArrayWithGroupPathKey:(NSString *) groupPathKey;
@end

NS_ASSUME_NONNULL_END
