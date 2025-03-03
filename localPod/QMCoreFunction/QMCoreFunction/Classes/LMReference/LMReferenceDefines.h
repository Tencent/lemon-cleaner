//  Copyright © 2018年 Tencent. All rights reserved.
//

#ifndef MQQReferenceDefines_h
#define MQQReferenceDefines_h

/**
 Synthsize a weak or strong reference.
 
 Example:
    @weakify(self);
    [self doSomething^{
        [weak_self xxxxxx];
        ...
        @strongify(self);
        dispatch_async(...., ^{
            [self xxxxxxx];
        });
        ...
    }];
 */
 
#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object
        #else
            #define weakify(object) autoreleasepool{} __block __typeof__(object) weak##_##object = object
        #endif
    #else
        #if __has_feature(objc_arc)
            #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object
        #else
            #define weakify(object) try{} @finally{} {} __block __typeof__(object) weak##_##object = object
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object
        #else
            #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object
        #endif
    #else
        #if __has_feature(objc_arc)
            #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object
        #else
            #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object
        #endif
    #endif
#endif

#endif /* MQQReferenceDefines_h */
