//
//  OwlWhitelistCell.h
//  PrivacyProtect
//
//  Copyright © 2025 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/LMTitleButton.h>
#import <QMUICommon/LMBubbleView.h>
#import <QMUICommon/QMHoverStackView.h>
#import "Owl2AppItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface OwlWhitelistCell : NSTableCellView

@property (nonatomic, strong) NSImageView *appIcon; // 图标
@property (nonatomic, strong) NSTextField *tfAppName; // 应用名称
@property (nonatomic, strong) NSTextField *tfKind; // 系统应用 or 第三方应用
@property (nonatomic, strong) NSTextField *tfGrantedPermission; // 已允许权限类型
@property (nonatomic, strong) NSTextField *tfItem; // 项
@property (nonatomic, strong) QMHoverStackView *grantedPermissionStackView;
@property (nonatomic, strong) LMBubbleView *bubbleView;
@property (nonatomic, strong) LMTitleButton *foldOrExpandButton; // 权限管理,展开或者收起
@property (nonatomic, strong) LMTitleButton *removeBtn; // 移除

@property (nonatomic, strong) dispatch_block_t foldOrExpandAction;
@property (nonatomic, strong) dispatch_block_t removeAction;

- (void)setupSubviews;
- (void)setupSubviewsLayout;
- (void)updateAppItem:(Owl2AppItem *)appItem;

- (NSImage *)imageFoldOrExpandButton;

+ (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color;

@end

NS_ASSUME_NONNULL_END
