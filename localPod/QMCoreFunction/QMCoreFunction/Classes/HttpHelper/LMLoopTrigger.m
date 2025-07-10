//
//  LMLoopTrigger.m
//  QMCoreFunction
//
//

#import "LMLoopTrigger.h"
#import "LMLoopTriggerCallbackObject.h"

static NSString * kRunModeKey = @"kRunModeKey";

@interface LMLoopTrigger ()

@property (nonatomic, strong) NSMutableSet<NSNumber *> *timerTaskSet;

@property (nonatomic, strong) NSMutableDictionary<NSString*,LMLoopTriggerCallbackObject*> *registerCallbackDict;

@end

@implementation LMLoopTrigger

+ (instancetype)sharedInstance {
    static LMLoopTrigger *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timerTaskSet = [[NSMutableSet alloc] init];
        _registerCallbackDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching {
    for (LMLoopTriggerCallbackObject *object in self.registerCallbackDict.allValues) {
        if (object.runModes & LMLoopTriggerRunModeWhenAppLaunch) {
            if (object.callback) object.callback();
        }
    }
}

- (void)timerFired:(NSTimer *)timer {
    LMLoopTriggerRunModes runMode = [timer.userInfo[kRunModeKey] unsignedIntegerValue];
    for (LMLoopTriggerCallbackObject *object in self.registerCallbackDict.allValues) {
        if (object.runModes & runMode) {
            if (object.callback) object.callback();
        }
    }
}

- (void)scheduledTimerWithTimeInterval:(NSTimeInterval)ti runMode:(LMLoopTriggerRunModes)runMode {
    NSNumber *tiNum = [NSNumber numberWithDouble:ti];
    for (NSNumber *existingTiNum in self.timerTaskSet) {
        if ([tiNum isEqualToNumber:existingTiNum]) {
            return;
        }
    }
    NSTimer *timer = [NSTimer timerWithTimeInterval:ti
                                             target:self
                                           selector:@selector(timerFired:)
                                           userInfo:@{kRunModeKey: [NSNumber numberWithUnsignedInteger:runMode]}
                                            repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    [self.timerTaskSet addObject:tiNum];
}

- (void)runModeRightNowForKey:(NSString *)key {
    if (![key isKindOfClass:NSString.class]) {
        return;
    }
    LMLoopTriggerCallbackObject *object = self.registerCallbackDict[key];
    if (object.runModes & LMLoopTriggerRunModeSupportRightNow) {
        if (object.callback) object.callback();
    }
}

- (void)runModes:(LMLoopTriggerRunModes)runModes key:key callback:(dispatch_block_t)callback {
    if (runModes == 0) return;
    
    if (![key isKindOfClass:NSString.class]) {
        return;
    }
    LMLoopTriggerCallbackObject *object = [LMLoopTriggerCallbackObject new];
    object.callback = callback;
    object.runModes = runModes;
    [self.registerCallbackDict setObject:object forKey:key];
    
#ifdef DEBUG
    if (runModes & LMLoopTriggerRunModeEveryFiveSeconds) {
        // 启动5s的定时器,用于测试
        [self scheduledTimerWithTimeInterval:5 runMode:LMLoopTriggerRunModeEveryFiveSeconds];
    }
#endif
    
    if (runModes & LMLoopTriggerRunModeEveryFiveMinutes) {
        // 启动5分钟的定时器
        [self scheduledTimerWithTimeInterval:5*60 runMode:LMLoopTriggerRunModeEveryFiveMinutes];
    }
    
    if (runModes & LMLoopTriggerRunModeEveryOneHour) {
        // 启动1小时的定时器
        [self scheduledTimerWithTimeInterval:60*60 runMode:LMLoopTriggerRunModeEveryOneHour];
    }
}

@end
