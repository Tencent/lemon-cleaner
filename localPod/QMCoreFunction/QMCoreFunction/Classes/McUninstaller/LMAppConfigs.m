//
//  LMAppConfigs.m
//  AFNetworking
//
//  
//

#import "LMAppConfigs.h"

@interface LMAppConfigs()

@property (strong, nonatomic) NSDictionary *configs;

@end

@implementation LMAppConfigs

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"appConfigs" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        _configs = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
    }
    return self;
}

- (NSDictionary *) getConfigsOfApp:(NSString *)bundleId {
    return [_configs objectForKey:bundleId];
}

- (nonnull NSArray *) getPathsOfApp:(NSString *)bundleId withTypeKey:(NSString *)key {
    NSDictionary *appConfig = [self getConfigsOfApp:bundleId];
    NSArray * array = [appConfig objectForKey:key];
    if (array) {
        return array;
    } else {
        return [[NSArray alloc] init];
    }
}


- (nonnull NSArray *)getDaemonsOfApp:(NSString *)bundleId {
    return [self getPathsOfApp:bundleId withTypeKey:@"Daemons"];

}

- (nonnull NSArray *)getUserAgnetOfApp:(NSString *)bundleId {
    return [self getPathsOfApp:bundleId withTypeKey:@"UserAgents"];
}

@end
