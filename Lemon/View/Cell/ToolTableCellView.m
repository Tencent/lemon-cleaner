//
//  ToolTableCellView.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ToolTableCellView.h"
#import "UIHelper.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "MyAnimateCellView.h"
#import <QMUICommon/NSFontHelper.h>

#define kAnimateMaxIdx  14
#define kAnimateDelay   0.15

const int LMToolWidth = 618;
const int LMToolHeight = 618;
const int LMToolTopSpace = 50;
const int LMToolCellTopSpace = 10;

@interface ToolTableCellView()<MyAnimateCellViewDelegate>
{
    NSTimer* _animateTimer;
    NSInteger _animateCount;
    NSTimeInterval _enterTime;
}
@property (nonatomic, strong) NSImageView *bgImageView;
@property (nonatomic, strong) MyAnimateCellView *aniContentView;
@property (nonatomic, strong) NSImageView *imgView;
@property (nonatomic, strong) NSTextField *titleLabel;

@property (nonatomic, strong) NSTextField *descLabel;
@property (nonatomic, strong) NSButton *clickToolBtn;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *toolPicName;
@property (nonatomic, copy) ClickToolBlock toolBlock;

@end

@implementation ToolTableCellView

-(id)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupUI];
        [self layoutView];
    }
    
    return self;
}

- (void)delegateMouseEntered {
//-(void)mouseEntered:(NSEvent *)event{
//    if ([_bgImageView isHidden]) {
//        [_bgImageView setHidden:NO];
//    }
    if ([self.className isEqualToString:MORE_FUNCTION]) {
        return;
    }
    if ([self.className isEqualToString:LEMON_LAB]) {
        return;
    }
    _enterTime = [[NSDate date] timeIntervalSince1970];
    [self performSelector:@selector(startAnimate) withObject:nil afterDelay:kAnimateDelay];
}

- (void)delegateMouseExited {
//-(void)mouseExited:(NSEvent *)event{
//    if (![_bgImageView isHidden]) {
//        [_bgImageView setHidden:YES];
//    }
    if ([self.className isEqualToString:MORE_FUNCTION]) {
        return;
    }
    NSTimeInterval _exitTime = [[NSDate date] timeIntervalSince1970];
    if(_exitTime - _enterTime < kAnimateDelay) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)startAnimate {
//    NSLog(@"startAnimate:%@", self.toolPicName);
    if(_animateTimer) {
        [_animateTimer invalidate];
        _animateTimer = nil;
//        NSLog(@"startAnimate:%@ set nil", self.toolPicName);
    }
    _animateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/25
                                                   target:self
                                                 selector:@selector(_refreshAnimateState)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)_refreshAnimateState {
    _animateCount++;
    if(_animateCount > kAnimateMaxIdx) {
        _animateCount = -1;
        [self.imgView setImage:[NSImage imageNamed:self.toolPicName]];
        [_animateTimer invalidate];
        _animateTimer = nil;
        return;
    }
    NSString* picName =[NSString stringWithFormat:@"%@%02ld", self.toolPicName, _animateCount];
    NSImage* image = [NSImage imageNamed:picName];
    [self.imgView setImage:image];
}


