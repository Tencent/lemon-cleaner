//
//  QMRadioButtonGroup.m
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMRadioButtonGroup.h"

@implementation QMRadioButtonGroup
{
    NSString *_keyPath;
}
@synthesize buttons = _buttons;

+ (instancetype)buttonGroupWithButtons:(NSArray *)buttons keyPathForState:(NSString *)keyPath
{
    return [[self alloc] initWithButtons:buttons keyPathForState:keyPath];
}

- (instancetype)initWithButtons:(NSArray *)buttons keyPathForState:(NSString *)keyPath
{
    self = [super init];
    if (self) {
        _keyPath = [keyPath copy];
        _buttons = buttons;
        for (NSButton *btn in _buttons) {
            [btn addObserver:self forKeyPath:_keyPath options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    return self;
}

- (void)dealloc
{
    for (NSButton *btn in _buttons) {
        [btn removeObserver:self forKeyPath:_keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([change[NSKeyValueChangeNewKey] boolValue]) {
        for (NSButton *btn in _buttons) {
            if (btn != object) {
                [btn setValue:@(NO) forKeyPath:_keyPath];
            }
        }
    }
}


@end
