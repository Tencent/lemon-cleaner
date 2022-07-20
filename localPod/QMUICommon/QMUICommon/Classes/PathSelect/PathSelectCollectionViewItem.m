//
//  FolderSelectCollectionViewItem.m
//  PathSelect
//
//
//  Copyright © 2019 xuanqi. All rights reserved.
//

#import "PathSelectCollectionViewItem.h"
#import <Masonry/Masonry.h>
#import "LMiCloudPathHelper.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/LanguageHelper.h>


@interface PathSelectCollectionViewItem () {
    NSString *_path;
}

@end

@implementation PathSelectCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

- (void)loadView {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 50, 100)];
    view.wantsLayer = true;
    view.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.view = view;
}

- (void)initView {
    
    NSImageView *imageView = [[NSImageView alloc] init];
    [self.view addSubview:imageView];
    _folderImageView = imageView;
    imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    imageView.imageAlignment = NSImageAlignCenter;
    
    
    NSButton *deleteButton = [[NSButton alloc] initWithFrame:NSZeroRect];
    [self.view addSubview:deleteButton];
    
    deleteButton.imageScaling = NSImageScaleProportionallyUpOrDown;
    [deleteButton setBezelStyle:NSTexturedSquareBezelStyle];
    [deleteButton setButtonType:NSButtonTypeMomentaryPushIn];
    deleteButton.bordered = NO;  //特别注意 cornerRadius 设置时别忘了这里
    deleteButton.image = [NSImage imageNamed:@"icon_path_delete_normal" withClass:[self class]];
    deleteButton.target = self;
    deleteButton.action = @selector(clickDeleteButton);
    
    
    NSTextField *folderNameLabel = [[NSTextField alloc] init];
    [self.view addSubview:folderNameLabel];
    
    _folderNameLabel = folderNameLabel;
    folderNameLabel.bordered = NO;
    folderNameLabel.editable = NO;
    folderNameLabel.drawsBackground = NO;
    folderNameLabel.font = [NSFont systemFontOfSize:12];
    folderNameLabel.alignment = NSTextAlignmentCenter;
    //    folderNameLabel cell
    //    [[folderNameLabel cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [folderNameLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@44);
        make.height.equalTo(@44);
        make.top.equalTo(self.view).offset(17);
        make.centerX.equalTo(self.view);
    }];
    
    [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@21);
        make.top.equalTo(imageView);
        make.left.equalTo(imageView.mas_right).offset(-13);
    }];
    
    [_folderNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imageView.mas_bottom).offset(4);
        make.centerX.equalTo(imageView);
        make.width.equalTo(@68);
    }];
}


- (void)updateViewWith:(NSString *)path {
    self->_path = path;
    if (!path) {return;}
    //    NSImage *pathImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
    NSImage *pathImage = [NSImage imageNamed:@"icon_folder" withClass:self.class];
    _folderImageView.image = pathImage;
    
    NSString *displayName = nil;
    // 对于iCloud 目录特殊处理.(因为选择iCloudPath 时会自动替换为~/Library/Mobile Documents
    if([path containsString:@"photoslibrary"]){
        if([LanguageHelper getCurrentSystemLanguageType] != SystemLanguageTypeChinese){
            displayName = @"Photos Library.photoslibrary";
        }else{
            displayName = @"照片图库.photoslibrary";
        }
    }
    else if ([LMiCloudPathHelper isICloudContanierPath:path]) {
        displayName = [LMiCloudPathHelper getICloudPathdisplayName];
    } else {
        displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
    }
    _folderNameLabel.stringValue = [path lastPathComponent];
    
}

// MARK: button action
- (void)clickDeleteButton {
    if (self.pathRemoveDelegate) {
        [self.pathRemoveDelegate removePath: _path];
    }
}

@end
