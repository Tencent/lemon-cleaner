//
//  LMSpaceModelManager.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceModelManager.h"

@implementation LMSpaceModelManager

+ (LMSpaceModelManager *)sharedManger {
    static LMSpaceModelManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMSpaceModelManager alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self itemModelNeedInit];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(needClean)
                                                     name:@"LEMON_SPACE_RESULT_NEED_CLEAN"
                                                   object:nil];
    }
    return self;
}

- (void)itemModelNeedInit {
    _itemModel = [[LMSpaceModel alloc] init];
    _itemModelOne = [[LMSpaceModel alloc] init];
    _itemModelTwo = [[LMSpaceModel alloc] init];
    _itemModelThree = [[LMSpaceModel alloc] init];
}

- (void)needClean{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.itemModel = nil;
        self.itemModelOne = nil;
        self.itemModelTwo = nil;
        self.itemModelThree = nil;
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
