//
//  CCMKeyLoader.h
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCMPublicKey;
@class CCMPrivateKey;


@interface CCMKeyLoader : NSObject

/** Load PKCS#1 PEM public key, i.e. -----BEGIN RSA PUBLIC KEY-----... */
- (CCMPublicKey *)loadRSAPEMPublicKey:(NSString *)pemKey;
/** Load X.509 PEM public key, i.e. -----BEGIN PUBLIC KEY-----... */
- (CCMPublicKey *)loadX509PEMPublicKey:(NSString *)pemKey;

/** Load PKCS#1 PEM private key, i.e. -----BEGIN RSA PRIVATE KEY-----... */
- (CCMPrivateKey *)loadRSAPEMPrivateKey:(NSString *)pemKey;

@end
