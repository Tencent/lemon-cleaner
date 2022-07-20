//
//  HardwareCellView.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HardwareModel.h"

@protocol HardwareCellViewDelegate <NSObject>

- (void)HardwareCellViewDidSpaceButon;

@end

@interface HardwareCellView : NSTableCellView

@property (nonatomic, weak) NSImageView *iconImageView;
@property (nonatomic, weak) NSTextField *categoryTextField;
@property (nonatomic, weak) NSTextField *name1TextField;
@property (nonatomic, weak) NSTextField *value1TextField;
@property (nonatomic, weak) NSTextField *name2TextField;
@property (nonatomic, weak) NSTextField *value2TextField;
@property (nonatomic, weak) NSTextField *name3TextField;
@property (nonatomic, weak) NSTextField *value3TextField;
@property (nonatomic, weak) NSView *topLineView;

@property(nonatomic, strong) NSImageView *spaceIcon;
@property(nonatomic, strong) NSButton *spaceButton;
@property (nonatomic, weak) id<HardwareCellViewDelegate> delegate;

-(void)setupUI;

-(void)layoutView;

-(void)setCellWithArr:(HardwareBaseModel *)hardwareModel;

@end
