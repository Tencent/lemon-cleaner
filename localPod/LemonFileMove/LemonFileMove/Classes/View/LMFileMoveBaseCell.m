//
//  LMFileMoveBaseCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveBaseCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import "LMFileMoveManger.h"
#import "LMResultItem.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMFileMoveBaseCell(){
    NSTrackingArea *trackingArea;
}
@end

@implementation LMFileMoveBaseCell

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    
}


- (void)setCellData:(id)item {
    [_iconView setImageScaling:NSImageScaleAxesIndependently];
    
    if ([item title] != nil) {
        [_titleLabel setStringValue:[item title]];
    }
    // 显示大小
    NSString *sizeStr = @"很干净";
    _sizeLabel.textColor = [NSColor colorWithHex:0x33D39D];
    if ([item fileSize]) {
        sizeStr = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:[item fileSize]];
        if (![item isKindOfClass:[LMResultItem class]]) {
            sizeStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Total %@", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr];
        }
        _sizeLabel.textColor = [LMAppThemeHelper getTitleColor];
    }
    [_sizeLabel setStringValue:sizeStr];
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
        [self setHightLightStyle:selected];
    }
}

- (CGFloat)getViewHeight {
    return 0;
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
