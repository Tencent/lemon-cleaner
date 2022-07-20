//
//  LMSpaceTableRowView.m
//  NSTableViewDemo
//
//  
//  Copyright © 2017年 Karthus. All rights reserved.
//

#import "LMSpaceTableRowView.h"
#import <QMUICommon/LMPathBarView.h>
#import <Masonry/Masonry.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import "LMTextField.h"
#import "LMImageView.h"
#import "LMThemeManager.h"
#import "LMSpacePathView.h"

@interface LMSpaceTableRowView() {
    NSTrackingArea *trackingArea;
}

@property (weak) IBOutlet NSImageView *iconImage;
@property (weak) IBOutlet LMSpacePathView *spaceNameLabel;

@property (weak) IBOutlet NSTextField *spaceSizeLabel;
@property (weak) IBOutlet NSTextField *spaceSubCountLabel;

@property (weak) IBOutlet NSButton *searchButton;
@property (weak) IBOutlet NSButton *nextButton;

@property (nonatomic, assign) long long sizeNum;
@property (nonatomic, assign) BOOL beSelected;

@end

@implementation LMSpaceTableRowView


-(instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
//    [LMAppThemeHelper setTitleColorForTextField:self.spaceSizeLabel];
}

-(void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];

    [self changeSizeColor:self.sizeNum];
    
//    if ([LMThemeManager cureentTheme] == YES) {
//        self.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
//    }else{
//       self.backgroundColor = [NSColor whiteColor];
//    }

}

- (void)drawSelectionInRect:(NSRect)dirtyRect {

    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        NSRect selectionRect = dirtyRect;
    
        if ([LMThemeManager cureentTheme] == YES) {
            //设置选中行的颜色
            [[NSColor colorWithRed:33/255.0 green:32/255.0 blue:41/255.0 alpha:1/1.0] setStroke];
            [[NSColor colorWithRed:33/255.0 green:32/255.0 blue:41/255.0 alpha:1/1.0] setFill];
        }else {
            //设置选中行的颜色
            [[NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.4/1.0] setStroke];
            [[NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.4/1.0] setFill];
        }
        //
        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:1 yRadius:1];
        [selectionPath fill];
        [selectionPath stroke];
    }
}

#pragma mark - action

- (IBAction)searchBtn:(id)sender {
    [[NSWorkspace sharedWorkspace] selectFile:self.fullPath
                     inFileViewerRootedAtPath:[self.fullPath stringByDeletingLastPathComponent]];
}

#pragma mark - NSResponder

- (void)rightMouseDown:(NSEvent *)event {
    if (self.selected != YES) {
        return;
    }
    NSMenu* rightClickMenu = [[NSMenu alloc] init];
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Reveal in Finder", nil, [NSBundle bundleForClass:[self class]], @"") action:@selector(onGoToFinder) keyEquivalent:@""];

    [item1 setTarget:self];
    [rightClickMenu addItem:item1];
    NSMenu* contextMenu = rightClickMenu;
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self];
}

- (void)onGoToFinder {
    [[NSWorkspace sharedWorkspace] selectFile:self.fullPath
                     inFileViewerRootedAtPath:[self.fullPath stringByDeletingLastPathComponent]];
}

- (void)mouseMoved:(NSEvent *)event {
    [super mouseMoved:event];

    NSPoint point =  [self.superview.window.contentView convertPoint:event.locationInWindow toView:self.superview];
    
    if (point.x > self.frame.origin.x && point.x < self.frame.origin.x + self.frame.size.width && point.y > self.frame.origin.y && point.y < self.frame.origin.y + self.frame.size.height) {
//        self.searchButton.hidden = NO;
        self.wantsLayer = YES;
        if ([LMThemeManager cureentTheme] == YES) {
            self.backgroundColor = [NSColor colorWithRed:33/255.0 green:32/255.0 blue:41/255.0 alpha:0.6/1.0];
        }else{
            self.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.3/1.0];
        }
    }else{
//        self.searchButton.hidden = YES;
        self.wantsLayer = YES;
        if ([LMThemeManager cureentTheme] == YES) {
            self.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
        }else{
            self.backgroundColor = [NSColor whiteColor];
        }
    }
}

