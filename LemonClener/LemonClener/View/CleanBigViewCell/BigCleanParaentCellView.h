//
//  BigCleanParaentCellView.h
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMCheckboxButton.h>
#import "LMCheckboxButton.h"

@interface BigCleanParaentCellView : NSTableCellView
{
    BOOL m_hight;
}

@property (nonatomic, strong) IBOutlet LMCheckboxButton* checkButton;

@property (nonatomic, strong) IBOutlet NSImageView* iconView;

@property (nonatomic, strong) IBOutlet NSTextField* titleLabel;

@property (nonatomic, strong) IBOutlet NSTextField* sizeLabel;

-(void)setCellData:(id)item;

-(NSString *)getSizeStr:(id)item;

-(CGFloat)getViewHeight;

- (void)setHightLightStyle:(BOOL)hight;

- (void)_refreshDisplayState:(BOOL)hight;

@end
