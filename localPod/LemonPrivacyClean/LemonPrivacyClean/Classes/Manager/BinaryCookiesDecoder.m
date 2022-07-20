//
//  BinaryCookiesParser.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018 tencent. All rights reserved.
//

#import "BinaryCookiesDecoder.h"


@implementation BinaryCookieParserException
- (instancetype)initWithType:(BinaryCookiesErrorType)type {
    self = [super initWithName:@"CookieParserExcpetion" reason:@"cookie parser error" userInfo:nil];
    if (self) {
        self.errorType = type;
    }
    return self;
}

@end


@interface BinaryReader ()
- (int64_t)readDoubleBE;
@end

@implementation BinaryReader {
    NSData *_data;
    NSUInteger _bufferPosition;
}

- (NSData *)getData {
    return _data;
}

- (instancetype)init:(NSData *)data {
    self = [super init];
    if (self) {
        _data = data;
    }
    return self;
}

- (NSData *)sliceAtLoc:(NSUInteger)loc len:(NSUInteger)len {
    return [_data subdataWithRange:NSMakeRange(loc, len)];
}

- (NSData *)readSlice:(NSUInteger)length {
    NSData *slice = [_data subdataWithRange:NSMakeRange(_bufferPosition, length)];
    _bufferPosition += length;
    return slice;
}

// MARK : BE :big endian  LE:little endian
- (int64_t)readDoubleBE {  // BE meaning?
    int64_t data = [self readDoubleBE:_bufferPosition];
    _bufferPosition += 8;
    return data;
}

- (int64_t)readDoubleBE:(NSUInteger)offset {
    NSData *data = [self sliceAtLoc:offset len:8];
    double_t out = 0;
    memcpy(&out, data.bytes, sizeof(double_t));
    unsigned long long int i = NSSwapHostDoubleToBig(out).v;
    return (int64_t) (i);
}

- (int64_t)readDoubleLE {  // BE meaning?
    int64_t data = [self readDoubleLE:_bufferPosition];
    _bufferPosition += 8;
    return data;
}

- (int64_t)readDoubleLE:(NSUInteger)offset {
    NSData *data = [self sliceAtLoc:offset len:8];
    double_t out = 0;
    memcpy(&out, data.bytes, sizeof(double_t));
    return (int64_t) out;
}


- (int32_t)readIntBE {
    int32_t i = [self readIntBE:_bufferPosition];
    _bufferPosition += 4;
    return i;
}

- (int32_t)readIntBE:(NSUInteger)offset {
    NSData *data = [self sliceAtLoc:offset len:4];
    NSInteger out = 0;
    [data getBytes:&out length:sizeof(NSInteger)];
    return CFSwapInt32HostToBig((uint32_t) out);
}

- (int32_t)readIntLE {
    int32_t i = [self readIntLE:_bufferPosition];
    _bufferPosition += 4;
    return i;
}

- (int32_t)readIntLE:(NSUInteger)offset {
    NSData *data = [self sliceAtLoc:offset len:4];
    NSInteger out = 0;
    [data getBytes:&out length:sizeof(NSInteger)];
    return (int32_t) out;
}


@end


@implementation BinaryCookiesDecoder {
    uint32 _numPage;
    NSArray *_pageSizes; // [uint32]
    NSMutableArray *_pageNumCookies; //[uint32]
    NSMutableArray *_pageCookieOffsets; // [[uint32]]
    NSArray *_pages; //[BinaryReader]
    NSMutableArray *_cookieData; //[[BinaryReader]]
    NSMutableArray *_cookies; // [Cookie]
    BinaryReader *_reader;
}

// return: [Cookie]
- (NSArray *)processCookieData:(NSData *)data {
    _reader = [[BinaryReader alloc] init:data];
    NSData *headerData = [_reader readSlice:4];
    NSString *header = [NSString stringWithUTF8String:[headerData bytes]];
    if ([header isEqualToString:@"cook"]) {
        [self getNumPages];
        [self getPageSizes];
        [self getPages];

        [_pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

            @try {
                [self getNumCookies:idx];
                [self getCookieOffsets:idx];
                [self getCookieData:idx];


                NSArray *cookieReaders = self->_cookieData[idx];
                for (BinaryReader *reader in cookieReaders) {
                    [self parseCookieData:reader];
                }
            } @catch (NSException *exception) {
                *stop = YES;
                NSLog(@"processCookieData occur an error : %@", exception.description);
            }

        }];

    } else {
        @throw [[BinaryCookieParserException alloc] initWithType:BinaryCookiesErrorTypeBadFileHeader];
    }

    return _cookies;

}

- (void)getNumPages {
    _numPage = (uint32) [_reader readIntBE];
}


// +[NSNumber numberWithInteger:] will hold a 32-bit number nicely on all 32-bit and 64-bit systems.
// +[NSNumber integerValue] will retrieve it. If you need it unsigned you can use ``+[NSNumber numberWithUnsignedInteger:]`.

- (void)getPageSizes {

    NSMutableArray *pageSizes = [[NSMutableArray alloc] init];
    _pageSizes = pageSizes;
    for (int i = 0; i < _numPage; i++) {
        int32_t intBE = [_reader readIntBE];
        [pageSizes addObject:@(intBE)];
    }
}

- (void)getPages {
    NSMutableArray *pages = [[NSMutableArray alloc] init];
    _pages = pages;
    for (NSNumber *pageSize in _pageSizes) {
        BinaryReader *reader = [[BinaryReader alloc] init:[_reader readSlice:(NSUInteger) [pageSize integerValue]]];
        [pages addObject:reader];
    }
}

