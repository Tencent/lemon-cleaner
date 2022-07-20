//
//  HardwareCellView.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "HardwareCellView.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface HardwareCellView()

@end

@implementation HardwareCellView

-(id)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupUI];
        [self layoutView];
    }
    
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setupUI];
    [self layoutView];
}

-(void)setupUI{
    NSImageView *iconImageView = [[NSImageView alloc] init];
    //    [iconImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self addSubview:iconImageView];
    self.iconImageView = iconImageView;
    
    NSTextField *categoryTextField = [[NSTextField alloc] init];
    categoryTextField.textColor = [LMAppThemeHelper getThirdTextColor];
    categoryTextField.font = [NSFont systemFontOfSize:14];
    categoryTextField.editable = NO;
    categoryTextField.bordered = NO;
    categoryTextField.drawsBackground = NO;
    [self addSubview:categoryTextField];
    self.categoryTextField = categoryTextField;
    
    //name1
    NSTextField *name1TextField = [[NSTextField alloc] init];
    name1TextField.textColor = [NSColor colorWithHex:0x94979b];
    name1TextField.font = [NSFont systemFontOfSize:12];
    name1TextField.editable = NO;
    name1TextField.bordered = NO;
    name1TextField.drawsBackground = NO;
    [self addSubview:name1TextField];
    self.name1TextField = name1TextField;
    
    //value1
    NSTextField *value1TextField = [[NSTextField alloc] init];
    value1TextField.textColor = [LMAppThemeHelper getThirdTextColor];
    value1TextField.font = [NSFont systemFontOfSize:12];
    value1TextField.editable = NO;
    value1TextField.bordered = NO;
    value1TextField.drawsBackground = NO;
    value1TextField.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:value1TextField];
    self.value1TextField = value1TextField;
    
    //name2
    NSTextField *name2TextField = [[NSTextField alloc] init];
    name2TextField.textColor = [NSColor colorWithHex:0x94979b];
    name2TextField.font = [NSFont systemFontOfSize:12];
    name2TextField.editable = NO;
    name2TextField.bordered = NO;
    name2TextField.drawsBackground = NO;
    [self addSubview:name2TextField];
    self.name2TextField = name2TextField;
    
    //value2
    NSTextField *value2TextField = [[NSTextField alloc] init];
    value2TextField.textColor = [LMAppThemeHelper getThirdTextColor];
    value2TextField.font = [NSFont systemFontOfSize:12];
    value2TextField.editable = NO;
    value2TextField.bordered = NO;
    value2TextField.drawsBackground = NO;
    [self addSubview:value2TextField];
    self.value2TextField = value2TextField;
    
    //name3
    NSTextField *name3TextField = [[NSTextField alloc] init];
    name3TextField.textColor = [NSColor colorWithHex:0x94979b];
    name3TextField.font = [NSFont systemFontOfSize:12];
    name3TextField.editable = NO;
    name3TextField.bordered = NO;
    name3TextField.drawsBackground = NO;
    [self addSubview:name3TextField];
    self.name3TextField = name3TextField;
    
    //value3
    NSTextField *value3TextField = [[NSTextField alloc] init];
    value3TextField.textColor = [LMAppThemeHelper getThirdTextColor];
    value3TextField.font = [NSFont systemFontOfSize:12];
    value3TextField.editable = NO;
    value3TextField.bordered = NO;
    value3TextField.drawsBackground = NO;
    [self addSubview:value3TextField];
    self.value3TextField = value3TextField;
    
    NSView* topLineView = [[NSView alloc] init];
    CALayer *topLineLayer = [[CALayer alloc] init];
    topLineLayer.backgroundColor = [NSColor colorWithHex:0xF1F1F1].CGColor;
    topLineView.layer = topLineLayer;
    [self addSubview:topLineView];
    self.topLineView = topLineView;
    
    NSImageView *spaceIcon = [[NSImageView alloc] init];
    NSImage *image = [NSImage imageNamed:@"ic_analyze" withClass:[self class]];
    spaceIcon.image = image;
    [self addSubview:spaceIcon];
    self.spaceIcon = spaceIcon;
    self.spaceIcon.hidden = YES;

    NSButton *spaceButton = [[NSButton alloc] init];
    spaceButton.bordered = NO;
    NSDictionary *dicAtt = @{NSForegroundColorAttributeName: [NSColor colorWithRed:25/255.0 green:131/255.0 blue:247/255.0 alpha:1/1.0]};
    spaceButton.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Disk Analyzer", nil, [NSBundle bundleForClass:[self class]], @"") attributes:dicAtt];
    spaceButton.font = [NSFont systemFontOfSize:12];
    [self addSubview:spaceButton];
    self.spaceButton = spaceButton;
    self.spaceButton.hidden = YES;
    
    [self.spaceButton  setTarget:self];
    [self.spaceButton setAction:@selector(buttonClick:)];
}
- (void)buttonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(HardwareCellViewDidSpaceButon)]) {
        [self.delegate HardwareCellViewDidSpaceButon];
    }
    
}
- (void)drawRect:(NSRect)dirtyRect{
    [LMAppThemeHelper setDivideLineColorFor:self.topLineView];
}

