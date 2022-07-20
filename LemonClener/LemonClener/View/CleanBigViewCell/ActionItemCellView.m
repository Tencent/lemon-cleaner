//
//  ActionItemCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ActionItemCellView.h"
#import "QMActionItem.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation ActionItemCellView

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.sizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-95);
        make.centerY.equalTo(self.titleLabel);
    }];
}

-(NSString *)getSizeStr:(id)item{
    // 扫描完成，显示结果
    NSString * sizeStr = NSLocalizedStringFromTableInBundle(@"ActionItemCellView_getSizeStr_ sizeStr _1", nil, [NSBundle bundleForClass:[self class]], @"");
    NSUInteger fileSize = [item resultFileSize];
    if (fileSize > 0) {
        sizeStr = [NSString stringFromDiskSize:fileSize];
    }
    return sizeStr;
}


-(void)setCellData:(id)item {
    [super setCellData:item];
    NSString *sizeStr = [self getSizeStr:item];
    if ([sizeStr isEqualToString:NSLocalizedStringFromTableInBundle(@"ActionItemCellView_setCellData_sizeStr_1", nil, [NSBundle bundleForClass:[self class]], @"")]){
        [self.sizeLabel setTextColor:[NSColor colorWithHex:0x33D39D]];
    }else{
        if ([item recommend]) {
            [self.sizeLabel setTextColor:[LMAppThemeHelper getTitleColor]];
            [self.sizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ActionItemCellView_setCellData_sizeLabel_2", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr]];
        }else{
            [self.sizeLabel setTextColor:[NSColor colorWithHex:0xE6704C]];
            [self.sizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"ActionItemCellView_setCellData_sizeLabel_3", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr]];
        }
    }
     [self.titleLabel setTextColor:[LMAppThemeHelper getTitleColor]];
//    if ([[item resultItemArray] count] == 0) {
//        [self.checkButton setHidden:YES];
//    }else{
//        [self.checkButton setHidden:NO];
//    }
}


@end
