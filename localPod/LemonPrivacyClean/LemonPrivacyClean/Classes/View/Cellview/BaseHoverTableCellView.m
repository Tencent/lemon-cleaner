//
//  BaseHoverTableCellView.m
//  LemonPrivacyClean
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "BaseHoverTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import <Masonry/Masonry.h>

@interface BaseHoverTableCellView ()
@property (nonatomic, strong) NSButton    *noPrivacyBtn;
@end


@implementation BaseHoverTableCellView{
    NSTrackingArea *trackingArea;
}



- (void)updateTrackingAreas {
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
    }
}

// fix row 处于 select 状态时, textfield 字体变细的问题.
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}


- (void) removeFullDiskAccessViews
{
    if(self.noPrivacyBtn){
        if([self.noPrivacyBtn superview] ){
            [self.noPrivacyBtn removeFromSuperview];
        }
        self.noPrivacyBtn = nil;
    }
    
}

// 关于 full disk access 权限设置.
- (void) addFullDiskAccessSetttingBtn
{
    if (self.noPrivacyBtn == nil) {
        self.noPrivacyBtn = [LMViewHelper createNormalTextButton:12 title:[self getNoFullDiskAccessAuthorityWording] textColor:[NSColor colorWithHex:0xFF9600]];
        self.noPrivacyBtn.alignment = NSTextAlignmentLeft;
        [self addSubview:self.noPrivacyBtn];
        self.noPrivacyBtn.target = self;
        self.noPrivacyBtn.action = @selector(clickNoFullDiskPrivacyBtn);
        [self.noPrivacyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self).offset(-60);
            make.height.equalTo(self);
        }];
    }
}

-(void)clickNoFullDiskPrivacyBtn{
    if(self.delegate){
        //通知LMCleanBigViewController 弹出popViewController
        [self.delegate openFullDiskAccessSettingGuidePage];
    }
}

-(NSString *)getNoFullDiskAccessAuthorityWording{
    return NSLocalizedStringFromTableInBundle(@"GETAllItemsAccessAuthority", nil, [NSBundle bundleForClass:[self class]], @"");
}
@end
