//
//  CCMPrivateKey.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMPrivateKey.h"

@implementation CCMPrivateKey {
  SecKeyRef _key;
}

- (instancetype)initWithSecKeyRef:(SecKeyRef)key {
  self = [super init];
  if (self) {
    _key = (SecKeyRef)CFRetain(key);
  }
  return self;
}

- (void)dealloc {
  CFRelease(_key);
}

- (SecKeyRef)secKeyRef {
  return _key;
}

@end
