//
//  CCMBase64.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMBase64.h"

@implementation CCMBase64


+ (NSString *)base64StringFromData:(NSData *)data {
  if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
    // Mac OS 10.9+ / iOS 7+
    return [data base64EncodedStringWithOptions:kNilOptions];
  } else {
    // pre Mac OX 10.9 / iOS7
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [data base64Encoding];
#pragma clang diagnostic pop
  }
}

+ (NSData *)dataFromBase64String:(NSString *)string {
  if ([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
    // Mac OS 10.9+ / iOS 7+
    return [[NSData alloc] initWithBase64EncodedString:string options:kNilOptions];
  } else {
    // pre Mac OX 10.9 / iOS7
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSData alloc] initWithBase64Encoding:string];
#pragma clang diagnostic pop
  }
}

@end
