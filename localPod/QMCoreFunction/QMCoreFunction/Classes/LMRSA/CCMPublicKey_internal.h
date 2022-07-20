//
//  CCMPublicKey_internal.h
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMPublicKey.h"
#import <Security/Security.h>

@interface CCMPublicKey ()

- (instancetype)initWithSecKeyRef:(SecKeyRef)key;
- (SecKeyRef)secKeyRef;

@end
