//
//  LMFileCustomPathView.m
//  LemonFileMove
//
//  
//

#import "LMFileCustomPathView.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMFileCustomPathView() {
    NSTrackingArea * _trackingArea;
}

@end

@implementation LMFileCustomPathView

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(_trackingArea) {
        [self removeTrackingArea:_trackingArea];
    }
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    
    [self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent *)event{
  
}

- (void)mouseEntered:(NSEvent *)theEvent {
    
    [self fileMoveMaskMoveIn];
}

- (void)mouseDown:(NSEvent *)event {
    if ([self.delegate respondsToSelector:@selector(fileCustomPathViewDidClick)]) {
        [self.delegate fileCustomPathViewDidClick];
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self fileMoveMaskMoveOut];
}

- (void)fileMoveMaskMoveIn {
    if (self.selected == NO) {
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor colorWithHex:0x9A9A9A alpha:0.2].CGColor;
        self.maskView.layer.borderWidth = 1;
        self.maskView.layer.backgroundColor = [NSColor colorWithHex:0xC0C0C0 alpha:0.05].CGColor;
    }
}

- (void)fileMoveMaskMoveOut {
    if (self.selected == NO) {
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor clearColor].CGColor;
        self.maskView.layer.borderWidth = 0;
        self.maskView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
}

- (void)changeMaskLightColor:(BOOL)needChange {
    if (needChange == NO) {
        self.selected = NO;
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor clearColor].CGColor;
        self.maskView.layer.borderWidth = 0;
        self.maskView.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.diskNameLabel.textColor = [LMAppThemeHelper getFixedTitleColor];
    } else {
        self.selected = YES;
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor colorWithHex:0xFFD500 alpha:1].CGColor;
        self.maskView.layer.borderWidth = 1;
        self.maskView.layer.backgroundColor = [NSColor colorWithHex:0xFFD500 alpha:0.1].CGColor;
        self.diskNameLabel.textColor = [NSColor colorWithHex:0xFFAA00 alpha:1];
        
    }
}


- (instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        [self initView];
    }
    return self;
}


-(instancetype)init {
    self = [super init];
    if (self) {
        [self initView];
    }
    return self;
}
- (void)initView {

    // 背景图
    NSImageView *diskImageBgView = [[NSImageView alloc] init];
    diskImageBgView.imageScaling = NSImageScaleProportionallyUpOrDown;
    diskImageBgView.imageAlignment = NSImageAlignCenter;
    diskImageBgView.image = [NSImage imageNamed:@"circle_icon" withClass:[self class]];
    [self addSubview:diskImageBgView];
    self.diskImageBgView = diskImageBgView;
    
    
    // disk图
    NSImageView *diskImageView = [[NSImageView alloc] init];
    diskImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    diskImageView.imageAlignment = NSImageAlignCenter;
    NSImage *image = [NSImage imageNamed:@"dot_icon" withClass:[self class]];
    diskImageView.image = image;
    [self addSubview:diskImageView];
    self.diskImageView = diskImageView;
    
    //
    
    NSTextField *diskNameLabel = [[NSTextField alloc] init];
    diskNameLabel.stringValue = NSLocalizedStringFromTableInBundle(@"Custom Path", nil, [NSBundle bundleForClass:[self class]], @"");;
    diskNameLabel.bordered = NO;
    diskNameLabel.alignment = NSCenterTextAlignment;
    diskNameLabel.font = [NSFont systemFontOfSize:15.0];
    [diskNameLabel setEditable:NO];
    diskNameLabel.textColor = [LMAppThemeHelper getFixedTitleColor];
    diskNameLabel.backgroundColor = [NSColor clearColor];
    [self addSubview:diskNameLabel];
    self.diskNameLabel = diskNameLabel;
    
    //
    NSTextField *diskSizeLabel = [[NSTextField alloc] init];
    diskSizeLabel.stringValue = NSLocalizedStringFromTableInBundle(@"Local", nil, [NSBundle bundleForClass:[self class]], @"");
    diskSizeLabel.bordered = NO;
    diskSizeLabel.textColor = [NSColor colorWithHex:0x989A9E];
    diskSizeLabel.alignment = NSCenterTextAlignment;
    diskSizeLabel.font = [NSFont systemFontOfSize:14.0];
    [diskSizeLabel setEditable:NO];
    diskSizeLabel.backgroundColor = [NSColor clearColor];
    
    [self addSubview:diskSizeLabel];
    self.diskSizeLabel = diskSizeLabel;
    
    [self.diskImageBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@(96));
        make.top.equalTo(self).offset(16);
        make.left.equalTo(self).offset(22);
    }];
    
    [self.diskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@8);
        make.width.equalTo(@36);
        make.center.equalTo(self.diskImageBgView);
    }];
    
    [self.diskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.diskImageBgView.mas_bottom).offset(20);
        make.height.mas_equalTo(17);
    }];
    
    [self.diskSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.diskNameLabel.mas_bottom).offset(8);
        make.height.mas_equalTo(17);
    }];
    
    NSView *mask = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 140, 202)];
    mask.wantsLayer = YES;
    mask.layer.backgroundColor = [NSColor clearColor].CGColor;
    mask.layer.cornerRadius = 4.0;
    [self addSubview:mask positioned:NSWindowBelow relativeTo:self.diskImageBgView];
    self.maskView = mask;
    
}

@end
