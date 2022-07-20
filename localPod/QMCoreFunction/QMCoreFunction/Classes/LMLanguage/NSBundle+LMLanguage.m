//
//  NSBundle+LMLanguage.m
//  Lemon
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "NSBundle+LMLanguage.h"
#import <objc/runtime.h>

static const char _bundle = 0;

@interface BundleEx : NSBundle

@end

@implementation BundleEx

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    @try{
        NSBundle *bundle = objc_getAssociatedObject(self, &_bundle);
        return bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
        [super localizedStringForKey:key value:value table:tableName];
    }
    
}
@end

@implementation NSBundle (LMLanguage)

+ (void)setLanguage:(NSString *)language bundle:(NSBundle *)bundle;{
    if(language == nil){
        return;
    }
    if(bundle == nil){
        return;
    }
    @try{
        //    static dispatch_once_t onceToken;
        //    dispatch_once(&onceToken, ^{
        object_setClass(bundle, [BundleEx class]);
        //    });
        
        objc_setAssociatedObject(bundle, &_bundle, language ? [NSBundle bundleWithPath:[bundle pathForResource:language ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }

}

@end
