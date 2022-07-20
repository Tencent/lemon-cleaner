//
//  LMPhotoViewItem.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>

@interface LMPhotoViewItem : NSCollectionViewItem
@property (weak) IBOutlet LMCheckboxButton *checkBtnIsSelected;
@property (weak) IBOutlet NSImageView *imgThumbnail;
@end
