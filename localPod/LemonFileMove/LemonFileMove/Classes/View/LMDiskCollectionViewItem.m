//
//  LMDiskCollectionViewItem.m
//  LemonFileMove
//
//  
//

#import "LMDiskCollectionViewItem.h"
#import <QMCoreFunction/NSImage+Extension.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/LanguageHelper.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import "LMFileMoveMask.h"
#import "LMFileMoveManger.h"
#import <QMUICommon/LMAppThemeHelper.h>

@interface LMDiskCollectionViewItem () <LMFileMoveMaskDelegate>{
    NSTrackingArea * _trackingArea;
}
@end

@implementation LMDiskCollectionViewItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self initView];
}

- (void)setSelected:(BOOL)selected {

    [super setSelected:selected];
    [(LMFileMoveMask *)[self view] setIsSelected:selected];
}

- (void)initView {
    
    // 背景图
    NSImageView *diskImageBgView = [[NSImageView alloc] init];
    diskImageBgView.imageScaling = NSImageScaleProportionallyUpOrDown;
    diskImageBgView.imageAlignment = NSImageAlignCenter;
    diskImageBgView.image = [NSImage imageNamed:@"circle_icon" withClass:[self class]];
    [self.view addSubview:diskImageBgView];
    self.diskImageBgView = diskImageBgView;
    
    //
    LMCircleDiskView *diskImageCircleView =  [[LMCircleDiskView alloc] init];
    [diskImageCircleView setSysFullSize:100 alreadySize:80];
    [self.view addSubview:diskImageCircleView];
    self.diskImageCircleView = diskImageCircleView;
    
    // disk图
    NSImageView *diskImageView = [[NSImageView alloc] init];
    diskImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    diskImageView.imageAlignment = NSImageAlignCenter;
    NSImage *image = [NSImage imageNamed:@"disk_icon_hight" withClass:[self class]];
    diskImageView.image = image;
    [self.view addSubview:diskImageView];
    self.diskImageView = diskImageView;
    
    //
    NSTextField *diskNameLabel = [[NSTextField alloc] init];
    diskNameLabel.stringValue = @"DiskName1";
    diskNameLabel.bordered = NO;
    diskNameLabel.textColor = [LMAppThemeHelper getFixedTitleColor];
    diskNameLabel.alignment = NSCenterTextAlignment;
    diskNameLabel.font = [NSFont systemFontOfSize:15.0];
    [diskNameLabel setEditable:NO];
    diskNameLabel.backgroundColor = [NSColor clearColor];
    [self.view addSubview:diskNameLabel];
    self.diskNameLabel = diskNameLabel;
    
    //
    NSTextField *diskSizeLabel = [[NSTextField alloc] init];
    diskSizeLabel.stringValue = @"999.9TB";
    diskSizeLabel.bordered = NO;
    diskSizeLabel.textColor = [NSColor colorWithHex:0x989A9E];
    diskSizeLabel.alignment = NSCenterTextAlignment;
    diskSizeLabel.font = [NSFont systemFontOfSize:13.0];
    [diskSizeLabel setEditable:NO];
    diskSizeLabel.backgroundColor = [NSColor clearColor];
    [self.view addSubview:diskSizeLabel];
    self.diskSizeLabel = diskSizeLabel;
    
    [self.diskImageBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@(96));
        make.top.equalTo(self.view).offset(16);
        make.left.equalTo(self.view).offset(22);
    }];
    
    [self.diskImageCircleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.height.width.equalTo(self.diskImageBgView);
    }];
    
    [self.diskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.height.width.equalTo(self.diskImageBgView);
    }];
    
    [self.diskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.diskImageView.mas_bottom).offset(20);
        make.height.mas_equalTo(17);
        make.centerX.equalTo(self.view);
    }];
    
    [self.diskSizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(17);
        make.top.equalTo(self.diskNameLabel.mas_bottom).offset(8);
    }];    
    
    NSView *mask = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 140, 202)];
    mask.wantsLayer = YES;
    mask.layer.cornerRadius = 4.0;
    [self.view addSubview:mask];
    [self.view addSubview:mask positioned:NSWindowBelow relativeTo:self.diskImageBgView];
    self.maskView = mask;
}

- (void)fileMoveMaskMoveIn {
    if (self.selected == NO  && self.isNone == NO && self.noEnough == NO) {
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor colorWithHex:0x9A9A9A alpha:0.2].CGColor;
        self.maskView.layer.borderWidth = 1;
        self.maskView.layer.backgroundColor = [NSColor colorWithHex:0xC0C0C0 alpha:0.05].CGColor;
    }
}

