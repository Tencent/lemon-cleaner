//
//  LMSpaceModel.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceModel.h"


@implementation LMSpaceModel

- (instancetype)init{
    self = [super init];
    if (self) {
        _currentItems = [NSMutableArray array];
        _currentChildItms = [NSMutableArray array];
        _remindItems = [NSMutableArray array];
    }
    return self;
}
@end