-(void)setupUI{
//    [self setWantsLayer:YE];
//    [self.layer setBackgroundColor:[NSColor colorWithHex:0xff00ff].CGColor];
    
//    _bgImageView = [[NSImageView alloc] init];
//    [_bgImageView setImageScaling:NSImageScaleAxesIndependently];
//    [_bgImageView setImage:[NSImage imageNamed:@"tool_hover" withClass:self.class]];
//    [_bgImageView setHidden:YES];
//    [self addSubview:_bgImageView];
    
    _aniContentView = [[MyAnimateCellView alloc] init];
    _aniContentView.delegate = self;
//    [_aniContentView setWantsLayer:YES];
//    [_aniContentView.layer setBackgroundColor:[NSColor redColor].CGColor];
    [self addSubview:_aniContentView];
    
    _imgView = [[NSImageView alloc] init];
//    [_imgView setWantsLayer:YES];
//    [_imgView.layer setBackgroundColor:[NSColor grayColor].CGColor];
    [_aniContentView addSubview:_imgView];
    
    _descLabel = [UIHelper createNormalLabelWithString:@"" color:[NSColor colorWithHex:0x94979b] fontSize:14];
    if (@available(macOS 10.11, *)) {
        [_descLabel setFont:[NSFont systemFontOfSize:14 weight:NSFontWeightLight]];
    }
    
    self.tagImage =  [[NSImageView alloc] init];
    [self.tagImage setImage:[NSImage imageNamed:@"icon_new_tag"]];
    [_aniContentView addSubview:self.tagImage];
    self.tagImage.hidden = YES;
    
#ifndef APPSTORE_VERSION
    if (@available(macOS 10.14, *)) {
        _titleLabel = [UIHelper createNormalLabelWithString:@"" color:[NSColor colorNamed:@"title_name"] fontSize:16];
    } else {
        _titleLabel = [UIHelper createNormalLabelWithString:@"" color:[NSColor colorWithHex:0x515151] fontSize:16];
    }
    
    [_aniContentView addSubview:_titleLabel];
#else
    if (@available(macOS 10.14, *)) {
        _titleLabel = [UIHelper createNormalLabelWithString:@"" color:[NSColor colorNamed:@"title_name"] fontSize:20];
    } else {
        _titleLabel = [UIHelper createNormalLabelWithString:@"" color:[NSColor colorWithHex:0x515151] fontSize:20];
    }

    [_titleLabel setFont:[NSFontHelper getMediumPingFangFont:20]];
    [_aniContentView addSubview:_titleLabel];
    
    [_titleLabel setAlignment:NSTextAlignmentCenter];
    [_descLabel setAlignment:NSTextAlignmentCenter];
#endif
    [_aniContentView addSubview:_descLabel];
    
    NSButton *clickToolBtn = [[NSButton alloc] init];
    clickToolBtn.bordered = NO;
    [clickToolBtn setTitle:@""];
    [clickToolBtn setButtonType:NSButtonTypeMomentaryChange];
    [clickToolBtn setTarget:self];
    [clickToolBtn setAction:@selector(clickTool)];
    [_aniContentView addSubview:clickToolBtn];
    self.clickToolBtn = clickToolBtn;
    
}

-(void)layoutView{
    
//    [_bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.equalTo(self);
//        make.centerX.equalTo(self);
//        make.centerY.equalTo(self).offset(6);
//        make.height.equalTo(@86);
//    }];
#ifndef APPSTORE_VERSION
    [_aniContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@278);
        make.height.equalTo(@100);
        make.left.equalTo(self).offset(14);
        make.centerY.equalTo(self);
    }];
    
    [_imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.aniContentView).offset(45);
        make.centerY.equalTo(self.aniContentView).offset(6);
        make.height.equalTo(@52);
        make.width.equalTo(@52);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imgView.mas_right).offset(7);
        make.top.equalTo(self.aniContentView).offset(33);
    }];
    
    [_tagImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel.mas_right).offset(1);
        make.top.equalTo(self.aniContentView).offset(33);
    }];
    
    [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imgView.mas_right).offset(7);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(3);
    }];
    
    [self.clickToolBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.aniContentView);
        make.height.equalTo(@100);
        make.width.equalTo(self.aniContentView);
    }];
#else
    [_aniContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        CGFloat aWidth = (LMToolWidth - LMToolTopSpace * 2)/2 - LMToolCellTopSpace * 0;
        make.width.equalTo(@(aWidth));
        make.height.equalTo(@160);
        make.left.equalTo(self).offset(LMToolCellTopSpace);
        make.centerY.equalTo(self);
    }];
    
    [_imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.aniContentView).offset(0);
        make.top.equalTo(self.aniContentView).offset(LMToolCellTopSpace*2);
        make.height.equalTo(@52);
        make.width.equalTo(@52);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imgView.mas_bottom).offset(12);
        make.centerX.equalTo(self.aniContentView).offset(0);
    }];
    
    [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(3);
        make.centerX.equalTo(self.aniContentView).offset(0);
    }];
    
    [self.clickToolBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.aniContentView);
        make.height.equalTo(@140);
        make.width.equalTo(self.aniContentView);
        //make.centerX.centerY.equalTo(self.aniContentView).offset(0);
    }];
#endif
}

-(void)clickTool{
    self.tagImage.hidden = YES;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kLemonToolShowNewIcon"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.toolBlock(self.className);
}

-(void)setCellWithToolModel:(ToolModel *) toolModel toolBlock:(ClickToolBlock) toolBlock{
//    NSImage *image = [NSImage imageNamed:toolModel.toolPicName];
//    [_bgImageView setHidden:YES];
    
    self.toolBlock = toolBlock;
    self.className = toolModel.className;
    self.toolPicName = toolModel.toolPicName;

    BOOL needShowIcon = [[NSUserDefaults standardUserDefaults] boolForKey:@"kLemonToolShowNewIcon"];
    if ([self.toolPicName isEqualToString:@"space_icon"] && needShowIcon == NO) {
        self.tagImage.hidden = NO;
    }
    [self.imgView setImage:[NSImage imageNamed:toolModel.toolPicName]];
    [self.titleLabel setStringValue:toolModel.toolName];
    [self.descLabel setStringValue:toolModel.toolDesc];
}

@end
