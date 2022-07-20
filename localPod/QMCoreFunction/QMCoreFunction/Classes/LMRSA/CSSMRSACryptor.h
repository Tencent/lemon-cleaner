//
//  CSSMRSACryptor.h
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCMPublicKey;
@class CCMPrivateKey;

@interface CSSMRSACryptor : NSObject

- (NSData *)decryptData:(NSData *)encryptedData withPublicKey:(CCMPublicKey *)key error:(NSError **)errorPtr;
- (NSData *)encryptData:(NSData *)data withPrivateKey:(CCMPrivateKey *)key error:(NSError **)errorPtr;

@end
