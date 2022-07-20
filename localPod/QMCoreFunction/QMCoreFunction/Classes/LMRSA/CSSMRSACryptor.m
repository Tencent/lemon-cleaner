//
//  CSSMRSACryptor.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CSSMRSACryptor.h"
#import "CCMPublicKey_internal.h"
#import "CCMPrivateKey.h"
#import "CCMPrivateKey_internal.h"

static NSString *const kCSSMPublicKeyDecryptorErrorDomain = @"CSSMPublicKeyDecryptorErrorDomain";

@implementation CSSMRSACryptor

- (NSData *)decryptData:(NSData *)encryptedData withPublicKey:(CCMPublicKey *)key error:(NSError **)errorPtr {
  return [self cssm_decryptData:encryptedData usingPublicKey:[key secKeyRef] error:errorPtr];
}

- (NSData *)encryptData:(NSData *)data withPrivateKey:(CCMPrivateKey *)key error:(NSError **)errorPtr {
  return [self cssm_encryptData:data usingPrivateKey:[key secKeyRef] error:errorPtr];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSData*)cssm_decryptData:(NSData *)data usingPublicKey:(SecKeyRef)key error:(NSError**)errorPtr  {
  const CSSM_KEY* cssm_key = nil;
  SecKeyGetCSSMKey(key, &cssm_key);
  CSSM_CSP_HANDLE providerHandle;
  SecKeyGetCSPHandle(key, &providerHandle);

  CSSM_DATA inData;
  inData.Data = (uint8_t*)[data bytes];
  inData.Length = [data length];

  CSSM_DATA outData;
  CSSM_RETURN status = [self cssm_decryptData:&inData provider:providerHandle key:cssm_key output:&outData];
  if (status != CSSM_OK) {
    NSError *error = [NSError errorWithDomain:kCSSMPublicKeyDecryptorErrorDomain
                                         code:status
                                     userInfo:nil];
    if (errorPtr != NULL) {
      *errorPtr = error;
    }
    return nil;
  }
  return [NSData dataWithBytesNoCopy:outData.Data length:outData.Length freeWhenDone:YES];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSData*)cssm_encryptData:(NSData *)data usingPrivateKey:(SecKeyRef)key error:(NSError**)errorPtr  {
  const CSSM_KEY* cssm_key = nil;
  SecKeyGetCSSMKey(key, &cssm_key);
  CSSM_CSP_HANDLE providerHandle;
  SecKeyGetCSPHandle(key, &providerHandle);

  CSSM_DATA inData;
  inData.Data = (uint8_t*)[data bytes];
  inData.Length = [data length];

  CSSM_DATA outData;
  CSSM_RETURN status = [self cssm_encryptData:&inData provider:providerHandle key:cssm_key output:&outData];
  if (status != CSSM_OK) {
    NSError *error = [NSError errorWithDomain:kCSSMPublicKeyDecryptorErrorDomain
                                         code:status
                                     userInfo:nil];
    if (errorPtr != NULL) {
      *errorPtr = error;
    }
    return nil;
  }
  return [NSData dataWithBytesNoCopy:outData.Data length:outData.Length freeWhenDone:YES];
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (CSSM_RETURN)cssm_decryptData:(const CSSM_DATA *)encryptedData
                       provider:(CSSM_CSP_HANDLE)providerHandle
                            key:(const CSSM_KEY *)key
                         output:(CSSM_DATA*)outData  {
  CSSM_RETURN status;

  CSSM_CC_HANDLE ctxHandle;
  status = [self cssm_createAsymmetricContext:&ctxHandle
                                 withProvider:providerHandle
                                          key:key
                                      padding:CSSM_PADDING_PKCS1];
  if (status != CSSM_OK) {
    return status;
  }

  CSSM_CONTEXT_ATTRIBUTE attribute = {};
  attribute.AttributeType = CSSM_ATTRIBUTE_MODE;
  attribute.AttributeLength = sizeof(UInt32);
  attribute.Attribute.Uint32 = CSSM_ALGMODE_PUBLIC_KEY;

  status = CSSM_UpdateContextAttributes(ctxHandle, 1, &attribute);
  if (status != CSSM_OK) {
    return status;
  }

  CSSM_DATA remData = {.Length = 0, .Data = NULL};
  CSSM_SIZE bytesDecrypted;
  outData->Length = 0;
  outData->Data = NULL;
  status = CSSM_DecryptData(ctxHandle,
      encryptedData,
      1,
      outData,
      1,
      &bytesDecrypted,
      &remData);
  CSSM_DeleteContext(ctxHandle);
  if (status != CSSM_OK) {
    return status;
  }
  outData->Length = bytesDecrypted;

  if(remData.Length != 0) {
    /* append remaining data to plainText */
    CSSM_SIZE newLen = outData->Length + remData.Length;
    outData->Data = (uint8 *)realloc(outData->Data, newLen);
    memmove(outData->Data + outData->Length,
        remData.Data, remData.Length);
    outData->Length = newLen;
    free(remData.Data);
  }
  return CSSM_OK;
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (CSSM_RETURN)cssm_encryptData:(const CSSM_DATA *)data
                       provider:(CSSM_CSP_HANDLE)providerHandle
                            key:(const CSSM_KEY *)key
                         output:(CSSM_DATA*)outData  {
  CSSM_RETURN status;

  CSSM_CC_HANDLE ctxHandle;
  status = [self cssm_createAsymmetricContext:&ctxHandle
                                 withProvider:providerHandle
                                          key:key
                                      padding:CSSM_PADDING_PKCS1];
  if (status != CSSM_OK) {
    return status;
  }

  CSSM_CONTEXT_ATTRIBUTE attribute = {};
  attribute.AttributeType = CSSM_ATTRIBUTE_MODE;
  attribute.AttributeLength = sizeof(UInt32);
  attribute.Attribute.Uint32 = CSSM_ALGMODE_PRIVATE_KEY;

  status = CSSM_UpdateContextAttributes(ctxHandle, 1, &attribute);
  if (status != CSSM_OK) {
    return status;
  }

  CSSM_DATA remData = {.Length = 0, .Data = NULL};
  CSSM_SIZE bytesEncrypted;
  outData->Length = 0;
  outData->Data = NULL;
  status = CSSM_EncryptData(ctxHandle, data, 1, outData, 1, &bytesEncrypted, &remData);
//  status = CSSM_DecryptData(ctxHandle,
//      data,
//      1,
//      outData,
//      1,
//      &bytesEncrypted,
//      &remData);
  CSSM_DeleteContext(ctxHandle);
  if (status != CSSM_OK) {
    return status;
  }
  outData->Length = bytesEncrypted;

  if(remData.Length != 0) {
    /* append remaining data to output */
    CSSM_SIZE newLen = outData->Length + remData.Length;
    outData->Data = (uint8 *)realloc(outData->Data, newLen);
    memmove(outData->Data + outData->Length,
        remData.Data, remData.Length);
    outData->Length = newLen;
    free(remData.Data);
  }
  return CSSM_OK;
}
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (CSSM_RETURN)cssm_createAsymmetricContext:(CSSM_CC_HANDLE *)ctxHandle
                               withProvider:(CSSM_CSP_HANDLE)providerHandle
                                        key:(const CSSM_KEY *)key
                                    padding:(CSSM_PADDING)padding {
  CSSM_ACCESS_CREDENTIALS credentials;
  memset(&credentials, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
  return CSSM_CSP_CreateAsymmetricContext(providerHandle,
      key->KeyHeader.AlgorithmId,
      &credentials,         // access
      key,
      padding,
      ctxHandle);
}
#pragma clang diagnostic pop

@end
