//
//  LMSubItemCellView.m
//  LemonBigOldFile
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMSubItemCellView.h"
#import "QMLargeOldManager.h"
#import "LMBigResultTableRowView.h"
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMUICommon/NSFontHelper.h>
#import "NSColor+Extension.h"
#import "NSString+Extension.h"
#import "NSFont+Extension.h"
@implementation LMSubItemCellView
{
    NSTrackingArea *trackingArea;
    QMLargeOldResultItem* resultItem;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)setCellData:(id)item {
    resultItem = (QMLargeOldResultItem*)item;
    self.pathBarView.hidden = YES;
    self.finderButton.hidden = YES;

    self.titleLabel.stringValue = [[NSFileManager defaultManager] displayNameAtPath:resultItem.filePath];
//    self.titleLabel fo
//    [LMViewHelper createNormalLabel:<#(int)#> fontColor:<#(NSColor *)#>]
//    self.titleLabel.font = [NSFontHelper getLightSystemFont:14];
    self.sizeLabel.font =  [NSFontHelper getLightSystemFont:12];
    [LMAppThemeHelper setTitleColorForTextField:self.titleLabel];
    self.pathBarView.path = resultItem.filePath;
    self.iconView.image = resultItem.iconImage;
    self.checkButton.state = (resultItem.isSelected ? NSOnState : NSOffState);
    self.checkButton.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.sizeLabel.stringValue = [NSString stringFromDiskSize:resultItem.fileSize];
    [LMAppThemeHelper setTitleColorForTextField:self.sizeLabel];
    [self.finderButton setTarget:self];
    [self.finderButton setAction:@selector(finderAction:)];
}

- (void)finderAction:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:resultItem.filePath
                     inFileViewerRootedAtPath:[resultItem.filePath stringByDeletingLastPathComponent]];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                    options:NSTrackingInVisibleRect | NSTrackingActiveAlways |
            NSTrackingMouseEnteredAndExited
                                                      owner:self userInfo:nil];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self updateRowViewSelectState:YES];
    LMBigResultTableRowView *rowView = (LMBigResultTableRowView *)self.superview;
    if(!rowView.rowViewDelegate.isPreviewing) {
        self.pathBarView.hidden = NO;
        self.finderButton.hidden = NO;
    }
}

- (void)mouseExited:(NSEvent *)event {
    [self updateRowViewSelectState:NO];
    LMBigResultTableRowView *rowView = (LMBigResultTableRowView *)self.superview;
    if(!rowView.rowViewDelegate.isPreviewing) {
        self.pathBarView.hidden = YES;
        self.finderButton.hidden = YES;
    }
}

- (void)updateRowViewSelectState:(BOOL)selected {
    NSView *superView = self.superview;
    if (superView != nil && [superView isKindOfClass:LMBigResultTableRowView.class]) {
        LMBigResultTableRowView *rowView = (LMBigResultTableRowView *) superView;
        if(!rowView.rowViewDelegate.isPreviewing)
            [rowView setSelected:selected];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle: NSBackgroundStyleLight];
}



@end
