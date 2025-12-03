//
//  LMButton.m
//  LemonClener
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMButton.h"
#import "LMButtonCell.h"

@interface LMButton()

@property (nonatomic, strong) NSTextField *customLabel;

@end

@implementation LMButton

-(void)setUp{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    self.defaultImage = [bundle imageForResource:@"start_scan_btn_down_bg"];
    self.hoverImage = [bundle imageForResource:@"start_scan_btn_hover_bg"];
    self.downImage = [bundle imageForResource:@"start_scan_btn_normal_bg"];
    
    self.defaultTitleColor = [NSColor colorWithHex:0xFFFFFF];
    
    // 创建自定义Label
    [self setupCustomLabel];

    [super setUp];
    
    // 隐藏NSButton原有的标题
    [super setTitle:@""];
}

- (void)setupCustomLabel {
    if (!self.customLabel) {
        self.customLabel = [[NSTextField alloc] init];
        self.customLabel.editable = NO;
        self.customLabel.selectable = NO;
        self.customLabel.bordered = NO;
        self.customLabel.backgroundColor = [NSColor clearColor];
        self.customLabel.alignment = NSTextAlignmentCenter;
        
        // 关键配置：确保Label能正确显示
        self.customLabel.bezeled = NO;
        self.customLabel.drawsBackground = NO;
        self.customLabel.wantsLayer = YES;
        
        // 设置默认文本和样式
        self.customLabel.stringValue = @"";
        self.customLabel.font = [NSFont systemFontOfSize:13];
        // 使用正确的默认颜色而不是白色
        self.customLabel.textColor = self.defaultTitleColor ?: [NSColor whiteColor];
        
        // 同步NSButtonCell的属性到自定义Label
        [self syncCellPropertiesToLabel];
        
        [self addSubview:self.customLabel];
        [self layoutCustomLabel];
    }
}

// 同步NSButtonCell的属性到自定义Label
- (void)syncCellPropertiesToLabel {
    if (!self.customLabel || !self.cell) {
        return;
    }
    
    // 同步字体
    NSFont *cellFont = self.font;
    if (cellFont) {
        self.customLabel.font = cellFont;
    } else {
        self.customLabel.font = [NSFont systemFontOfSize:13]; // 默认字体
    }
    
    // 同步文本对齐方式
    NSTextAlignment alignment = self.alignment;
    self.customLabel.alignment = alignment;
    
    // 同步attributedTitle的属性（如果有的话）
    NSAttributedString *attributedTitle = self.attributedTitle;
    if (self.customLabel && attributedTitle.length > 0) {
        // 提取attributedTitle中的字体和颜色信息
        [self.customLabel setAttributedStringValue:attributedTitle];
    } else {
        // 确保有明显的文本颜色
        self.customLabel.textColor = self.defaultTitleColor ?: [NSColor whiteColor];
    }
    
    // 强制刷新显示
    [self.customLabel setNeedsDisplay:YES];
}

- (void)layoutCustomLabel {
    if (self.customLabel) {
        NSRect titleFrame = self.bounds;
        if ([self.cell isKindOfClass:LMButtonCell.class]) {
            //这里是个估计值，之前已有逻辑是根据一个错误的依赖（attributedStringValue）估计的，当前沿用。如果要大范围使用LMButton，这里需要修改
            // 正确来说是计算文字中心下移到一个固定位置。下移的的位移是变化的，但是目标中心位置是固定的。
            NSSize titleSize = [[self attributedStringValue] size];
            titleFrame.origin.y = (titleFrame.size.height-titleSize.height)*0.18;
        }
        self.customLabel.frame = titleFrame;
        // 强制刷新
        [self.customLabel setNeedsDisplay:YES];
    }
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self layoutCustomLabel];
}

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [self layoutCustomLabel];
}

// 重写setTitle方法，将文本设置到自定义Label
- (void)setTitle:(NSString *)title {
    // [super setTitle:<#title#>];
    NSLog(@"Setting title: %@", title);
    
    if (self.customLabel) {
        self.customLabel.stringValue = title ?: @"";
        [self updateCustomLabelColor];
        
        [self layoutCustomLabel]; // 重新布局以适应新文本
    } else {
        // 如果customLabel还没创建，先调用父类方法
        [super setTitle:title];
    }
}

