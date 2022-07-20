//
//  ResultCellView.m
//  LemonClener
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ResultCellView.h"
#import "QMResultItem.h"
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>

@interface ResultCellView()
{
    NSTrackingArea * _trackingArea;
}
@end

@implementation ResultCellView

-(void)awakeFromNib{
    [super awakeFromNib];
    [_pathBarView setHidden:YES];
//    [self addSubview:_showInFinderButton];
//    [_showInFinderButton setFrame:NSMakeRect(210, 10, 12, 12)];
    [_showInFinderButton setHidden:YES];
}

- (IBAction)showInFinderAction:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:[self.resultItem path]
                         inFileViewerRootedAtPath:[[self.resultItem path] stringByDeletingLastPathComponent]];
}

-(CGFloat)getViewHeight {
    return 30;
}

-(void)setTextColor{
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
}

-(void)setCellData:(id)item {
    [super setCellData:item];
    self.resultItem = item;
//    NSLog(@"sizelabel frame = %@", NSStringFromRect(self.sizeLabel.frame));
    if ([item showHierarchyType] == 3) {//第三级显示
        [self.sizeLabel setFrame:NSMakeRect(699, 4, 105, 18)];
        [self.pathBarView setFrame:NSMakeRect(374, 3, 299, 20)];
    }else if([item showHierarchyType] == 4){//第四级显示
        [self.sizeLabel setFrame:NSMakeRect(702, 4, 87, 18)];
        [self.pathBarView setFrame:NSMakeRect(354, 3, 299, 20)];
    }
    
    [self.iconView setImage:[item iconImage]];
    [_pathBarView setPath:[item path]];
    [self setTextColor];
}

-(NSString *)getSizeStr:(id)item{
    // 扫描完成，显示结果
    NSString * sizeStr = @"1 kB";
    NSUInteger resultSize = [item resultFileSize];
    // 显示大小
    if (resultSize > 0) {
        sizeStr = [NSString stringFromDiskSize:resultSize];
    }
    return sizeStr;
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
    if ((self.resultItem.cleanType == QMCleanRemoveLanguage) && ([self.resultItem showHierarchyType] == 3)) {
        return;
    }
    _showInFinderButton.hidden = NO;
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [super mouseExited:theEvent];
    _showInFinderButton.hidden = YES;
}

@end
