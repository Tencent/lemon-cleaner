//
//  CategoryCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "CategoryCellView.h"
#import <Masonry/Masonry.h>
#import "QMCategoryItem.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface CategoryCellView()
{
    
}
@end

@implementation CategoryCellView

-(instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self) {
        
    }
    
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconView.mas_right).offset(12);
        make.centerY.equalTo(self);
    }];
    
    [self.sizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel.mas_right).offset(7);
        make.centerY.equalTo(self.titleLabel);
    }];
    
    [self.sizeSelectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.sizeLabel.mas_right).offset(5);
        make.centerY.equalTo(self.sizeLabel);
    }];
    
    [self.sizeSelectLabel setTextColor:[NSColor colorWithHex:0xFFBE46]];
    [self.sizeSelectLabel setFont:[NSFontHelper getLightSystemFont:14]];

}

-(CGFloat)getViewHeight {
    return 40;
}

-(void)setCellData:(id)item {
    if (![item isScanning]) {
        [super setCellData:item];
    }
    NSString *categoryId = [item categoryID];
    if ([categoryId isEqualToString:@"1"]) {
        [self.categoryProgessView setProgressType:ProgressViewTypeSys];
    }else if ([categoryId isEqualToString:@"2"]){
        [self.categoryProgessView setProgressType:ProgressViewTypeApp];
    }else if ([categoryId isEqualToString:@"3"]){
        [self.categoryProgessView setProgressType:ProgressViewTypeInt];
    }
    
    if ([item showHighlight]) {
        if ([[item categoryID] isEqualToString:@"1"]) {
            [self.iconView setImage:[NSImage imageNamed:@"sys_enable" withClass:[self class]]];
        }else if ([[item categoryID] isEqualToString:@"2"]){
            [self.iconView setImage:[NSImage imageNamed:@"app_enable" withClass:[self class]]];
        }else if ([[item categoryID] isEqualToString:@"3"]){
            [self.iconView setImage:[NSImage imageNamed:@"int_enable" withClass:[self class]]];
        }
        [self.titleLabel setTextColor:[NSColor colorWithHex:0xFFBE46]];
    }else{
        if ([[item categoryID] isEqualToString:@"1"]) {
            [self.iconView setImage:[NSImage imageNamed:@"sys_disable" withClass:[self class]]];
        }else if ([[item categoryID] isEqualToString:@"2"]){
            [self.iconView setImage:[NSImage imageNamed:@"app_disable" withClass:[self class]]];
        }else if ([[item categoryID] isEqualToString:@"3"]){
            [self.iconView setImage:[NSImage imageNamed:@"int_disable" withClass:[self class]]];
        }
        [self.titleLabel setTextColor:[LMAppThemeHelper getTitleColor]];
    }
    
    
    if ([item isScanning]) {
        [self.titleLabel setStringValue:[item title]];
        [self.sizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"CategoryCellView_setCellData_sizeLabel_1", nil, [NSBundle bundleForClass:[self class]], @"")];
        [self.sizeSelectLabel setHidden:YES];
        [self.categoryProgessView startAni];
    }else if ([item isCleanning]){
        [self.sizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"CategoryCellView_setCellData_sizeLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
        [self.sizeSelectLabel setHidden:YES];
        [self.categoryProgessView startAni];
    }else{
        NSString *sizeTotalStr = [NSString stringFromDiskSize:[item resultFileSize]];
        [self.sizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"CategoryCellView_setCellData_sizeLabel_3", nil, [NSBundle bundleForClass:[self class]], @""), sizeTotalStr]];
        [self.sizeSelectLabel setHidden:NO];
        NSString *sizeSelectStr = [self getSizeStr:item];
        [self.sizeSelectLabel setStringValue:sizeSelectStr];
        [self.categoryProgessView stopAni];
//        [self.titleLabel setTextColor:[self getScanTitleColor]];
    }
}

-(NSColor *)getScanTitleColor{
    if (@available(macOS 10.14, *)) {
        return [NSColor colorNamed:@"subcatory_item_title_color" bundle:[NSBundle mainBundle]];
    } else {
        return [NSColor colorWithHex:0x515151];
    }
}


@end
