//
//  LMPhotoViewItem.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoViewItem.h"
#import "LMPhotoItem.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMBubbleView.h>
#import <QMCoreFunction/LMReferenceDefines.h>

@interface LMPhotoViewItem ()

@property (nonatomic, strong) LMBubbleView *bubbleView;

@end

@implementation LMPhotoViewItem

- (void)loadView {
    self.view = [NSView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setupSubviews];
    [self setupSubviewsLayout];
    
    self.view.wantsLayer = true;
    self.view.layer.backgroundColor = [NSColor.lightGrayColor CGColor];
}

- (void)setupSubviews {
    [self.view addSubview:self.imgThumbnail];
    [self.view addSubview:self.checkBtnIsSelected];
}

- (void)setupSubviewsLayout {
    [self.imgThumbnail mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    [self.checkBtnIsSelected mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(NSMakeSize(15, 15));
        make.right.bottom.mas_equalTo(0);
    }];
}


- (LMPhotoItem *) photoItem {
    return (LMPhotoItem *)self.representedObject;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    [self.photoItem requestPreviewImage];
    LMPhotoItem *item = representedObject;
    self.checkBtnIsSelected.state = item.isSelected;
    self.checkBtnIsSelected.enabled = item.canRemove;
    if (item.previewImage) {
        self.imgThumbnail.image = item.previewImage;
    }
    __weak typeof(self) weakSelf = self;
    item.previewImageDidChangeBlock = ^(LMPhotoItem *item) {
        if (item.previewImage) {
            weakSelf.imgThumbnail.image = item.previewImage;
        }
    };
}

- (IBAction)valueChange:(NSButton *)sender{
    
    NSButton *checkBtn = sender;
    BOOL isOn = checkBtn.state;
    NSLog(@"valueChange  %d, item is %@",isOn, self);
    self.photoItem.isSelected = isOn;
    
    NSDictionary *userInfo =@{
                              LM_NOTIFICATION_ITEM_UPDATESELECT_PATH:self.photoItem.path,
                              };
//    double startTime = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"updateCollectionViewByPath click  time:%f",startTime);
    [[NSNotificationCenter defaultCenter] postNotificationName:LM_NOTIFICATION_ITEM_UPDATESELECT object:self userInfo:userInfo];
}

#pragma mark - getter

- (LMCheckboxButton *)checkBtnIsSelected {
    if (!_checkBtnIsSelected) {
        _checkBtnIsSelected = [[LMCheckboxButton alloc] init];
        _checkBtnIsSelected.imageScaling = NSImageScaleNone;
        [_checkBtnIsSelected setButtonType:NSButtonTypeSwitch];
        [_checkBtnIsSelected setBezelStyle:NSBezelStyleFlexiblePush];
        _checkBtnIsSelected.target = self;
        _checkBtnIsSelected.action  = @selector(valueChange:);
        @weakify(self);
        _checkBtnIsSelected.hoverBubbleHandler = ^(BOOL value) {
            @strongify(self);
            if (self.photoItem.canRemove) return;
            if (value) {
                if (self.photoItem.externalStorage) {
                    [self.bubbleView setBubbleTitle:NSLocalizedStringFromTableInBundle(@"该图片所在磁盘为只读模式，不支持清理", nil, [NSBundle bundleForClass:[self class]], @"")];
                } else {
                    [self.bubbleView setBubbleTitle:NSLocalizedStringFromTableInBundle(@"该图片为只读模式，不支持清理", nil, [NSBundle bundleForClass:[self class]], @"")];
                }
                if (self.type == LMPhotoViewItemTypeDefault) {
                    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:self.view.frame.origin];
                    if ((indexPath.item % 7) > 2) {
                        [self.bubbleView setArrowDirection:LMBubbleArrowDirectionBottomRight];
                        NSPoint point = [self.checkBtnIsSelected convertPoint:NSMakePoint(37.5, -2) toView:nil];
                        CGSize size = [self.bubbleView calculateViewSize];
                        point = NSMakePoint(point.x - size.width, self.view.window.contentView.frame.size.height - point.y - size.height);
                        [self.bubbleView showInView:self.view.window.contentView atPosition:point];
                    } else {
                        [self.bubbleView setArrowDirection:LMBubbleArrowDirectionBottomLeft];
                        NSPoint point = [self.checkBtnIsSelected convertPoint:NSMakePoint(-22.5, -2) toView:nil];
                        CGSize size = [self.bubbleView calculateViewSize];
                        point = NSMakePoint(point.x, self.view.window.contentView.frame.size.height - point.y - size.height);
                        [self.bubbleView showInView:self.view.window.contentView atPosition:point];
                    }
                }
                if (self.type == LMPhotoViewItemTypePreview) {
                    [self.bubbleView setArrowDirection:LMBubbleArrowDirectionBottomRight];
                    NSPoint point = [self.checkBtnIsSelected convertPoint:NSMakePoint(37.5, -2) toView:nil];
                    CGSize size = [self.bubbleView calculateViewSize];
                    point = NSMakePoint(point.x - size.width, self.view.window.contentView.frame.size.height - point.y - size.height);
                    [self.bubbleView showInView:self.view.window.contentView atPosition:point];
                }
            } else {
                [self.bubbleView removeFromSuperview];
            }
        };
    }
    return _checkBtnIsSelected;
}

- (NSImageView *)imgThumbnail {
    if (!_imgThumbnail) {
        _imgThumbnail = [[NSImageView alloc] init];
        _imgThumbnail.imageScaling = NSImageScaleAxesIndependently;
        NSBundle* bundle = [NSBundle bundleForClass:self.class];
        _imgThumbnail.image = [bundle imageForResource:@"PreviewPlaceHolder"];
    }
    return _imgThumbnail;
}

- (LMBubbleView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [LMBubbleView bubbleWithStyle:LMBubbleStyleText arrowDirection:LMBubbleArrowDirectionBottomLeft];
        _bubbleView.arrowOffset = 30;
    }
    return _bubbleView;
}

@end
