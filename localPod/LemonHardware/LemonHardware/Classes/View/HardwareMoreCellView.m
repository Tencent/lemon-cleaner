//
//  HardwareMoreCellView.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareMoreCellView.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>

@implementation HardwareMoreCellView

-(void)awakeFromNib{
    [super awakeFromNib];
}

-(void)setupUI{
    [super setupUI];
    [self.iconImageView setHidden:YES];
    [self.categoryTextField setHidden:YES];
    [self.topLineView setHidden:YES];
    [self.topLineView setAlphaValue:0.0];
    [self.topLineView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
}

-(void)layoutView{
    [super layoutView];
    
    CGFloat offset = 0;
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        offset = 90;
    }else{
        offset = 140;
    }
    [self.name1TextField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(offset);
        make.centerY.equalTo(self);
    }];
    
    [self.value1TextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.name1TextField.mas_right).offset(10);
        make.centerY.equalTo(self);
        make.width.lessThanOrEqualTo(@180);
    }];
    
    [self.name2TextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.value1TextField.mas_right).offset(20);
        make.centerY.equalTo(self);
    }];
    
    [self.value2TextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.name2TextField.mas_right).offset(10);
        make.centerY.equalTo(self);
    }];
    
    [self.name3TextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.value2TextField.mas_right).offset(20);
        make.centerY.equalTo(self);
    }];
    
    [self.value3TextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.name3TextField.mas_right).offset(10);
        make.centerY.equalTo(self);
    }];
}

-(void)setCellWithArr:(HardwareBaseModel *)hardwareInfoModel{
    HardwareInfoModel *infoModel = (HardwareInfoModel *)hardwareInfoModel;
    if (infoModel == nil) {
        return;
    }
    //第一组
    [self setStringValue:infoModel.name1 toTextField:self.name1TextField];
    [self setStringValue:infoModel.value1 toTextField:self.value1TextField];

    //第二组
    [self setStringValue:infoModel.name2 toTextField:self.name2TextField];
    [self setStringValue:infoModel.value2 toTextField:self.value2TextField];

    //第三组
    if (infoModel.name3 == nil) {
        [self.name3TextField setHidden:YES];
        [self.value3TextField setHidden:YES];
    }else{
        [self.name3TextField setHidden:NO];
        [self.value3TextField setHidden:NO];
        [self setStringValue:infoModel.name3 toTextField:self.name3TextField];
        [self setStringValue:infoModel.value3 toTextField:self.value3TextField];
    }
}

-(void)setStringValue:(NSString *)value toTextField:(NSTextField *)textField{
    if (value != nil) {
        [textField setStringValue:value];
    }
}

@end
