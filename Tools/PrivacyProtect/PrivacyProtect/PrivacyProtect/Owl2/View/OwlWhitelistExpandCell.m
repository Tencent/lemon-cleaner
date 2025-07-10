//
//  OwlWhitelistExpandCell.m
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlWhitelistExpandCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMUICommon/LMBorderButton.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/LMReferenceDefines.h>

static CGFloat const kCheckBoxAndLabelSpacing = 4;
static CGFloat const kBetweenBoxesSpacing = 20;
static CGFloat const kCheckBoxHW = 14;

CGFloat const OwlWLCellFoldHeight = 54;
CGFloat const OwlWLCellExpandHeight = 52;

@implementation OwlWhitelistExpandCell

- (void)setupSubviews {
    [self addSubview:self.foldContainer];
    [self addSubview:self.expandContainer];

    [self.foldContainer addSubview:self.appIcon];
    [self.foldContainer addSubview:self.tfAppName];
    [self.foldContainer addSubview:self.tfKind];
    [self.foldContainer addSubview:self.grantedPermissionStackView];
    [self.foldContainer addSubview:self.foldOrExpandButton];
    [self.foldContainer addSubview:self.removeBtn];
    
    [self.expandContainer addSubview:self.tfPermissionType];
    [self.expandContainer addSubview:self.cameraCheck];
    [self.expandContainer addSubview:self.checkLabelCamera];
    [self.expandContainer addSubview:self.audioCheck];
    [self.expandContainer addSubview:self.checkLabelAudio];
    [self.expandContainer addSubview:self.speakerCheck];
    [self.expandContainer addSubview:self.checkLabelSpeaker];
    [self.expandContainer addSubview:self.screenCheck];
    [self.expandContainer addSubview:self.checkLabelScreen];
    [self.expandContainer addSubview:self.automaticCheck];
    [self.expandContainer addSubview:self.checkLabelAutomatic];
}

- (void)setupSubviewsLayout {
    [self.foldContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(0);
        make.height.mas_equalTo(OwlWLCellFoldHeight);
    }];
    
    [self.expandContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.mas_equalTo(0);
        make.height.mas_equalTo(OwlWLCellExpandHeight);
    }];
    
    [self.tfPermissionType mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(OwlElementLeft - kOwlLeftRightMarginForTableCell);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.cameraCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.tfPermissionType.mas_right).offset(kBetweenBoxesSpacing);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(kCheckBoxHW, kCheckBoxHW));
    }];
    
    [self.checkLabelCamera mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.cameraCheck.mas_right).offset(kCheckBoxAndLabelSpacing);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.audioCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.checkLabelCamera.mas_right).offset(kBetweenBoxesSpacing);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(kCheckBoxHW, kCheckBoxHW));
    }];
    
    [self.checkLabelAudio mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.audioCheck.mas_right).offset(kCheckBoxAndLabelSpacing);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.speakerCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.checkLabelAudio.mas_right).offset(kBetweenBoxesSpacing);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(kCheckBoxHW, kCheckBoxHW));
    }];
    
    [self.checkLabelSpeaker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.speakerCheck.mas_right).offset(kCheckBoxAndLabelSpacing);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.screenCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.checkLabelSpeaker.mas_right).offset(kBetweenBoxesSpacing);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(kCheckBoxHW, kCheckBoxHW));
    }];
    
    [self.checkLabelScreen mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.screenCheck.mas_right).offset(kCheckBoxAndLabelSpacing);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.automaticCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.checkLabelScreen.mas_right).offset(kBetweenBoxesSpacing);
        make.centerY.mas_equalTo(0);
        make.size.mas_equalTo(NSMakeSize(kCheckBoxHW, kCheckBoxHW));
    }];
    
    [self.checkLabelAutomatic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.automaticCheck.mas_right).offset(kCheckBoxAndLabelSpacing);
        make.centerY.mas_equalTo(0);
    }];
    
    [super setupSubviewsLayout];
}

