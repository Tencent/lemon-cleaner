//
//  HardwareElectircCellView.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareElectircCellView.h"
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface HardwareElectircCellView()

@property (nonatomic, weak) NSImageView *elecImageView;

@end

@implementation HardwareElectircCellView

-(void)awakeFromNib{
    [super awakeFromNib];
}

-(void)setupUI{
    [super setupUI];
    NSImageView *elecImageView = [[NSImageView alloc] init];
    [self addSubview:elecImageView];
    self.elecImageView = elecImageView;
}

-(void)setCellWithArr:(HardwareBaseModel *)hardwareModel{
    HardwareModel *hardModel = (HardwareModel *)hardwareModel;
    if (hardModel == nil) {
        return;
    }
    
    //通过电池是充电来调整布局
    if (hardModel.isExternalCharge) {
        [self.elecImageView setHidden:NO];
        [self.elecImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.name1TextField.mas_right).offset(4);
            make.centerY.equalTo(self);
            make.height.equalTo(@20);
            make.width.equalTo(@20);
        }];
        
        [self.value1TextField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.elecImageView.mas_right).offset(1);
            make.centerY.equalTo(self);
            make.width.lessThanOrEqualTo(@180);
        }];
        NSString *percentString = hardModel.elecPercentage;
        NSInteger percent = 0;
        if ((percentString != nil) || (![percentString isEqualToString:@""])) {
            @try{
                NSString *onlyNumStr = [percentString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [percentString length])];
                percent = [onlyNumStr integerValue];
            }@catch(NSException *exception){
                NSLog(@"setCellWithArr1 exception = %@", exception);
                [self.value1TextField setTextColor:[LMAppThemeHelper getTitleColor]];
            }
        }
        //根据是否在充电更换图标
        if (!hardModel.isCharge && (percent == 100)) {
            [self.elecImageView setImage:[NSImage imageNamed:@"charge_full" withClass:[self class]]];
        }else{
            [self.elecImageView setImage:[NSImage imageNamed:@"charge_in" withClass:[self class]]];
        }
        
        [self.value1TextField setTextColor:[NSColor colorWithHex:0x06d99a]];
    }else{
        [self.elecImageView setHidden:YES];
        
        //还原位置
        [self.value1TextField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.name1TextField.mas_right).offset(10);
            make.centerY.equalTo(self);
            make.width.lessThanOrEqualTo(@180);
        }];
        
        NSString *percentString = hardModel.elecPercentage;
        if ((percentString != nil) && (![percentString isEqualToString:@""])) {
            @try{
                NSString *onlyNumStr = [percentString stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [percentString length])];
                NSInteger percent = [onlyNumStr integerValue];
                if (percent <= 10) {
                    [self.value1TextField setTextColor:[NSColor colorWithHex:0xe6704c]];
                }else if (percent <= 20){
                    [self.value1TextField setTextColor:[NSColor colorWithHex:0xffaa09]];
                }else{
                    [self.value1TextField setTextColor:[LMAppThemeHelper getTitleColor]];
                }
            }@catch(NSException *exception){
                NSLog(@"setCellWithArr2 exception = %@", exception);
                [self.value1TextField setTextColor:[LMAppThemeHelper getTitleColor]];
            }
        }
    }
    
    [super setCellWithArr:hardwareModel];
}

@end