// 重写title的getter方法
- (NSString *)title {
    if (self.customLabel) {
        return self.customLabel.stringValue;
    }
    return [super title];
}

// 重写setFont方法，同步字体到自定义Label
- (void)setFont:(NSFont *)font {
    // [super setFont:font];
    if (self.customLabel && font) {
        self.customLabel.font = font;
        [self layoutCustomLabel]; // 重新布局以适应新字体
    }
}

// 重写setAlignment方法，同步对齐方式到自定义Label
- (void)setAlignment:(NSTextAlignment)alignment {
    // [super setAlignment:alignment];
    if (self.customLabel) {
        self.customLabel.alignment = alignment;
    }
}

// 重写setAttributedTitle方法，同步属性文本到自定义Label
- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
    // [super setAttributedTitle:attributedTitle];
    
    if (self.customLabel && attributedTitle.length > 0) {
        [self.customLabel setAttributedStringValue:attributedTitle];
        [self layoutCustomLabel]; // 重新布局
    }
}

// 重写颜色设置方法，应用到自定义Label
- (void)applyTitleColor {
    // [super applyTitleColor];
    
    if (self.customLabel) {
        NSColor *targetColor = nil;
        
        if (!self.enabled) {
            targetColor = [NSColor grayColor];
        } else {
            // 由于无法直接访问父类的私有变量，我们通过重写setTitleColor方法来同步颜色
            targetColor = self.defaultTitleColor ?: [NSColor whiteColor];
        }
        
        if (targetColor) {
            self.customLabel.textColor = targetColor;
        }
    }
}

// 重写父类的鼠标事件方法来同步颜色状态
- (void)mouseEntered:(NSEvent *)event {
    [super mouseEntered:event];
    [self updateCustomLabelColor];
}

- (void)mouseExited:(NSEvent *)event {
    [super mouseExited:event];
    [self updateCustomLabelColor];
}

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    [self updateCustomLabelColor];
}

- (void)mouseUp:(NSEvent *)event {
    [super mouseUp:event];
    [self updateCustomLabelColor];
}

- (void)updateCustomLabelColor {
    if (self.customLabel) {
        NSColor *targetColor = nil;
        
        if (!self.enabled) {
            targetColor = [NSColor grayColor];
        } else {
            // 通过检查当前鼠标状态来确定颜色
            BOOL isMouseDown = [NSApp currentEvent].type == NSEventTypeLeftMouseDown;
            BOOL isMouseInView = [self mouseInView];
            
            if (isMouseDown && self.downTitleColor) {
                targetColor = self.downTitleColor;
            } else if (isMouseInView && self.hoverTitleColor) {
                targetColor = self.hoverTitleColor;
            } else if (self.defaultTitleColor) {
                targetColor = self.defaultTitleColor;
            } else {
                // 如果没有设置任何颜色，使用白色作为默认
                targetColor = [NSColor whiteColor];
            }
        }
        
        if (targetColor) {
            self.customLabel.textColor = targetColor;
            NSLog(@"Updated label color to: %@", targetColor);
        }
    }
}

// 重写父类的setTitleColor方法来同步颜色状态到自定义Label
- (void)setTitleColor {
    // 不调用父类方法，因为我们要用自定义Label
    [self updateCustomLabelColor];
}

// 重写setEnabled方法，同步禁用状态到自定义Label
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if (self.customLabel) {
        self.customLabel.textColor = enabled ? 
            (self.defaultTitleColor ?: [NSColor whiteColor]) : 
            [NSColor grayColor];
    }
}

// 添加一个公共方法，允许外部手动同步Cell属性
- (void)syncCellProperties {
    [self syncCellPropertiesToLabel];
    [self layoutCustomLabel];
}

// 重写setCell方法，确保在设置新Cell时同步属性
- (void)setCell:(NSButtonCell *)cell {
    // [super setCell:cell];
    if (self.customLabel) {
        [self syncCellPropertiesToLabel];
        [self layoutCustomLabel];
    }
}

// 重写drawRect确保自定义Label能正确显示
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // 确保自定义Label在最上层
    if (self.customLabel && self.customLabel.superview == self) {
        [self.customLabel setNeedsDisplay:YES];
    }
}

@end
