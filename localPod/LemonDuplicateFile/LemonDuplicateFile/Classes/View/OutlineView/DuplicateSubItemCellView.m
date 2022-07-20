//
//  OutlineItemCellView.m
//  LemonDuplicateFile
//
//  Created by tencent on 2018/8/19.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "DuplicateSubItemCellView.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMCheckboxButton.h>
#import <QMUICommon/LMViewHelper.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import "SizeHelper.h"
#import <QMUICommon/LMPathBarView.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/NSFontHelper.h>

@interface DuplicateSubItemCellView () {

    NSBundle *bundle;
    BOOL _isPreview;

}
//@property(nonatomic, strong) NSTextField *pathLabel;
@property(nonatomic, strong) NSImageView *iconImageView;
@property (nonatomic)  LMPathBarView *pathBarView;

@end

@implementation DuplicateSubItemCellView {
    NSImageView *_iconImageView;
    NSTrackingArea *trackingArea;
}


- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        bundle = [NSBundle bundleForClass:self.class];

        [self initViews];
    }
    return self;
}

- (void)initViews {
    _checkBox = [[LMCheckboxButton alloc] init];
    [self addSubview:_checkBox];
    _checkBox.allowsMixedState = NO;
    _checkBox.imageScaling = NSImageScaleProportionallyUpOrDown;
    _checkBox.title = @"";
    [_checkBox setButtonType:NSButtonTypeSwitch];
    _checkBox.target = self;
    [_checkBox setAction:@selector(updateSelectedInfo:)];
    [_checkBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).mas_equalTo(94);
        make.width.height.equalTo(@14);
        make.centerY.equalTo(self);
    }];


    _iconImageView = [[NSImageView alloc] init];
    self.iconImageView = _iconImageView;
    [self addSubview:_iconImageView];
    _iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_checkBox.mas_right).offset(13);
        make.centerY.equalTo(self);
        make.width.height.equalTo(@15);
    }];


    _pathBarView = [[LMPathBarView alloc] init];
    _pathBarView.rightAlignment = NO;
    [self addSubview:_pathBarView];
    _pathBarView.wantsLayer = YES;
    [_pathBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self->_iconImageView.mas_right).offset(19);
        make.centerY.equalTo(self);
        make.width.equalTo(@380);
        make.height.equalTo(@20);
    }];

    _sizeText = [LMViewHelper createNormalLabel:12 fontColor:[LMAppThemeHelper getTitleColor] fonttype:LMFontTypeLight];
    [self addSubview:_sizeText];
    [_sizeText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-40);
        make.centerY.equalTo(self);
    }];

    NSImage *icon_search_image = [NSImage imageNamed:@"icon_search" withClass:self.class];
    _openFolderBtn = [[NSButton alloc] init];
    _openFolderBtn.image = icon_search_image;
    _openFolderBtn.target = self;
    _openFolderBtn.action = @selector(openFolder);
    _openFolderBtn.bezelStyle = NSRoundedBezelStyle;
    _openFolderBtn.bordered = false;
    _openFolderBtn.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self addSubview:_openFolderBtn];
    [_openFolderBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(18);
        make.right.equalTo(self->_sizeText.mas_left).offset(-20);
        make.centerY.equalTo(self);
    }];
    
    _modifyTimeText = [LMViewHelper createNormalLabel:12 fontColor:[NSColor colorWithHex:0x94979B]];
    [self addSubview:_modifyTimeText];
    [_modifyTimeText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self->_pathBarView.mas_right).offset(10);
        make.centerY.equalTo(self->_pathBarView);
    }];

}


- (void)openFolder {
    NSLog(@"...openFolder...");
    [[NSWorkspace sharedWorkspace] selectFile:_item.filePath
                     inFileViewerRootedAtPath:[_item.filePath stringByDeletingLastPathComponent]];
}

- (void)updateSelectedInfo:(NSButton *)sender {
    if (self.checkBoxUpdateDelegate) {
        [self.checkBoxUpdateDelegate updateDupFileSelectedState:_item button:sender];
    }
    [self.checkBox setNeedsDisplay];
}