- (void)fileMoveMaskMoveOut {
    if (self.selected == NO && self.isNone == NO && self.noEnough == NO) {
        self.maskView.wantsLayer = YES;
        self.maskView.layer.borderColor = [NSColor clearColor].CGColor;
        self.maskView.layer.borderWidth = 0;
        self.maskView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
}

- (void)fileMoveMaskSelect:(BOOL)select {
    if (self.isNone == NO && self.noEnough == NO) {
    
        if (self.selected == YES) {
            if ([self.delegate respondsToSelector:@selector(collectionViewItemBeSelect:)]) {
                [self.delegate collectionViewItemBeSelect:self.model];
            }
            self.maskView.wantsLayer = YES;
            self.maskView.layer.borderColor = [NSColor colorWithHex:0xFFD500 alpha:1].CGColor;
            self.maskView.layer.borderWidth = 1;
            self.maskView.layer.backgroundColor = [NSColor colorWithHex:0xFFD500 alpha:0.1].CGColor;
            [self.diskImageCircleView setCircleColor:[NSColor colorWithHex:0xFFD500 alpha:1]];
            self.diskNameLabel.textColor = [NSColor colorWithHex:0xFFAA00 alpha:1];
        } else {
            self.maskView.wantsLayer = YES;
            self.maskView.layer.borderColor = [NSColor clearColor].CGColor;
            self.maskView.layer.borderWidth = 0;
            self.maskView.layer.backgroundColor = [NSColor clearColor].CGColor;
            [self.diskImageCircleView setCircleColor:[NSColor colorWithHex:0x9A9A9A alpha:0.2]];
            self.diskNameLabel.textColor = [LMAppThemeHelper getFixedTitleColor];
        }
        
    }
}

- (void)loadView {
    LMFileMoveMask *view = [[LMFileMoveMask alloc] initWithFrame:NSMakeRect(0, 0, 140, 202)];
    view.wantsLayer = true;
    view.layer.backgroundColor = [NSColor clearColor].CGColor;
    view.layer.borderWidth = 0;
    view.delegate = self;
    self.view = view;
}

- (void)setNoneDisk {
    self.isNone = YES;
    self.diskNameLabel.stringValue = NSLocalizedStringFromTableInBundle(@"No external device found", nil, [NSBundle bundleForClass:[self class]], @"");
    self.diskNameLabel.textColor = [LMAppThemeHelper getFixedTitleColor];
    self.diskSizeLabel.stringValue = NSLocalizedStringFromTableInBundle(@"Please check whether it’s connected", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.diskImageCircleView setSysFullSize:0 alreadySize:0];
    self.diskImageView.image = [NSImage imageNamed:@"disk_icon_gray" withClass:[self class]];
}

- (void)setDiskModel:(Disk *)model {
    self.model = model;
    self.isNone = NO;
    NSString *diskName = [model.diskDescription objectForKey:@"DAVolumeName"];
    if (diskName == nil ) {
        diskName = [model.diskDescription objectForKey:@"DAMediaName"];
    }
    self.diskNameLabel.stringValue = diskName;
    
    NSURL *pathUrl = [model.diskDescription objectForKey:@"DAVolumePath"];
    long long leftDiskSize = [self getAllUsableBytes:pathUrl];
    NSNumber *mediaSize = (NSNumber *)[model.diskDescription objectForKey: (NSString *)kDADiskDescriptionMediaSizeKey];
    long long allDiskSize = [mediaSize longLongValue];
    long long usedDiskSize;
    if (leftDiskSize > allDiskSize) {
        usedDiskSize = 0;
    } else {
        usedDiskSize = allDiskSize - leftDiskSize;
    }
    
    [self.diskImageCircleView setSysFullSize:allDiskSize alreadySize:usedDiskSize];
    
    long long selectedStr = [LMFileMoveManger shareInstance].selectedFileSize;
    
    if (selectedStr >= leftDiskSize) {
        self.noEnough = YES;
        self.diskSizeLabel.stringValue = NSLocalizedStringFromTableInBundle(@"Not enough space", nil, [NSBundle bundleForClass:[self class]], @"");
    } else {
        self.noEnough = NO;
        self.diskSizeLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ available", nil, [NSBundle bundleForClass:[self class]], @""), [[LMFileMoveManger shareInstance] sizeNumChangeToStr:leftDiskSize]];
    }
    self.diskImageView.image = [NSImage imageNamed:@"disk_icon_hight" withClass:[self class]];
    
}

- (long long)getAllUsableBytes:(NSURL *)fileURL {
        NSError *error = nil;
        NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityKey] error:&error];
        if (!results) {
            NSLog(@"Error retrieving resource keys");
            return 0;
        }
        return [[results objectForKey:NSURLVolumeAvailableCapacityKey] longLongValue];
}

@end
