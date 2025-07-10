//
//  OwlWhitelistExpandCell.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import "OwlWhitelistCell.h"

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const OwlWLCellFoldHeight;
extern CGFloat const OwlWLCellExpandHeight;

typedef void(^OwlWlCellCheckboxAction)(LMCheckboxButton *btn);

@interface OwlWhitelistExpandCell : OwlWhitelistCell

@property (nonatomic, strong) NSView *foldContainer;

@property (nonatomic, strong) NSView *expandContainer;

@property (nonatomic, strong) NSTextField *tfPermissionType;

@property (nonatomic, strong) LMCheckboxButton *cameraCheck;
@property (nonatomic, strong) LMCheckboxButton *audioCheck;
@property (nonatomic, strong) LMCheckboxButton *speakerCheck;
@property (nonatomic, strong) LMCheckboxButton *screenCheck;
@property (nonatomic, strong) LMCheckboxButton *automaticCheck;

@property (nonatomic, strong) NSTextField *checkLabelCamera;
@property (nonatomic, strong) NSTextField *checkLabelAudio;
@property (nonatomic, strong) NSTextField *checkLabelSpeaker;
@property (nonatomic, strong) NSTextField *checkLabelScreen;
@property (nonatomic, strong) NSTextField *checkLabelAutomatic;

@property (nonatomic, strong) OwlWlCellCheckboxAction cameraCheckAction;
@property (nonatomic, strong) OwlWlCellCheckboxAction audioCheckAction;
@property (nonatomic, strong) OwlWlCellCheckboxAction speakerCheckAction;
@property (nonatomic, strong) OwlWlCellCheckboxAction screenCheckAction;
@property (nonatomic, strong) OwlWlCellCheckboxAction automaticCheckAction;

@end

NS_ASSUME_NONNULL_END