-(void)layoutView{
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.centerY.equalTo(self);
        make.width.equalTo(@32);
        make.height.equalTo(@32);
    }];
    
    [self.categoryTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).offset(9);
        make.centerY.equalTo(self);
    }];
    
    CGFloat offset = 0;
    if ([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeChinese) {
        offset = 106;
    }else{
        offset = 156;
    }
    [self.name1TextField mas_makeConstraints:^(MASConstraintMaker *make) {
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
    
    //
    [self.spaceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.value3TextField.mas_right).offset(20);
        make.centerY.equalTo(self);
        make.width.equalTo(@16);
        make.height.equalTo(@16);
    }];
    //
    [self.spaceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.spaceIcon.mas_right).offset(8);
        make.centerY.equalTo(self);
    }];
    
    [self.topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self);
        make.width.equalTo(self);
        make.height.equalTo(@1);
    }];
}

-(void)setCellWithArr:(HardwareBaseModel *)hardwareModel{
    HardwareModel *hardModel = (HardwareModel *)hardwareModel;
    if (hardModel == nil) {
        return;
    }
    if ([hardModel.iconName isEqualToString:@"disk"]) {
        [self.topLineView setHidden:YES];
        self.spaceButton.hidden = NO;
        self.spaceIcon.hidden = NO;
    }else{
        [self.topLineView setHidden:NO];
    }
    //图片和类别
    NSImage *image = [NSImage imageNamed:hardModel.iconName withClass:[self class]];
    [self.iconImageView setImage:image];
    if (hardModel.categoryName != nil) {
        [self.categoryTextField setStringValue:hardModel.categoryName];
    }
    
    if ([hardModel.infoArr count] > 0) {
        HardwareInfoModel *infoModel = [hardModel.infoArr objectAtIndex:0];
        //第一组
        if (infoModel.name1 != nil) {
            [self.name1TextField setStringValue:infoModel.name1];
        }
        if (infoModel.value1 != nil) {
            [self.value1TextField setStringValue:infoModel.value1];
        }
        
        //第二组
        if (infoModel.name2 != nil) {
            [self.name2TextField setStringValue:infoModel.name2];
        }
        if (infoModel.value2 != nil) {
            [self.value2TextField setStringValue:infoModel.value2];
        }
        
        //第三组
        if (infoModel.name3 == nil) {
            [self.name3TextField setHidden:YES];
            [self.value3TextField setHidden:YES];
        }else{
            [self.name3TextField setHidden:NO];
            [self.value3TextField setHidden:NO];
            if (infoModel.name3 != nil) {
                [self.name3TextField setStringValue:infoModel.name3];
            }
            if (infoModel.value3 != nil) {
                [self.value3TextField setStringValue:infoModel.value3];
            }
        }
    }
}

@end
