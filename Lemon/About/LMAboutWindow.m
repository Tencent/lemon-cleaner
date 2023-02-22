//
//  LMAboutWindow.m
//  Lemon
//
//  Copyright © 2022 Tencent. All rights reserved.
//

#import "LMAboutWindow.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import "NSTextField+Extension.h"
#import "NSColor+Extension.h"
#import "LMHoverButton.h"
#import <QMCoreFunction/LanguageHelper.h>
#import "QMDataConst.h"
#import <Masonry/Masonry.h>

@implementation LMAboutWindow

+ (instancetype)window {
    return [self windowWithVersionDate:nil];
}

+ (instancetype)windowWithVersionDate:(NSDate *)versionDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY"];
    NSString *versionTime = [formatter stringFromDate:versionDate ?: [NSDate date]];
    return [self _windowWithVersionTimeString:versionTime];
}

+ (instancetype)windowWithVersionTimeString:(NSString *)versionTimeString {
    if (versionTimeString.length > 0) {
        return [self _windowWithVersionTimeString:versionTimeString];
    } else {
        return [self window];
    }
}

+ (instancetype)_windowWithVersionTimeString:(NSString *)versionTimeString {
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;// | NSWindowStyleMaskMiniaturizable ;
    LMAboutWindow* windowAbout = [[self alloc] initWithContentRect:CGRectMake(0, 0, 360, 270) styleMask:style backing:NSBackingStoreBuffered defer:YES];
    windowAbout.backgroundColor = [LMAppThemeHelper getMainBgColor];
    //    CGFloat i =  _windowAbout.contentView.frame.size.height;
    //    CGFloat j =  _windowAbout.contentView.frame.size.width;
    
    windowAbout.title = NSLocalizedString(@"About_windowAboutTitle_lemon", @"");
    
    //    [LMAppThemeHelper setTitleColorForTextField:windowAbout];
    NSTextField* LemonProductName = [NSTextField labelWithStringCompat:NSLocalizedStringFromTableInBundle(@"LMMonitorTabController_rightAboutAction_LemonProductName_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    
    NSImageView* LemonIcon = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [LemonIcon setImage:[[NSBundle mainBundle] imageForResource:@"new_app_icon"]];
    [windowAbout.contentView addSubview:LemonIcon];
    [LemonIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView);
        make.top.equalTo(windowAbout.contentView.mas_top).offset(25);
        make.height.equalTo(@85);
        make.width.equalTo(@85);
    }];
    
    LemonProductName.font = [NSFont boldSystemFontOfSize:16];
    //    LemonProductName.textColor = [NSColor colorWithHex:0x333333 alpha:1.0];
    LemonProductName.textColor = [LMAppThemeHelper getTitleColor];
    [windowAbout.contentView addSubview:LemonProductName];
    [LemonProductName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView);
        make.top.equalTo(LemonIcon.mas_bottom).offset(12);
    }];
    
    // Version
    NSString* strVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* strBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* strVersionAndBuild = [NSString stringWithFormat:@"%@(%@)", strVersion, strBuild];
    NSTextField* LemonProductVersion = [NSTextField labelWithStringCompat:strVersionAndBuild];
    LemonProductVersion.font = [NSFont systemFontOfSize:12];
    LemonProductVersion.textColor = [NSColor colorWithHex:0x989A9E alpha:1.0];
    [windowAbout.contentView addSubview:LemonProductVersion];
    [LemonProductVersion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView);
        make.top.equalTo(LemonProductName.mas_bottom).offset(5);
    }];
    
    //服务协议
    LMHoverButton *serviceAgreeButton = [[LMHoverButton alloc] init];
    [serviceAgreeButton setTarget:self];
    [serviceAgreeButton setAction:@selector(serviceAgreeBtn)];
    NSMutableAttributedString *serviceAgreeAttrStr = [[NSMutableAttributedString alloc]
                                                      initWithString:NSLocalizedStringFromTableInBundle(@"Services Agreement", nil, [NSBundle bundleForClass:[self class]], @"")
                                                      attributes:@{NSForegroundColorAttributeName : [NSColor colorWithHex:0x989A9E alpha:1.0]}];
    [serviceAgreeButton setAttributedTitle:serviceAgreeAttrStr];
    serviceAgreeButton.font = [NSFont systemFontOfSize:12.0f];
    serviceAgreeButton.bordered = NO;
    serviceAgreeButton.imagePosition = NSImageLeft;
    [windowAbout.contentView addSubview:serviceAgreeButton];
    NSInteger width = 0;
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        width = 16.5;
    }
    [serviceAgreeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView).offset(-width);
        make.top.equalTo(LemonProductVersion.mas_bottom).offset(17);
        make.height.equalTo(@17);
    }];

    //分割线
    NSImageView *line_one = [[NSImageView alloc] init];
    [line_one setImage:[[NSBundle mainBundle] imageForResource:@"Line_about"]];
    [windowAbout.contentView addSubview:line_one];
    [line_one mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serviceAgreeButton.mas_centerY);
        make.trailing.equalTo(serviceAgreeButton.mas_leading).offset(-12);
        make.height.equalTo(@13);
    }];
    NSImageView *line_two = [[NSImageView alloc] init];
    [line_two setImage:[[NSBundle mainBundle] imageForResource:@"Line_about"]];
    [windowAbout.contentView addSubview:line_two];
    [line_two mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serviceAgreeButton.mas_centerY);
        make.leading.equalTo(serviceAgreeButton.mas_trailing).offset(12);
        make.height.equalTo(@13);
    }];

    //官网网站
    LMHoverButton *websiteButton = [[LMHoverButton alloc] init];
    [websiteButton setTarget:self];
    [websiteButton setAction:@selector(websiteBtn)];
    NSMutableAttributedString *websiteAttrStr = [[NSMutableAttributedString alloc]
                                                 initWithString:NSLocalizedStringFromTableInBundle(@"Website", nil, [NSBundle bundleForClass:[self class]], @"")
                                                 attributes:@{NSForegroundColorAttributeName : [NSColor colorWithHex:0x989A9E alpha:1.0]}];
    [websiteButton setAttributedTitle:websiteAttrStr];
    websiteButton.font = [NSFont systemFontOfSize:12.0f];
    websiteButton.bordered = NO;
    websiteButton.imagePosition = NSImageLeft;
    [windowAbout.contentView addSubview:websiteButton];
    [websiteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serviceAgreeButton.mas_centerY);
        make.trailing.equalTo(line_one.mas_leading).offset(-12);
    }];

    //隐私协议
    LMHoverButton *privacyPolicyButton = [[LMHoverButton alloc] init];
    [privacyPolicyButton setTarget:self];
    [privacyPolicyButton setAction:@selector(privacyPolicyBtn)];
    NSMutableAttributedString *privacyAttrStr = [[NSMutableAttributedString alloc]
                                                 initWithString:NSLocalizedStringFromTableInBundle(@"Privacy Policy", nil, [NSBundle bundleForClass:[self class]], @"")
                                                 attributes:@{NSForegroundColorAttributeName : [NSColor colorWithHex:0x989A9E alpha:1.0]}];
    [privacyPolicyButton setAttributedTitle:privacyAttrStr];
    privacyPolicyButton.font = [NSFont systemFontOfSize:12.0f];
    privacyPolicyButton.bordered = NO;
    privacyPolicyButton.imagePosition = NSImageLeft;
    [windowAbout.contentView addSubview:privacyPolicyButton];
    [privacyPolicyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(serviceAgreeButton.mas_centerY);
        make.leading.equalTo(line_two.mas_trailing).offset(12);
    }];
    
    // company
    NSTextField* LemonCompany = [NSTextField labelWithStringCompat:@"腾讯公司 版权所有"];
    LemonCompany.font = [NSFont systemFontOfSize:11];
    LemonCompany.textColor = [NSColor colorWithHex:0x989A9E alpha:1.0];
    [windowAbout.contentView addSubview:LemonCompany];
    [LemonCompany mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView);
        make.top.equalTo(serviceAgreeButton.mas_bottom).offset(11);
    }];
    if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
        [LemonCompany setHidden:YES];
    }else{
        [LemonCompany setHidden:NO];
    }
     
    // copyright
    NSString *copyRight = [NSString stringWithFormat:@"Copyright©2018-%@ Tencent. All Rights Reserved", versionTimeString];
    NSTextField* LemonCopyright = [NSTextField labelWithStringCompat:copyRight];
    LemonCopyright.font = [NSFont systemFontOfSize:11];
    LemonCopyright.textColor = [NSColor colorWithHex:0x989A9E alpha:1.0];
    [windowAbout.contentView addSubview:LemonCopyright];
    [LemonCopyright mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(windowAbout.contentView);
        make.top.equalTo(LemonCompany.mas_bottom).offset(5);
    }];
    
    return windowAbout;
}

+ (void)serviceAgreeBtn {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kQMServiceLicenseLink]];
}

+ (void)websiteBtn {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kQMOfficialWebsite]];
}

+ (void)privacyPolicyBtn {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kQMPrivacyLicenseLink]];
}

@end
