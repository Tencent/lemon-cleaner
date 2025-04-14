//
//  LMPhotoViewItem.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>

typedef NS_ENUM(NSUInteger, LMPhotoViewItemType) {
    LMPhotoViewItemTypeDefault,
    LMPhotoViewItemTypePreview
};

@interface LMPhotoViewItem : NSCollectionViewItem
@property (nonatomic, strong) LMCheckboxButton *checkBtnIsSelected;
@property (nonatomic, strong) NSImageView *imgThumbnail;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) LMPhotoViewItemType type;
@end
