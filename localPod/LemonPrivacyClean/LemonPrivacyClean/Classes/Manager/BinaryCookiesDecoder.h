//
//  BinaryCookiesParser.h
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//




// 注意: 暂不使用这个类去解析 binaryCookie了. 直接使用
//It turns out 10.11 to sandbox every individual app like iOS. Here is my solution.
// NSHTTPCookieStorage *storage  = [NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:@"Cookies"];
// To write cookies to the app
//for (NSHTTPCookie *aCookies in [storage cookies]){
//    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:aCookies];
//}

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, BinaryCookiesErrorType) {
    BinaryCookiesErrorTypeBadFileHeader = -1,
    BinaryCookiesErrorTypeInvalidEndOfCookieData = -2,
    BinaryCookiesErrorTypeUnexpectedCookieHeaderValue = -3
};




@interface BinaryCookieParserException : NSException

@property BinaryCookiesErrorType errorType;

@end



@interface BinaryReader : NSObject

@end




@interface BinaryCookiesDecoder : NSObject

@end





@interface BinaryCookiesParser : NSObject
+ (NSArray *)parseWithData:(NSData *)data ;
@end




// __unsafe_unretained meaning https://stackoverflow.com/questions/8592289/arc-the-meaning-of-unsafe-unretained
// __unsafe_unretained和__weak都防止了参数的持有。对于__weak，指针的对象在它指向的对象释放的时候回转换为nil，这是一种特别安全的行为。就像他的名字表达那样，__unsafe_unretained会继续指向对象存在的那个内存

// 结构体 struct  typedef struct _XXX {}XXX;
// 结构体不能使用 OC object ARC forbids Objective-C objects in struct

@interface Cookie : NSObject

@property(assign) int64_t expiration;
@property(assign) int64_t creation;
@property(readwrite) NSString *domain;
@property(readwrite) NSString *name;
@property(readwrite) NSString *path;
@property(readwrite) NSString *value;
@property(assign) BOOL secure;
@property(assign) BOOL http;

@end