-(void)mouseEntered:(NSEvent *)event {
//    self.searchButton.hidden = NO;
    if ([LMThemeManager cureentTheme] == YES) {
        self.backgroundColor = [NSColor colorWithRed:33/255.0 green:32/255.0 blue:41/255.0 alpha:0.6/1.0];
    }else{
        self.backgroundColor = [NSColor colorWithRed:222/255.0 green:228/255.0 blue:235/255.0 alpha:0.3/1.0];
    }
}

- (void)mouseExited:(NSEvent *)event {
//    self.searchButton.hidden = YES;
    if ([LMThemeManager cureentTheme] == YES) {
        self.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
    }else{
        self.backgroundColor = [NSColor whiteColor];
    }
    
}

- (void)scrollWheel:(NSEvent *)event{
    [super scrollWheel:event];
//    self.searchButton.hidden = YES;
    if ([LMThemeManager cureentTheme] == YES) {
        self.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
    }else{
        self.backgroundColor = [NSColor whiteColor];
    }
    
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

#pragma mark - public

- (void)initUI {
//    self.searchButton.hidden = YES;
    self.iconImage.image = nil;
    self.iconImage.alphaValue = 1;
    self.spaceSizeLabel.attributedStringValue = [[NSAttributedString alloc] init];
    self.spaceSubCountLabel.attributedStringValue = [[NSAttributedString alloc] init];
    if ([LMThemeManager cureentTheme] == YES) {
        self.backgroundColor = [NSColor colorWithRed:38/255.0 green:39/255.0 blue:50/255.0 alpha:1/1.0];
    }else{
        self.backgroundColor = [NSColor whiteColor];
    }

    
}

- (void)setCountStr:(NSUInteger)num {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary * dict = @{
                            NSParagraphStyleAttributeName:style,
                            NSFontAttributeName:[NSFont systemFontOfSize:12.0]
                            };
    
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lu items", nil, [NSBundle bundleForClass:[self class]], @""),num] attributes:dict];
    self.spaceSubCountLabel.attributedStringValue = attrStr;
    
}

- (void)setType:(NSString *)type {
    if(type){
        self.spaceSubCountLabel.stringValue = type;
    }
}

- (void)countStrIsHidden:(BOOL)result {
    self.spaceSubCountLabel.hidden = result;
}

- (void)nextButtonIsHidden:(BOOL)result {
    self.nextButton.hidden = result;
}

- (void)setIcon:(NSImage *)image isHidden:(BOOL)isHidden{
    self.iconImage.image = image;
    if (isHidden) {
        self.iconImage.alphaValue = 0.5;
    }
    
}

- (void)setNameStr:(NSString *)text {
//    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//    style.lineBreakMode = NSLineBreakByTruncatingTail;
//    NSDictionary * dict = @{
//                            NSParagraphStyleAttributeName:style,
//                            NSFontAttributeName:[NSFont systemFontOfSize:12.0]
//                            };
//
//    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:text attributes:dict];
//    self.spaceNameLabel.attributedStringValue = attrStr;
    
    
    self.spaceNameLabel.rightAlignment = NO;
    self.spaceNameLabel.path = text;
    
}

- (void)setSizeStr:(long long)text {
    self.sizeNum = text;
    [self changeSizeColor:text];
}

#pragma mark - private

- (nullable id)viewAtColumn:(NSInteger)column {
    return nil;
}

- (void)changeSizeColor:(long long)text {
    NSColor *sizeColor;
    NSFont *sizeFont;
//    if(text >= 10000000000){
//        sizeColor = [NSColor colorWithHex:0xF25B3D];
//        sizeFont = [NSFont systemFontOfSize:12.0];
//    }else{
        sizeColor = [NSColor colorWithHex:0x989A9E];
        sizeFont = [NSFont systemFontOfSize:12.0];
//    }

    float resultSize = 0.0;
    NSString *fileSizeStr;
    if (text < 1000000){
        resultSize = text/1000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fKB",resultSize];
    }else if(text < 1000000000){
        resultSize = text/1000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fMB",resultSize];
    }else{
        resultSize = text/1000000000.0;
        fileSizeStr = [NSString stringWithFormat:@"%0.2fGB",resultSize];
    }
    
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentRight;
    NSDictionary * dict = @{
                            NSParagraphStyleAttributeName:style,
                            NSFontAttributeName:sizeFont,
                            NSForegroundColorAttributeName:sizeColor
                            };
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:fileSizeStr attributes:dict];
    self.spaceSizeLabel.attributedStringValue = attrStr;
    
}

-(void)dealloc{
//    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end
