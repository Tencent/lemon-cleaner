//
//  AppResultTableCellView.m
//  FMDBDemo
//
//  
//  Copyright © 2018年 tencent. All rights reserved.
//

#import <Masonry/Masonry.h>
#import "PrivacyAppTableCellView.h"
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import "PrivacyDataManager.h"
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/GetFullDiskPopViewController.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface PrivacyAppTableCellView () <NSGestureRecognizerDelegate>

@end


@implementation PrivacyAppTableCellView


- (instancetype)initWithFrame:(NSRect)frameRect {

    if (self = [super initWithFrame:frameRect]) {
        [self setupSubViews];
        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAfterFullDiskAccessSetting) name:AFTER_FULL_DISK_PRIVACY_SEETING_NEED_RESCAN object:nil];
    }

    return self;
}

//- (void)dealloc{
//      [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

- (void)setupSubViews {

    NSImageView *imageView = [LMViewHelper createNormalImageView];
    [self addSubview:imageView];
    self.appImageView = imageView;

    NSButton *checkButton = [[LMCheckboxButton alloc] init];
    self.checkButton = checkButton;
    checkButton.imageScaling = NSImageScaleProportionallyDown;
    checkButton.title = @"";
    [checkButton setButtonType:NSButtonTypeSwitch];
    checkButton.allowsMixedState = YES; // YES: 三种状态 -1, 1, 0, NO: 1 和 0; // -1 代码 mix 的状态, 显示的 - 而非 对号或者空白.
    [self addSubview:checkButton];

    // MARK: NsButton
    // toggle button 的 on / off state 可以通过 image 和 alternateImage 选择展示不同的.
    // 通过 setEnable 来决定是否可与用户交互, 通过 setState/ preformClick 更改状态.
    // 可以复写 toggleButton 方法 来 custom Button.
    // imageButton 实现:     [imageButton setButtonType:NSRoundedBezelStyle]; imageButton.bordered = NO;

//    checkButton.wantsLayer = YES;
//    checkButton.layer.backgroundColor = [NSColor blueColor].CGColor;

//    MyImageView *imageView = [[MyImageView alloc] init];
//    imageView.image = [NSImage imageNamed:NSImageNameApplicationIcon];
//    [self addSubview:imageView];
//    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.height.mas_equalTo(50);
//        make.centerY.equalTo(checkButton.superview);
//        make.left.equalTo(checkButton.superview).offset(150);
//    }];
//    NSClickGestureRecognizer *clickGesture = [[NSClickGestureRecognizer alloc]initWithTarget:self action: @selector(test)];
//    clickGesture.delegate = self;
//    [imageView addGestureRecognizer:clickGesture];
//
//    NSButton *imageButton = [[NSButton alloc] init];
//    [imageButton setButtonType:NSButtonTypeOnOff];
//    imageButton.bordered = NO;
//    imageButton.image = [NSImage imageNamed:NSImageNameBluetoothTemplate];
//    [self addSubview:imageButton];
//    [imageButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.height.mas_equalTo(50);
//        make.centerY.equalTo(checkButton.superview);
//        make.left.equalTo(checkButton.superview).offset(250);
//    }];

    NSTextField *appNameLabel = [LMViewHelper createNormalLabel:14 fontColor:[LMAppThemeHelper getTitleColor]];
    [LMAppThemeHelper setTitleColorForTextField:appNameLabel];
    self.appNameLabel = appNameLabel;
    [self addSubview:appNameLabel];

    NSTextField *accountLabel = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor]];
    [LMAppThemeHelper setTitleColorForTextField:accountLabel];
    self.accountLabel = accountLabel;
    [self addSubview:accountLabel];
    
    NSTextField *countLabel = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    countLabel.font = [NSFontHelper getLightSystemFont:12];
    [LMAppThemeHelper setTextColorName:@"outlineview_subitem_text_color" defaultColor:[NSColor colorWithHex:0x94979B] for:countLabel];
    [self addSubview:countLabel];
    self.countLabel = countLabel;

    [checkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(14);
        make.left.equalTo(self);
        make.centerY.equalTo(self);
    }];

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@32);
        make.centerY.equalTo(self);
        make.left.equalTo(checkButton.mas_right).offset(10);
    }];

    [appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageView.mas_right).offset(14);
        make.centerY.equalTo(self);
    }];

    [accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(appNameLabel.mas_right).offset(6);
        make.centerY.equalTo(self);
    }];
    
    [countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(accountLabel.mas_right).offset(14);
        make.centerY.equalTo(self);
    }];
}


//- (BOOL)gestureRecognizer:(NSGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(NSGestureRecognizer *)otherGestureRecognizer{
//    
//    return YES;
//}
//- (void)test{
//    NSLog(@"test... gesture");
//}

- (void)updateViewBy:(PrivacyAppData *)appData {
    self.checkButton.state = appData.state;
    self.appImageView.image = [PrivacyDataManager getBrowserIconByType:appData.appType];
    self.appNameLabel.stringValue = appData.appName;
    
    // 对于多账户的问题,appName 视觉上进行区分.
    if(appData.showAccount){
        self.accountLabel.stringValue = appData.showAccount;
    }else{
        self.accountLabel.stringValue = @"";
    }
    
    

    NSMutableAttributedString *selectedAttributeStr;
    
    NSDictionary *normalAttributes = @{ NSForegroundColorAttributeName:[NSColor colorWithHex:0x94979B],
                                       NSFontAttributeName: [NSFontHelper getLightSystemFont:12]
                                       };
    
    NSDictionary *colorAttributes = @{NSForegroundColorAttributeName:[NSColor colorWithHex:0xFFAA09],
                                       NSFontAttributeName: [NSFontHelper getLightSystemFont:12]
                                      };
    if (appData.selectedSubItemNum <= 0) {
        
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyAppTableCellView_updateViewBy_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), appData.totalSubNum];
        selectedAttributeStr = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];
      
    } else {
        NSString *prefixString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyAppTableCellView_updateViewBy_NSString_2", nil, [NSBundle bundleForClass:[self class]], @""), appData.totalSubNum];
        NSString *numberString = [NSString stringWithFormat:@"%li", appData.selectedSubItemNum];
        NSString *totalString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PrivacyAppTableCellView_updateViewBy_NSString_3", nil, [NSBundle bundleForClass:[self class]], @""), prefixString,numberString];
        selectedAttributeStr = [[NSMutableAttributedString alloc] initWithString:totalString attributes:normalAttributes];
        [selectedAttributeStr addAttributes:colorAttributes range:NSMakeRange(prefixString.length, numberString.length)];
    }
//    self.countLabel.stringValue = selectedStr;
    self.countLabel.attributedStringValue = selectedAttributeStr;

    if(appData.totalSubNum == 0){
        self.countLabel.attributedStringValue = [[NSMutableAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"PrivacyAppTableCellView_updateViewBy_1553135349_4", nil, [NSBundle bundleForClass:[self class]], @"") attributes:normalAttributes];
    }
    
    // 如果是 safari 浏览器,在10.14之上的系统上, 如果没有完全磁盘访问权限, 无法扫描 safari的数据. 需要用户引导给予权限.
    if(appData.appType == PRIVACY_APP_SAFARI && !_hasFullDiskAccessAuthority){
        [self addFullDiskAccessSetttingBtn];
    }else{
        [self removeFullDiskAccessViews];
    }
}

@end

