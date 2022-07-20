//
//  LMFileMoveResultCell.m
//  LemonFileMove
//
//  
//

#import "LMFileMoveResultCell.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>

@implementation LMFileMoveResultCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)showInFinderAction:(id)sender {
    NSString *pathFinder;
    if (self.resultItem.path) {
        pathFinder = self.resultItem.path;
    } else {
        pathFinder = self.resultItem.originPath;
    }
    [[NSWorkspace sharedWorkspace] selectFile:pathFinder
                     inFileViewerRootedAtPath:[pathFinder stringByDeletingLastPathComponent]];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    [_pathBarView setHidden:YES];
    [_showInFinderButton setHidden:YES];
}

- (CGFloat)getViewHeight {
    return 32;
}

- (void)setTextColor {
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
}

- (void)setCellData:(LMResultItem *)item {
    [super setCellData:item];
    NSLog(@"=====%@",item.title);
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
    if (item.selecteState == YES) {
        self.checkButton.state = NSControlStateValueOn;
    } else {
        self.checkButton.state = NSControlStateValueOff;
    }
   
    [self.iconView setImage:image];
    [self setTextColor];
}

-(void)_refreshDisplayState:(BOOL)hight{
    if (hight) {
        [_pathBarView setHidden:NO];
    }else{
        [_pathBarView setHidden:YES];
    }
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [super mouseEntered:theEvent];
    _showInFinderButton.hidden = NO;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    _showInFinderButton.hidden = YES;
}


@end
