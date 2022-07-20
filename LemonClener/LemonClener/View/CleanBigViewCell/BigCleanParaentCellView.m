//
//  BigCleanParaentCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "BigCleanParaentCellView.h"
#import <Masonry/Masonry.h>
#import "QMBaseItem.h"
#import <QMUICommon/NSFontHelper.h>

@interface BigCleanParaentCellView(){
    NSTrackingArea *trackingArea;
}
@end


@implementation BigCleanParaentCellView

-(id)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self.checkButton setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.sizeLabel setFont:[NSFontHelper getLightSystemFont:12]];
    
}

-(void)updateTrackingAreas{
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self updateRowViewSelectState:YES];
}

- (void)mouseExited:(NSEvent *)event {
    [self updateRowViewSelectState:NO];
}

- (void)updateRowViewSelectState:(BOOL)selected {
    NSView *superView = self.superview;
    if (superView != nil && [superView isKindOfClass:NSTableRowView.class]) {
        NSTableRowView *rowView = (NSTableRowView *) superView;
        [rowView setSelected:selected];
        [self setHightLightStyle:selected];
    }
}

-(CGFloat)getViewHeight {
    return 0;
}

-(void)setCellData:(id)item {
    [_iconView setImageScaling:NSImageScaleAxesIndependently];
    if ([item title] != nil) {
        [_titleLabel setStringValue:[item title]];
    }
    // 显示大小
    NSString *sizeStr = [self getSizeStr:item];
    [_sizeLabel setStringValue:sizeStr];
}

-(NSString *)getSizeStr:(id)item{
    // 扫描完成，显示结果
    NSString * sizeStr = @"0 B";
    NSUInteger selectedSize = [item resultSelectedFileSize];
    sizeStr = [NSString stringFromDiskSize:selectedSize];
    return sizeStr;
}

- (void)setHightLightStyle:(BOOL)hight{
    if (m_hight == hight)
        return;
    m_hight = hight;
    [self _refreshDisplayState:m_hight];
}

- (void)_refreshDisplayState:(BOOL)hight{
    
}

@end
