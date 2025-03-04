//
//  SubCategoryCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "SubCategoryCellView.h"
#import "QMCategoryItem.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/QMFullDiskAccessManager.h>
#import <QMUICommon/GetFullDiskPopViewController.h>
#import "CleanerCantant.h"
#import <QMUICommon/LMViewHelper.h>
#import "LMCleanerDataCenter.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>

@interface SubCategoryCellView()
{
    
}

@property (nonatomic, strong) NSButton *noPrivacyBtn;
@property (nonatomic, strong) NSImageView *signImageView;

@end

@implementation SubCategoryCellView

-(CGFloat)getViewHeight {
    return 30;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.sizeLabel setFont:[NSFontHelper getLightSystemFont:12]];
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.checkButton.mas_right).offset(10);
        make.centerY.equalTo(self);
    }];
    [self.descLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel.mas_right).offset(10);
        make.centerY.equalTo(self);
    }];
    
    [self.sizeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-95);
        make.centerY.equalTo(self.titleLabel);
    }];
    [self.descLabel setFont:[NSFontHelper getLightSystemFont:12]];
}

-(NSString *)getSizeStr:(id)item{
    // 扫描完成，显示结果
    NSString * sizeStr = @"";
    NSUInteger fileSize = [item resultFileSize];
    if ([item isScaned]) {
        sizeStr = [NSString stringFromDiskSize:fileSize];
    }
    return sizeStr;
}

-(BOOL)isVersion1015{
    if(@available(macOS 10.15, *)){
         return YES;
    }
     return NO;
}

/// 通过判断可读，来判断是否有权限。
- (BOOL)isReadableDownloadPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *downloadPath = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES).firstObject;
    
    BOOL isWritable = [fileManager isReadableFileAtPath:downloadPath];
    return isWritable;
}

- (BOOL)shouldShowPrivacyAlertWithItem:(id)item {
    if ([QMFullDiskAccessManager getFullDiskAuthorationStatusWithoutLog] == QMFullDiskAuthorationStatusAuthorized) {
        return NO;
    }
    
    if (![item isScaned]) {
        return NO;
    }
    
    NSString *subCategoryID = [item subCategoryID] ?:@"";

    // 邮件
    if ([subCategoryID isEqualToString:@"301"]) {
        return YES;
    }
    
    // 垃圾篓
    if ([subCategoryID isEqualToString:@"1006"] && [self isVersion1015]) {
        return YES;
    }
    
    // 下载 且 无可读权限 且 扫描结果为0
    if ([subCategoryID isEqualToString:@"1007"] && ![self isReadableDownloadPath] && [item resultFileSize] == 0) {
        return YES;
    }
    
    return NO;
}

-(void)setCellData:(id)item {
    [super setCellData:item];
    [self.signImageView removeFromSuperview];
    if ([item tips] != nil) {
        [self.descLabel setStringValue:[item tips]];
    }
   BOOL featureTip =  [[NSUserDefaults standardUserDefaults]  boolForKey:@"kNewFeatureTip500"];
    if (!featureTip) {
        if ([[item subCategoryID] isEqualToString:@"20402"] || [[item subCategoryID] isEqualToString:@"20401"] ) {
            self.signImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 5, 5)];
            NSImage *image = [NSImage imageNamed:@"Ellipse" withClass:self.class];
            self.signImageView.image = image;
            [self addSubview:self.signImageView];
            
            [self.signImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.titleLabel.mas_right).offset(10);
                make.width.height.mas_equalTo(5);
                make.centerY.equalTo(self);
            }];
            
            [self.descLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.signImageView.mas_right).offset(6);
                make.centerY.equalTo(self);
            }];
        } else {
            if (self.signImageView) {
                [self.signImageView removeFromSuperview];
            }
            [self.descLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.titleLabel.mas_right).offset(10);
                make.centerY.equalTo(self);
            }];
        }
    } else {
        [self.descLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.titleLabel.mas_right).offset(10);
            make.centerY.equalTo(self);
        }];
    }
    //如果是邮件 有权限则继续往下 否则 return
    if ([self shouldShowPrivacyAlertWithItem:item]){
        //通知LMCleanBigViewController 弹出popViewController
        [self.sizeLabel setTextColor:[NSColor colorWithHex:0xFF9600]];
        [self.sizeLabel setStringValue:@""];
//
        if (self.noPrivacyBtn == nil) {
            self.noPrivacyBtn = [LMViewHelper createNormalTextButton:12 title:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_1553048057_1", nil, [NSBundle bundleForClass:[self class]], @"") textColor:[NSColor colorWithHex:0xFF9600] alignment:NSTextAlignmentRight];
            [self.noPrivacyBtn setFrame:NSMakeRect(775, 5, 100, 19)];
            [self addSubview:self.noPrivacyBtn];
            self.noPrivacyBtn.target = self;
            self.noPrivacyBtn.action = @selector(clickNoFullDiskPrivacyBtn);
        }
        return;
    }else{
        if (self.noPrivacyBtn != nil) {
            [self.noPrivacyBtn removeFromSuperview];
            self.noPrivacyBtn = nil;
        }
    }
    
    NSString *sizeStr = [self getSizeStr:item];
    if ([item isCleanning]){
        [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
        [self.sizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_sizeLabel_2", nil, [NSBundle bundleForClass:[self class]], @"")];
    }else{
        if ([item isScanning]) {
            [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
            [self.sizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_sizeLabel_3", nil, [NSBundle bundleForClass:[self class]], @"")];
        }else{
            if ([sizeStr isEqualToString:@"0 B"]) {
                if ([item showAction]) {
                    [self.sizeLabel setStringValue:sizeStr];
                }else{
                    [self.sizeLabel setTextColor:[NSColor colorWithHex:0x33D39D]];
                    [self.sizeLabel setStringValue:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_sizeLabel_4", nil, [NSBundle bundleForClass:[self class]], @"")];
                }
                if ([[item tips] isEqualToString:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_[item tips]_5", nil, [NSBundle bundleForClass:[self class]], @"")]) {
                    [self.descLabel setStringValue:@""];
                }
            }else if([item isScaned]){
                if ([item showAction]) {
                    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
                    [self.sizeLabel setStringValue:[NSString stringWithFormat:@"%@",sizeStr]];
                }else{
                    if ([item isCautious]) {
                        [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
                        [self.sizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_sizeLabel_6", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr]];
                    }else{
                        [self.sizeLabel setTextColor:[NSColor colorWithHex:0xE6704C]];
                        [self.sizeLabel setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SubCategoryCellView_setCellData_sizeLabel_7", nil, [NSBundle bundleForClass:[self class]], @""),sizeStr]];
                    }
                }
            }else{
                [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
                [self.sizeLabel setStringValue:@"0 B"];
            }
        }
    }
    
}

-(void)clickNoFullDiskPrivacyBtn{
    [[NSNotificationCenter defaultCenter] postNotificationName:START_TO_SHOW_FULL_DISK_PRIVACY_SETTING object:nil];
}

@end