- (void)getNumCookies:(NSUInteger)index {
    BinaryReader *reader = _pages[index];
    int32_t header = [reader readIntBE];
    if (header != 256) {
        @throw [[BinaryCookieParserException alloc]initWithType:BinaryCookiesErrorTypeUnexpectedCookieHeaderValue];
    }

    if (!_pageNumCookies) {
        _pageNumCookies = [[NSMutableArray alloc] init];
    }

    int32_t intLE = [reader readIntLE];
    [_pageNumCookies addObject:@(intLE)];

}

- (void)getCookieOffsets:(NSUInteger)index {
    BinaryReader *reader = _pages[index];
    uint32 numCookies = (uint32) [_pageNumCookies[index] integerValue];

    NSMutableArray *offsets = [[NSMutableArray alloc] init];
    for (int i = 0; i < numCookies; i++) {
        int32_t le = [reader readIntLE];
        [offsets addObject:@(le)];
    }
    if (!_pageCookieOffsets) {
        _pageCookieOffsets = [[NSMutableArray alloc] init];
    }

    [_pageCookieOffsets addObject:offsets];
}

- (void)getCookieData:(NSUInteger)index {
    BinaryReader *reader = _pages[index];
    NSArray *cookieOffsets = _pageCookieOffsets[index];

    NSMutableArray *pageCookies = [[NSMutableArray alloc] init];

    for (NSNumber *cookieOffset in cookieOffsets) {
        int32_t cookieSize = [reader readIntLE:(NSUInteger) [cookieOffset integerValue]];
        NSData *data = [reader sliceAtLoc:(NSUInteger) [cookieOffset integerValue] len:(NSUInteger) cookieSize];
        BinaryReader *tempReader = [[BinaryReader alloc] init:data];
        [pageCookies addObject:tempReader];
    }

    if (!_cookieData) {
        _cookieData = [[NSMutableArray alloc] init];
    }

    [_cookieData addObject:pageCookies];

}


- (void)parseCookieData:(BinaryReader *)cookieReader {
    int64_t macEpochOffset = 978307199;
    NSMutableArray *offsets = [[NSMutableArray alloc] init];

    [cookieReader readIntLE:0]; // unknown1
    [cookieReader readIntLE:4]; // unknown2 
    int32_t flag = [cookieReader readIntLE:4 + 4]; // flags
    [cookieReader readIntLE:8 + 4]; // unknown3

    [offsets addObject:@([cookieReader readIntLE:12 + 4])]; // domain
    [offsets addObject:@([cookieReader readIntLE:16 + 4])]; // name
    [offsets addObject:@([cookieReader readIntLE:20 + 4])]; // path
    [offsets addObject:@([cookieReader readIntLE:24 + 4])]; // value

    int32_t endOfCookie = [cookieReader readIntLE:28 + 4];
    if (endOfCookie != 0) {
        @throw [[BinaryCookieParserException alloc]initWithType:BinaryCookiesErrorTypeInvalidEndOfCookieData];
    }

    int64_t expiration = ([cookieReader readDoubleLE:32 + 8] + macEpochOffset) * 1000;
    int64_t creation = ([cookieReader readDoubleLE:40 + 8] + macEpochOffset) * 1000;
    __block NSString *domain = @"";
    // block 无法直接改变变量  Variable is declared outside the block and is not assignable .
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Blocks/Articles/bxVariables.html
    __block NSString *name = @"";
    __block NSString *path = @"";
    __block NSString *value = @"";
    BOOL secure = NO;
    BOOL http = NO;

//    NSString *cookieString = [NSString stringWithCString:[[cookieReader getData] bytes] encoding:NSASCIIStringEncoding];
    NSString *cookieString = [[NSString alloc]initWithData:[cookieReader getData]  encoding:NSASCIIStringEncoding];
    [offsets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *number = obj;
        NSUInteger offset = (NSUInteger) [number integerValue];
        NSRange range = NSMakeRange(offset, cookieString.length - offset);
//        - (NSRange)rangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)rangeOfReceiverToSearch;

        // @"\u0000" 会报错 Universal character name refers to a control character
        NSString *separateString = [NSString stringWithFormat:@"%C", 0x0000];
        NSUInteger endOffset = [cookieString rangeOfString:separateString options:NSCaseInsensitiveSearch range:range].location;
        NSRange stringRange = NSMakeRange(offset, endOffset - offset);
        NSString *string = [cookieString substringWithRange:stringRange];

        if (idx == 0) {
            domain = string;
        } else if (idx == 1) {
            name = string;
        } else if (idx == 2) {
            path = string;
        } else if (idx == 3) {
            value = string;
        }
    }];

    if (flag == 1) {
        secure = YES;
    } else if (flag == 4) {
        http = YES;
    } else if (flag == 5) {
        secure = YES;
        http = YES;
    }

    Cookie *cookie = [[Cookie alloc] init];
    cookie.creation = creation;
    cookie.domain = domain;
    cookie.name = name;
    cookie.value = value;
    cookie.path = path;
    cookie.expiration = expiration;
    cookie.creation = creation;
    cookie.http = http;
    cookie.secure = secure;

    if (_cookies == nil) {
        _cookies = [[NSMutableArray alloc] init];
    }

    [_cookies addObject:cookie];
    
}

@end


@implementation BinaryCookiesParser

+ (NSArray *)parseWithData:(NSData *)data {
    BinaryCookiesDecoder *parser = [[BinaryCookiesDecoder alloc] init];
    NSArray *array = [parser processCookieData:data];
    return array;
}

@end


@implementation Cookie


@end
