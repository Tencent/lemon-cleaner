//
//  LMAdaptiveScrollView.m
//  LemonMonitor
//
//  Created on 2025-10-23.
//

#import "LMAdaptiveScrollView.h"

@implementation LMAdaptiveScrollView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.minHeight = 60;
        self.maxHeight = 120;
        [self setupObservers];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.minHeight = 60;
        self.maxHeight = 120;
        [self setupObservers];
    }
    return self;
}

- (void)setupObservers {
    // 监听文本变化
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(textDidChange:) 
        name:NSTextDidChangeNotification 
        object:nil];
    
    // 监听 documentView 设置
    [self addObserver:self 
           forKeyPath:@"documentView" 
              options:NSKeyValueObservingOptionNew 
              context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    if ([keyPath isEqualToString:@"documentView"]) {
        // documentView 设置后，延迟更新高度
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), 
                       dispatch_get_main_queue(), ^{
            [self updateHeight];
        });
    }
}

- (void)textDidChange:(NSNotification *)notification {
    // 只处理当前 ScrollView 的 documentView 的文本变化
    if (notification.object == self.documentView) {
        [self updateHeight];
    }
}

- (void)updateHeight {
    NSTextView *textView = (NSTextView *)self.documentView;
    if (![textView isKindOfClass:[NSTextView class]]) {
        return;
    }
    
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSTextContainer *textContainer = textView.textContainer;
    
    if (!layoutManager || !textContainer) {
        return;
    }
    
    // 确保布局完成
    [layoutManager ensureLayoutForTextContainer:textContainer];
    
    // 计算内容实际高度
    CGFloat contentHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
    
    // 添加一些内边距
    contentHeight += 10;
    
    // 限制在最小和最大高度之间
    CGFloat newHeight = MAX(self.minHeight, MIN(contentHeight, self.maxHeight));
    
    // 触发高度变化回调
    if (self.heightDidChange) {
        self.heightDidChange(newHeight);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [self removeObserver:self forKeyPath:@"documentView"];
    } @catch (NSException *exception) {
        // 忽略移除观察者时的异常
    }
}

@end
