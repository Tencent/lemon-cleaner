//
//  QMLoginItemCacheHelper.m
//  QMAppLoginItemManage
//
//

#import "QMLoginItemCacheHelper.h"

@interface QMLoginItemCacheHelper ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *dict;

@end

@implementation QMLoginItemCacheHelper

+ (QMLoginItemCacheHelper *)sharedInstance
{
    static QMLoginItemCacheHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QMLoginItemCacheHelper alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSMutableDictionary *)dictForCacheKey:(NSString *)key {
    if (!key) return nil;
    NSMutableDictionary *subDict = [self.dict objectForKey:key];
    if (!subDict) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:key];
        dict = dict ? : [NSDictionary new];
        subDict = dict.mutableCopy;
        [self.dict setValue:subDict forKey:key];
    }
    return subDict;
}

- (void)updateUserDefaultsWithCacheKey:(NSString *)key {
    if (!key) return;
    NSMutableDictionary *subDict = [self.dict objectForKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:subDict forKey:key];
}

@end
