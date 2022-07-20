//
//  CCMKeyLoader.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMKeyLoader.h"
#import "CCMBase64.h"
#import "CCMPublicKey_internal.h"
#import "CCMPrivateKey_internal.h"


@implementation CCMKeyLoader {
  NSRegularExpression *_headerRegex;
  NSRegularExpression *_footerRegex;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _headerRegex = [NSRegularExpression regularExpressionWithPattern:@"-----BEGIN (RSA )?(PUBLIC|PRIVATE) KEY-----"
                                                             options:0
                                                               error:nil];
    _footerRegex = [NSRegularExpression regularExpressionWithPattern:@"-----END (RSA )?(PUBLIC|PRIVATE) KEY-----"
                                                             options:0
                                                               error:nil];
  }
  return self;
}

- (CCMPublicKey *)loadRSAPEMPublicKey:(NSString *)pemKey {
  if (![self verifyHeader:@"-----BEGIN RSA PUBLIC KEY-----"
                   footer:@"-----END RSA PUBLIC KEY-----"
                    inKey:pemKey]) {
    return nil;
  }
//    if (![self verifyHeader:@"-----BEGIN PUBLIC KEY-----"
//                     footer:@"-----END PUBLIC KEY-----"
//                      inKey:pemKey]) {
//        return nil;
//    }
  NSData *keyData = [self extractKeyData:pemKey];
  if (keyData == nil) {
    return nil;
  }
  // As mentioned in the source for SecImportExportUtils.cpp:
  // kSecFormatBSAFE expected formats for RSA: (public = PKCS1, private = PKCS8)
  // Source: http://www.opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-24850/lib/SecImportExportUtils.cpp?txt
  return [self importPublicKeyData:keyData
                    externalFormat:kSecFormatBSAFE];
}

- (CCMPublicKey *)loadX509PEMPublicKey:(NSString *)pemKey {
  if (![self verifyHeader:@"-----BEGIN PUBLIC KEY-----"
                   footer:@"-----END PUBLIC KEY-----"
                    inKey:pemKey]) {
    return nil;
  }
  NSData *keyData = [self extractKeyData:pemKey];
  if (keyData == nil) {
    return nil;
  }
  // As mentioned in the source for SecImportExportUtils.cpp:
  // kSecFormatOpenSSL expected formats for RSA: (public = X509, private = PKCS1)
  // Source: http://www.opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-24850/lib/SecImportExportUtils.cpp?txt
  return [self importPublicKeyData:keyData
                    externalFormat:kSecFormatOpenSSL];
}

- (CCMPrivateKey *)loadRSAPEMPrivateKey:(NSString *)pemKey {
  if (![self verifyHeader:@"-----BEGIN RSA PRIVATE KEY-----"
                   footer:@"-----END RSA PRIVATE KEY-----"
                    inKey:pemKey]) {
    return nil;
  }
  NSData *keyData = [self extractKeyData:pemKey];
  if (keyData == nil) {
    return nil;
  }
  // As mentioned in the source for SecImportExportUtils.cpp:
  // kSecFormatOpenSSL expected formats for RSA: (public = X509, private = PKCS1)
  // Source: http://www.opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-24850/lib/SecImportExportUtils.cpp?txt
  return [self importPrivateKeyData:keyData
                    externalFormat:kSecFormatOpenSSL];
}

- (CCMPrivateKey *)importPrivateKeyData:(NSData *)keyData externalFormat:(SecExternalFormat)externalFormat {
  SecKeyRef keyRef = [self createSecKeyWithData:keyData
                                 externalFormat:externalFormat
                               externalItemType:kSecItemTypePrivateKey];
  if (keyRef == NULL) {
    return nil;
  }
  CCMPrivateKey *wrappedKey = [[CCMPrivateKey alloc] initWithSecKeyRef:keyRef];
  CFRelease(keyRef);
  return wrappedKey;
}

- (CCMPublicKey *)importPublicKeyData:(NSData *)keyData externalFormat:(SecExternalFormat)externalFormat {
  SecKeyRef keyRef = [self createSecKeyWithData:keyData
                       externalFormat:externalFormat
                     externalItemType:kSecItemTypePublicKey];
  if (keyRef == NULL) {
    return nil;
  }
  CCMPublicKey *wrappedKey = [[CCMPublicKey alloc] initWithSecKeyRef:keyRef];
  CFRelease(keyRef);
  return wrappedKey;
}

- (SecKeyRef)createSecKeyWithData:(NSData *)keyData
                   externalFormat:(SecExternalFormat)externalFormat
                 externalItemType:(SecExternalItemType)externalItemType {
  SecExternalFormat format = externalFormat;
  SecExternalItemType itemType = externalItemType;
  CFArrayRef keys = NULL;
  OSStatus status = SecItemImport((__bridge CFDataRef)keyData, NULL, &format, &itemType, 0, NULL, NULL, &keys);
  if (status != 0) {
    return nil;
  }
  if (keys == NULL || CFArrayGetCount(keys) != 1) {
    return nil;
  }
  SecKeyRef keyRef = (SecKeyRef)CFRetain(CFArrayGetValueAtIndex(keys, 0));
  CFRelease(keys);
  return keyRef;
}

- (BOOL)verifyHeader:(NSString *)header footer:(NSString *)footer inKey:(NSString *)pemKey {
  NSTextCheckingResult *headerMatch = [_headerRegex firstMatchInString:pemKey
                                                               options:0
                                                                 range:NSMakeRange(0, pemKey.length)];
  NSTextCheckingResult *footerMatch = [_footerRegex firstMatchInString:pemKey
                                                               options:0
                                                                 range:NSMakeRange(0, pemKey.length)];
  if (!headerMatch && !footerMatch) {
    // Input key doesn't have a header or footer, this is okay
    return YES;
  } else if (!headerMatch || !footerMatch) {
    // Missing header xor footer
    return NO;
  }
  if (![[pemKey substringWithRange:headerMatch.range] isEqualToString:header]) {
    return NO;
  }
  if (![[pemKey substringWithRange:footerMatch.range] isEqualToString:footer]) {
    return NO;
  }
  return YES;
}

- (NSData *)extractKeyData:(NSString *)pemKey {
  NSString *stripped = [self strippedPEMKey:pemKey];
  return [CCMBase64 dataFromBase64String:stripped];
}

- (NSString *)strippedPEMKey:(NSString *)pemKey {
  NSMutableString *stripped = [NSMutableString stringWithString:pemKey];
  [_headerRegex replaceMatchesInString:stripped
                               options:0
                                 range:NSMakeRange(0, stripped.length)
                          withTemplate:@""];
  [_footerRegex replaceMatchesInString:stripped
                               options:0
                                 range:NSMakeRange(0, stripped.length)
                          withTemplate:@""];
  [stripped replaceOccurrencesOfString:@"\n"
                            withString:@""
                               options:0
                                 range:NSMakeRange(0, stripped.length)];
  return stripped;
}

@end