- (void)updateAppItem:(Owl2AppItem *)appItem {
    [super updateAppItem:appItem];
    self.cameraCheck.state = appItem.isWatchCamera;
    self.audioCheck.state = appItem.isWatchAudio;
    self.speakerCheck.state = appItem.isWatchSpeaker;
    self.screenCheck.state = appItem.isWatchScreen;
    self.automaticCheck.state = appItem.isWatchAutomatic;
    
    [self updateCheckLabel:self.checkLabelCamera state:self.cameraCheck.state];
    [self updateCheckLabel:self.checkLabelAudio state:self.audioCheck.state];
    [self updateCheckLabel:self.checkLabelSpeaker state:self.speakerCheck.state];
    [self updateCheckLabel:self.checkLabelScreen state:self.screenCheck.state];
    [self updateCheckLabel:self.checkLabelAutomatic state:self.automaticCheck.state];
}



- (NSImage *)imageFoldOrExpandButton {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [bundle imageForResource:@"owl_expand_arrow"];
}

- (BOOL)wantRemove{
    if (self.removeAction) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = [NSString stringWithFormat:LMLocalizedSelfBundleString(@"都取消信任会把app移出白名单。需要移除吗？", nil)];
        alert.informativeText = @"";
        [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"移除", nil)];
        [alert addButtonWithTitle:LMLocalizedSelfBundleString(@"保留", nil)];
        
        NSInteger responseTag = [alert runModal];
        if (responseTag == NSAlertFirstButtonReturn) {
            self.removeAction();
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (BOOL)allCheckBoxesByClosedWithWantRemove:(void(^)(BOOL remove))handler {
    if (self.audioCheck.state
        || self.cameraCheck.state
        || self.speakerCheck.state
        || self.screenCheck.state
        || self.automaticCheck.state) {
        return NO;
    }
    if (handler) {
        handler([self wantRemove]);
    }
    return YES;
}

- (void)checkCamera:(id)sender{
    if (self.cameraCheckAction) {
        @weakify(self);
        BOOL allClosed = [self allCheckBoxesByClosedWithWantRemove:^(BOOL remove) {
            @strongify(self);
            if (!remove) {
                self.cameraCheck.state = !self.cameraCheck.state;
            }
        }];
        
        if (!allClosed) {
            self.cameraCheckAction(self.cameraCheck);
        }
    }
    [self updateCheckLabel:self.checkLabelCamera state:self.cameraCheck.state];
}
- (void)checkAudio:(id)sender{
    if (self.audioCheckAction) {
        @weakify(self);
        BOOL allClosed = [self allCheckBoxesByClosedWithWantRemove:^(BOOL remove) {
            @strongify(self);
            if (!remove) {
                self.audioCheck.state = !self.audioCheck.state;
            }
        }];
        
        if (!allClosed) {
            self.audioCheckAction(self.audioCheck);
        }
    }
    [self updateCheckLabel:self.checkLabelAudio state:self.audioCheck.state];
}

- (void)checkSpeaker:(id)sender {
    if (self.speakerCheckAction) {
        @weakify(self);
        BOOL allClosed = [self allCheckBoxesByClosedWithWantRemove:^(BOOL remove) {
            @strongify(self);
            if (!remove) {
                self.speakerCheck.state = !self.speakerCheck.state;
            }
        }];
        
        if (!allClosed) {
            self.speakerCheckAction(self.speakerCheck);
        }
    }
    [self updateCheckLabel:self.checkLabelSpeaker state:self.speakerCheck.state];
}

- (void)checkScreen:(id)sender {
    if (self.screenCheckAction) {
        @weakify(self);
        BOOL allClosed = [self allCheckBoxesByClosedWithWantRemove:^(BOOL remove) {
            @strongify(self);
            if (!remove) {
                self.screenCheck.state = !self.screenCheck.state;
            }
        }];
        
        if (!allClosed) {
            self.screenCheckAction(self.screenCheck);
        }
    }
    [self updateCheckLabel:self.checkLabelScreen state:self.screenCheck.state];
}

- (void)checkAutomatic:(id)sender {
    if (self.automaticCheckAction) {
        @weakify(self);
        BOOL allClosed = [self allCheckBoxesByClosedWithWantRemove:^(BOOL remove) {
            @strongify(self);
            if (!remove) {
                self.automaticCheck.state = !self.automaticCheck.state;
            }
        }];
        
        if (!allClosed) {
            self.automaticCheckAction(self.automaticCheck);
        }
    }
    [self updateCheckLabel:self.checkLabelAutomatic state:self.automaticCheck.state];
}

- (void)updateCheckLabel:(NSTextField *)tf state:(BOOL)state {
//    if (state) {
//        tf.textColor = [LMAppThemeHelper getTitleColor];
//    } else {
//        tf.textColor = [NSColor colorWithHex:0x94979B];
//    }
}

#pragma mark - getter

- (NSView *)foldContainer {
    if (!_foldContainer) {
        _foldContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    }
    return _foldContainer;
}

- (NSView *)expandContainer {
    if (!_expandContainer) {
        _expandContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    }
    return _expandContainer;
}

- (NSTextField *)tfPermissionType {
    if (!_tfPermissionType) {
        _tfPermissionType = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"权限类型：", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _tfPermissionType;
}

- (LMCheckboxButton *)cameraCheck {
    if (!_cameraCheck) {
        _cameraCheck = [[LMCheckboxButton alloc] init];
        _cameraCheck.imageScaling = NSImageScaleProportionallyDown;
        _cameraCheck.title = @"";
        [_cameraCheck setButtonType:NSButtonTypeSwitch];
        _cameraCheck.allowsMixedState = NO;
        [_cameraCheck setTarget:self];
        [_cameraCheck setAction:@selector(checkCamera:)];
    }
    return _cameraCheck;
}

- (NSTextField *)checkLabelCamera {
    if (!_checkLabelCamera) {
        _checkLabelCamera = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"摄像头", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _checkLabelCamera;
}

- (LMCheckboxButton *)audioCheck {
    if (!_audioCheck) {
        _audioCheck = [[LMCheckboxButton alloc] init];
        _audioCheck.imageScaling = NSImageScaleProportionallyDown;
        _audioCheck.title = @"";
        [_audioCheck setButtonType:NSButtonTypeSwitch];
        _audioCheck.allowsMixedState = YES;
        [_audioCheck setTarget:self];
        [_audioCheck setAction:@selector(checkAudio:)];
    }
    return _audioCheck;
}

- (NSTextField *)checkLabelAudio {
    if (!_checkLabelAudio) {
        _checkLabelAudio = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"麦克风", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _checkLabelAudio;
}

- (LMCheckboxButton *)speakerCheck {
    if (!_speakerCheck) {
        _speakerCheck = [[LMCheckboxButton alloc] init];
        _speakerCheck.imageScaling = NSImageScaleProportionallyDown;
        _speakerCheck.title = @"";
        [_speakerCheck setButtonType:NSButtonTypeSwitch];
        _speakerCheck.allowsMixedState = YES;
        [_speakerCheck setTarget:self];
        [_speakerCheck setAction:@selector(checkSpeaker:)];
    }
    return _speakerCheck;
}

- (NSTextField *)checkLabelSpeaker {
    if (!_checkLabelSpeaker) {
        _checkLabelSpeaker = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"录制音频", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _checkLabelSpeaker;
}

- (LMCheckboxButton *)screenCheck {
    if (!_screenCheck) {
        _screenCheck = [[LMCheckboxButton alloc] init];
        _screenCheck.imageScaling = NSImageScaleProportionallyDown;
        _screenCheck.title = @"";
        [_screenCheck setButtonType:NSButtonTypeSwitch];
        _screenCheck.allowsMixedState = YES;
        [_screenCheck setTarget:self];
        [_screenCheck setAction:@selector(checkScreen:)];
    }
    return _screenCheck;
}

- (NSTextField *)checkLabelScreen {
    if (!_checkLabelScreen) {
        _checkLabelScreen = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"截屏&录屏", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _checkLabelScreen;
}

- (LMCheckboxButton *)automaticCheck {
    if (!_automaticCheck) {
        _automaticCheck = [[LMCheckboxButton alloc] init];
        _automaticCheck.imageScaling = NSImageScaleProportionallyDown;
        _automaticCheck.title = @"";
        [_automaticCheck setButtonType:NSButtonTypeSwitch];
        _automaticCheck.allowsMixedState = YES;
        [_automaticCheck setTarget:self];
        [_automaticCheck setAction:@selector(checkAutomatic:)];
    }
    return _automaticCheck;
}

- (NSTextField *)checkLabelAutomatic {
    if (!_checkLabelAutomatic) {
        _checkLabelAutomatic = [OwlWhitelistCell buildLabel:LMLocalizedSelfBundleString(@"自动操作", nil) font:[NSFontHelper getLightSystemFont:12] color:[LMAppThemeHelper getTitleColor]];
    }
    return _checkLabelAutomatic;
}

@end
