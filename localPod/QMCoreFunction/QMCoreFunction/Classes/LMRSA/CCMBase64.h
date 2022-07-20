//
//  CCMBase64.h
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCMBase64 : NSObject

+ (NSString *)base64StringFromData:(NSData *)data;
+ (NSData *)dataFromBase64String:(NSString *)string;

@end
