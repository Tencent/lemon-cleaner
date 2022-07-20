//
//  LMFileMoveResultFailureFileCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultFailureFileCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import "LMFileMoveCommonDefines.h"

@implementation LMFileMoveResultFailureFileCell

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self _setupViews];
    }
    return self;
}

- (void)_setupViews {
    self.sizeLabel.frame = NSMakeRect(764, 7, 105, 18);

    self.showInFinderButton = [[NSButton alloc] init];
    self.showInFinderButton.image = LM_IMAGE_NAMED(@"finder_icon");
    self.showInFinderButton.target = self;
    self.showInFinderButton.action = @selector(showInFinderAction:);
    self.showInFinderButton.wantsLayer = YES;
    [self.showInFinderButton setBordered:NO];
    [self addSubview:self.showInFinderButton];
    [self.showInFinderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(190);
        make.size.mas_equalTo(CGSizeMake(16, 16));
    }];
    
    self.pathBarView = [[LMPathBarView alloc] init];
    [self addSubview:self.pathBarView];
    [self.pathBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(210);
        make.size.mas_equalTo(CGSizeMake(299, 20));
    }];
    
    [self.pathBarView setHidden:YES];
    [self.showInFinderButton setHidden:YES];
}

- (void)showInFinderAction:(id)sender {
    NSString *pathFinder;
    if (self.resultItem.path) {
        pathFinder = self.resultItem.path;
    } else {
        pathFinder = self.resultItem.originPath;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathFinder]) {
        [[NSWorkspace sharedWorkspace] selectFile:pathFinder
                         inFileViewerRootedAtPath:[pathFinder stringByDeletingLastPathComponent]];
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:NSHomeDirectory() inFileViewerRootedAtPath:NSHomeDirectory()];
    }
}

- (void)setTextColor {
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
}

- (void)setCellData:(LMResultItem *)item {
    [super setCellData:item];
    self.resultItem = item;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image;
    if (item.originPath) {
        image = [workspace iconForFile:item.originPath];
        [_pathBarView setPath:[item originPath]];
    } else {
        image = [workspace iconForFile:item.path];
        [_pathBarView setPath:[item path]];
    }
   
    [self.iconView setImage:image];
    [self setTextColor];
}

- (void)_refreshDisplayState:(BOOL)hight {
    if (hight) {
        [_pathBarView setHidden:NO];
    }else{
        [_pathBarView setHidden:YES];
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    _showInFinderButton.hidden = NO;
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    _showInFinderButton.hidden = YES;
}

@end