//- (void)setTrackingArea {
//    //设置监视区域,必须添加NSTrackingActiveInKeyWindow,否则会崩溃!!!
//    CGRect eyeBox = CGRectMake(0, 0, 700, 40);
//    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:eyeBox options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingMouseMoved) owner:self userInfo:nil];
//    [self addTrackingArea:trackingArea];
//}
- (void)updateTrackingAreas {

//    NSArray *areaArray = [self trackingAreas];
//    for (NSTrackingArea *area in areaArray) {
//        [self removeTrackingArea:area];
//    }
//    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
//                                                                options:NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
//                                                                  owner:self userInfo:nil];
//    [self addTrackingArea:trackingArea];

    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    if(!_isPreview){
         [self updateRowViewSelect:YES];
    }
}

- (void)mouseExited:(NSEvent *)event {
    if(!_isPreview){
        [self updateRowViewSelect:NO];
    }
}

- (void)updateRowViewSelect:(BOOL)selected {
    NSView *superView = self.superview;
    if (superView != nil && [superView isKindOfClass:NSTableRowView.class]) {
        NSTableRowView *rowView = (NSTableRowView *) superView;
        [rowView setSelected:selected];
    }
}

- (void)updateViewsWithItem:(QMDuplicateFile *)item withPreview:(BOOL)isPreview {
    self->_isPreview = isPreview;
//    NSString *value = [item.filePath stringByReplacingOccurrencesOfString:@"/" withString:@" > "];
//    value = [value substringFromIndex:2];
//    _pathLabel.stringValue = value;
    [_pathBarView setPath:item.filePath];
    NSString *timeString = [self getDataStrByInterval:item.modifyTime];
    _modifyTimeText.stringValue = timeString;
    
    NSString *tempString = [[NSString alloc] initWithFormat:@"%@", [SizeHelper getFileSizeStringBySize:item.fileSize]];
    self.sizeText.stringValue = tempString;
    self.checkBox.state = item.selected ? NSControlStateValueOn : NSControlStateValueOff;
    if (isPreview) {
        self.sizeText.stringValue = @"";
        _pathBarView.rightAlignment = NO;
        [_sizeText setHidden:YES];
        [_iconImageView setHidden:YES];
        [_pathBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.mas_equalTo(self->_checkBox.mas_right).offset(10);
            make.right.mas_equalTo(self->_openFolderBtn.mas_left).offset(-10);
            make.height.equalTo(@20);
        }];

        [_modifyTimeText mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-10);
            make.width.mas_equalTo(75);
            make.centerY.equalTo(self);
        }];
        
        [_openFolderBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(18);
            make.right.equalTo(self->_modifyTimeText.mas_left).offset(-10);
            make.centerY.equalTo(self);
        }];

        [_checkBox mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).mas_equalTo(3);
        }];
    } else {
        self.sizeText.stringValue = tempString;
        [self.modifyTimeText setHidden: YES];
        [_sizeText setHidden:NO];
        [_iconImageView setHidden:NO];
        _pathBarView.rightAlignment = NO;
        [_pathBarView mas_remakeConstraints:^(MASConstraintMaker *make) {
            
            make.left.equalTo(self->_iconImageView.mas_right).offset(10);
            make.centerY.equalTo(self);
            make.width.equalTo(@380);
            make.height.equalTo(@20);
        }];
        [_openFolderBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self->_sizeText.mas_left).offset(-35);
            make.width.height.mas_equalTo(18);
            make.centerY.equalTo(self);
        }];
        [_checkBox mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).mas_equalTo(69);
        }];
    }

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:item.filePath];
    _iconImageView.image = image;
    _checkBox.state = _item.selected ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}

-(NSString *)getDataStrByInterval:(NSTimeInterval) timeInterval{
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
    
    NSDateFormatter *ymdDf = [[NSDateFormatter alloc] init];
    [ymdDf setDateFormat:@"yyyy/MM/dd"];
    NSString *nowTimeString = [ymdDf stringFromDate:currentDate];
    // NSLog(@"-------current date is = %@--------", nowTimeString);
    
    return nowTimeString;
}
@end
