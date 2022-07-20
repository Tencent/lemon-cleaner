//
//  LMPhotoCollectionViewHeader.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoCollectionViewHeader.h"
#import <QMCoreFunction/NSColor+Extension.h>

#import <QMUICommon/LMGradientTitleButton.h>

@implementation LMPhotoCollectionViewHeader

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
//        [self addCheckBtn];
//        self.checkBtn.target = self;
//        [self.checkBtn setAction:@selector(onCheckButtonClick:)];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect{
//    self.checkBtn.target = self;
//    [self.checkBtn setAction:@selector(onCheckButtonClick:)];
    [self.checkBtn setAction:@selector(onCheckButtonClick:)];
    self.checkBtn.target = self;
    self.checkBtn.allowsMixedState = YES;
    self.checkBtn.imageScaling = NSImageScaleProportionallyUpOrDown;
}

//需求变更，该方法已弃用
-(void)addSelectBtn{
    LMGradientTitleButton *ok = [[LMGradientTitleButton alloc] initWithFrame:NSMakeRect(580, 2, 100, 20)];
    ok.title = NSLocalizedStringFromTableInBundle(@"LMPhotoCollectionViewHeader_initWithCoder_ok_1", nil, [NSBundle bundleForClass:[self class]], @"");
    ok.titleNormalColor = [NSColor colorWithHex:0x057cff];
    ok.titleHoverColor = [NSColor colorWithHex:0x2998ff];
    ok.titleDownColor = [NSColor colorWithHex:0x0a6ad4];
    ok.isGradient = NO;
    ok.isBorder = NO;
    ok.font = [NSFont systemFontOfSize:12];
    ok.target = self;
    ok.lineWidth = 0;
    ok.action = @selector(btnSelectAction:);
    self.btnSelect = ok;
    [self addSubview:self.btnSelect];
}

-(void)addCheckBtn{
    LMCheckboxButton *checkBtn = [[LMCheckboxButton alloc]initWithFrame:NSMakeRect(100, 2, 100, 50)];
    [checkBtn setButtonType:NSSwitchButton];
    [checkBtn setAction:@selector(onCheckButtonClick:)];
    checkBtn.target = self;
    checkBtn.allowsMixedState = YES;
    checkBtn.state = NSControlStateValueMixed;
    self.checkBtn = checkBtn;
    [self addSubview:self.checkBtn];
}

-(void)onCheckButtonClick:(NSButton *)sender{
    NSLog(@"onCheckButtonClick");
    if(self.checkButtonEvent){
        self.checkButtonEvent();
    }
}


- (void)deleteSelectItem:(NSMutableArray *)result {
    
}

- (IBAction)btnSelectAction:(id)sender{
    NSLog(@"actionDel");
    if (_selectActionHandler) _selectActionHandler();

}

@end
