//
//  ToolCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ToolCellView.h"
#import <QMUICommon/NSFontHelper.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation ToolCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imageView.mas_right).offset(10);
        make.top.equalTo(self.imageView).offset(5);
    }];
    [LMAppThemeHelper setTitleColorForTextField:self.textField];
    [self.toolDesc setFont:[NSFontHelper getLightSystemFont:16]];
    [self.toolDesc mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textField.mas_left);
        make.top.equalTo(self.textField.mas_bottom).offset(3);
    }];
    if ([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese) {
        [self.experienceBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.imageView.mas_right).offset(316);
            make.top.equalTo(self.imageView.mas_top).offset(3);
            make.width.equalTo(@90);
            make.height.equalTo(@30);
        }];
    }
    
    [self.experienceBtn setFont:[NSFontHelper getLightSystemFont:13]];
    [self.experienceBtn setTitle:NSLocalizedStringFromTableInBundle(@"ToolCellView_awakeFromNib_experienceBtn_1", nil, [NSBundle bundleForClass:[self class]], @"")];
}

-(void)setCellWithToolModel:(ToolModel *)toolModel {
    NSBundle *mainBundle = [NSBundle mainBundle];
    self.imageView.image = [mainBundle imageForResource:toolModel.toolPicName];
    self.textField.stringValue = toolModel.toolName;
    self.toolDesc.stringValue = toolModel.toolDesc;
}

@end
