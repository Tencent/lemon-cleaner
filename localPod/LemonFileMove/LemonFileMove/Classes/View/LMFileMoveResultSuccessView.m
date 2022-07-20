//
//  LMFileMoveResultSuccessView.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultSuccessView.h"
#import "LMFileMoveCommonDefines.h"
#import "LMRectangleButton.h"
#import <QMUICommon/LMBorderButton.h>

@interface LMFileMoveResultSuccessView ()

@property (nonatomic, strong) NSImageView *circleView;
@property (nonatomic, strong) NSTextField *spaceLabel;
@property (nonatomic, strong) NSTextField *spaceDescLabel;

@property (nonatomic, strong) NSTextField *moveDoneLabel;

@property (nonatomic, strong) NSStackView *stackView;
@property (nonatomic, strong) NSTextField *targetPathLabel;
@property (nonatomic, strong) NSTextField *showInFinderLabel;

@property (nonatomic, strong) LMBorderButton *returnButton;

@end

@implementation LMFileMoveResultSuccessView

+ (instancetype)resultViewWithType:(LMFileMoveTargetPathType)type releaseSpace:(long long)releaseSpace targetFilePath:(NSString *)targetFilePath {
    LMFileMoveResultSuccessView *view = [[LMFileMoveResultSuccessView alloc] init];
    [view setupViews];
    [view updateWithType:type releaseSpace:releaseSpace targetFilePath:targetFilePath];
    return view;
}

- (void)setupViews {
    self.circleView = [[NSImageView alloc] init];
    [self addSubview:self.circleView];
    [self.circleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(140);
        make.size.mas_equalTo(CGSizeMake(192, 192));
    }];
    
    self.spaceLabel = [NSTextField labelWithStringCompat:@"1GB"];
    [LMAppThemeHelper setTitleColorForTextField:self.spaceLabel];
    self.spaceLabel.font = [NSFont systemFontOfSize:24];
    self.spaceLabel.alignment = NSTextAlignmentCenter;
    [self.circleView addSubview:self.spaceLabel];
    [self.spaceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.circleView);
        make.top.equalTo(self.circleView).offset(72);
        make.width.equalTo(self.circleView);
    }];
    
    self.spaceDescLabel = [NSTextField labelWithStringCompat:@""];
    self.spaceDescLabel.font = [NSFont systemFontOfSize:16];
    self.spaceDescLabel.alignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    LM_APPEND_ICON_AND_STRING(text, LM_IMAGE_NAMED(@"file_move_result_done_icon"), CGSizeMake(16, 16), LM_LOCALIZED_STRING(@" Free up space"), [NSFont systemFontOfSize:16], LM_COLOR_GRAY);
    self.spaceDescLabel.attributedStringValue = text;
    [self.circleView addSubview:self.spaceDescLabel];
    [self.spaceDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.circleView);
        make.top.equalTo(self.spaceLabel.mas_bottom).offset(2);
        make.width.mas_equalTo(lm_localizedCGFloat(108, 130));
    }];
    
    self.moveDoneLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Move File Done")];
    [LMAppThemeHelper setTitleColorForTextField:self.moveDoneLabel];
    self.moveDoneLabel.font = [NSFont systemFontOfSize:24];
    self.moveDoneLabel.alignment = NSTextAlignmentCenter;
    [self addSubview:self.moveDoneLabel];
    [self.moveDoneLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.circleView.mas_bottom).offset(48);
        make.width.equalTo(self.circleView);
    }];
    
    self.stackView = [[NSStackView alloc] init];
    self.stackView.spacing = 8;
    self.stackView.distribution = NSStackViewDistributionFill;
    [self addSubview:self.stackView];
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.moveDoneLabel.mas_bottom).offset(8);
    }];
    self.targetPathLabel = [NSTextField labelWithStringCompat:@""];
    self.targetPathLabel.font = [NSFont systemFontOfSize:14];
    self.targetPathLabel.textColor = LM_COLOR_GRAY;
    [self.stackView addArrangedSubview:self.targetPathLabel];

    self.showInFinderLabel = [NSTextField labelWithStringCompat:LM_LOCALIZED_STRING(@"Show in Finder")];
    self.showInFinderLabel.font = [NSFont systemFontOfSize:14];
    self.showInFinderLabel.textColor = LM_COLOR_BLUE;
    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(showInFinderLabelOnClick:)];
    [self.showInFinderLabel addGestureRecognizer:recognizer];
    [self.stackView addArrangedSubview:self.showInFinderLabel];
    
    self.returnButton = [[LMBorderButton alloc] init];
    [self addSubview:self.returnButton];
    self.returnButton.title = LM_LOCALIZED_STRING(@"Back to Menu");
    self.returnButton.target = self;
    self.returnButton.action = @selector(returnButtonOnClick:);
    self.returnButton.fontSize = 20;
    self.returnButton.font = [NSFont systemFontOfSize:20];
    [self.returnButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.stackView.mas_bottom).offset(32);
        make.size.mas_equalTo(CGSizeMake(148, 48));
    }];
}

- (void)updateWithType:(LMFileMoveTargetPathType)type releaseSpace:(long long)releaseSpace targetFilePath:(NSString *)targetFilePath {
    if (type == LMFileMoveTargetPathTypeDisk) {
        // 外设
        self.circleView.image = LM_IMAGE_NAMED(@"file_move_result_circle_space");
        self.spaceLabel.stringValue = [[LMFileMoveManger shareInstance] sizeNumChangeToStr:releaseSpace];
        self.spaceLabel.hidden = NO;
        self.spaceDescLabel.hidden = NO;
        self.targetPathLabel.stringValue = [NSString stringWithFormat:LM_LOCALIZED_STRING(@"Files were moved to %@"), targetFilePath];
    } else {
        // 本地
        self.circleView.image = LM_IMAGE_NAMED(@"file_move_result_circle_done");
        self.spaceLabel.hidden = YES;
        self.spaceDescLabel.hidden = YES;
        self.targetPathLabel.stringValue = LM_LOCALIZED_STRING(@"To free up your spaces, please move your files to external storage or cloud disks.");
    }
}

- (void)returnButtonOnClick:(id)sender {
    !self.returnButtonClickHandler ?: self.returnButtonClickHandler();
}

- (void)showInFinderLabelOnClick:(id)sender {
    !self.showInFinderLabelOnClickHandler ?: self.showInFinderLabelOnClickHandler();
}

@end
