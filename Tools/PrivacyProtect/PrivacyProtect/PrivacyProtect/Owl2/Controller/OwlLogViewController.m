//
//  OwlLogViewController.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlLogViewController.h"
#import "OwlTableRowView.h"
#import "Owl2Manager.h"
#import "OwlConstant.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/LMAppThemeHelper.h>
#import <QMCoreFunction/LanguageHelper.h>

@interface OwlCellView : NSView
@property (nonatomic, strong) NSImageView *iconImageView;
@property (nonatomic, strong) NSTextField *labelProcess;
@property (nonatomic, strong) NSTextField *labelTime;
@property (nonatomic, strong) NSTextField *labelEvent;
@property (nonatomic, strong) NSTextField *labelOperation;

@end

@implementation OwlCellView

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.iconImageView = [[NSImageView alloc] init];
        self.iconImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        [self addSubview:self.iconImageView];
        
        self.labelProcess = [[NSTextField alloc] init];
        self.labelProcess.alignment = NSTextAlignmentLeft;
        self.labelProcess.bordered = NO;
        self.labelProcess.editable = NO;
        self.labelProcess.backgroundColor = [NSColor clearColor];
        self.labelProcess.font = [NSFontHelper getLightSystemFont:12];
        self.labelProcess.textColor = [NSColor colorWithHex:0x94979B];
        self.labelProcess.maximumNumberOfLines = 1;
        self.labelProcess.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.labelProcess];
        
        self.labelTime = [[NSTextField alloc] init];
        self.labelTime.alignment = NSTextAlignmentLeft;
        self.labelTime.bordered = NO;
        self.labelTime.editable = NO;
        self.labelTime.backgroundColor = [NSColor clearColor];
        self.labelTime.font = [NSFontHelper getLightSystemFont:12];
        self.labelTime.textColor = [NSColor colorWithHex:0x94979B];
        self.labelTime.maximumNumberOfLines = 1;
        [self addSubview:self.labelTime];
        
        self.labelEvent = [[NSTextField alloc] init];
        self.labelEvent.alignment = NSTextAlignmentLeft;
        self.labelEvent.bordered = NO;
        self.labelEvent.editable = NO;
        self.labelEvent.backgroundColor = [NSColor clearColor];
        self.labelEvent.font = [NSFontHelper getLightSystemFont:12];
        self.labelEvent.textColor = [NSColor colorWithHex:0x94979B];
        self.labelEvent.maximumNumberOfLines = 1;
        [self addSubview:self.labelEvent];
        
        self.labelOperation = [[NSTextField alloc] init];
        self.labelOperation.alignment = NSTextAlignmentLeft;
        self.labelOperation.bordered = NO;
        self.labelOperation.editable = NO;
        self.labelOperation.backgroundColor = [NSColor clearColor];
        self.labelOperation.font = [NSFontHelper getLightSystemFont:12];
        self.labelOperation.textColor = [NSColor colorWithHex:0x989A9E];
        self.labelOperation.maximumNumberOfLines = 1;
        [self addSubview:self.labelOperation];
        
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(24);
            make.size.equalTo(@(NSMakeSize(20, 20)));
        }];
        
        [self.labelProcess mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.iconImageView.mas_right).offset(12);
            make.width.equalTo(@90);
        }];
        
        [self.labelTime mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.left.equalTo(self.mas_left).offset(165);
            } else {
                make.left.equalTo(self.mas_left).offset(180);
            }
            make.width.equalTo(@140);
        }];
        
        [self.labelEvent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.left.equalTo(self.mas_left).offset(335);
            } else {
                make.left.equalTo(self.mas_left).offset(350);
            }
            make.right.lessThanOrEqualTo(self.labelOperation.mas_left).offset(-4);
        }];
        
        [self.labelOperation mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self.mas_left).offset(480);
            if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                make.right.equalTo(self.mas_right).offset(-4);
            } else {
                make.right.equalTo(self.mas_right).offset(-24);
            }
        }];
    }
    return self;
}

@end

@interface OwlLogViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSTableView *tableView;
    NSString *timeIdentifier;
    NSString *eventIdentifier;
}
@property(weak) MMScroller *scroller;
@property (weak)NSView *bLineview;
@end

@implementation OwlLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (instancetype)initWithFrame:(NSRect)frame{
    self = [super init];
    if (self) {
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - 0/*OwlWindowTitleHeight*/)];
        contentView.wantsLayer = YES;
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = [NSColor whiteColor].CGColor;
        contentView.layer = layer;
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - OwlWindowTitleHeight - 29)];
        
        tableView = [[NSTableView alloc] init];
        [tableView setDelegate:self];
        [tableView setDataSource:self];
        [tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        [tableView setAutoresizesSubviews:YES];
        tableView.headerView = nil;
        tableView.intercellSpacing = NSMakeSize(0, 0);
        if (@available(macOS 11.0, *)) {
            tableView.style = NSTableViewStyleFullWidth;
        }
        timeIdentifier = @"OwlLogCellTime";
        eventIdentifier = @"OwlLogCellEvent";
        //[tableView registerNib:nil forIdentifier:timeIdentifier];
        //[contentView.contentView addSubview:tableView];
        
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setAutoresizesSubviews:YES];
        [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [scrollView setDocumentView:tableView];
        
        MMScroller *scroller = [[MMScroller alloc] init];
        self.scroller = scroller;
        scroller.wantsLayer = YES;
        [scroller.layer setBackgroundColor:[LMAppThemeHelper getMainBgColor].CGColor];
        [scrollView setVerticalScroller:scroller];
        [tableView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
        
        
        //NSTableHeaderView *headerView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 300, 30)];
        //[tableView setHeaderView:headerView];
        NSTableColumn *timeColumn = [[NSTableColumn alloc] initWithIdentifier:timeIdentifier];
        timeColumn.width = frame.size.width;
        //[timeColumn.headerCell setStringValue:@"时间"];
        [timeColumn.headerCell setFont:[NSFontHelper getMediumSystemFont:12]];
        [timeColumn.headerCell setTextColor:[LMAppThemeHelper getSecondTextColor]];
        [timeColumn.headerCell setAlignment:NSTextAlignmentCenter];
        [tableView addTableColumn:timeColumn];
//
//        NSTableColumn *eventColumn = [[NSTableColumn alloc] initWithIdentifier:eventIdentifier];
//        eventColumn.width = frame.size.width - OwlLogCellWidth;
//        [eventColumn.headerCell setStringValue:@"事件"];
//        [eventColumn.headerCell setFont:[NSFontHelper getMediumSystemFont:18]];
//        [eventColumn.headerCell setTextColor:[NSColor colorWithHex:0x7E7E7E]];
//        [eventColumn.headerCell setAlignment:NSTextAlignmentCenter];
//        [tableView addTableColumn:eventColumn];
        
//        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(scrollView.mas_top).offset(20);
//            make.height.equalTo(@(frame.size.height-20));
//            make.width.equalTo(scrollView);
//        }];
        tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
        [contentView addSubview:scrollView];
        self.view = contentView;
        
        NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
        tfTitle.alignment = NSTextAlignmentCenter;
        tfTitle.bordered = NO;
        tfTitle.editable = NO;
        tfTitle.backgroundColor = [NSColor clearColor];
        tfTitle.stringValue = LMLocalizedSelfBundleString(@"监控日志", nil);
        tfTitle.font = [NSFontHelper getMediumSystemFont:16];
        tfTitle.textColor = [LMAppThemeHelper getTitleColor];
        [contentView addSubview:tfTitle];
        
        NSView *bLineview = [[NSView alloc] init];
        CALayer *lineLayer = [[CALayer alloc] init];
        lineLayer.backgroundColor = [NSColor colorWithWhite:0.90 alpha:1].CGColor;
        bLineview.layer = lineLayer;
        self.bLineview = bLineview;
        [contentView addSubview:bLineview];
        
        NSTextField *labelProcess = [[NSTextField alloc] init];
        labelProcess.alignment = NSTextAlignmentLeft;
        labelProcess.bordered = NO;
        labelProcess.editable = NO;
        labelProcess.stringValue = LMLocalizedSelfBundleString(@"软件进程", nil);
        labelProcess.backgroundColor = [NSColor clearColor];
        labelProcess.font = [NSFontHelper getMediumSystemFont:12];
        labelProcess.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelProcess];
        
        NSTextField *labelTime = [[NSTextField alloc] init];
        labelTime.alignment = NSTextAlignmentLeft;
        labelTime.bordered = NO;
        labelTime.editable = NO;
        labelTime.stringValue = LMLocalizedSelfBundleString(@"时间", nil);
        labelTime.backgroundColor = [NSColor clearColor];
        labelTime.font = [NSFontHelper getMediumSystemFont:12];
        labelTime.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelTime];
        
        NSTextField *labelEvent = [[NSTextField alloc] init];
        labelEvent.alignment = NSTextAlignmentLeft;
        labelEvent.bordered = NO;
        labelEvent.editable = NO;
        labelEvent.stringValue = LMLocalizedSelfBundleString(@"事件", nil);
        labelEvent.backgroundColor = [NSColor clearColor];
        labelEvent.font = [NSFontHelper getMediumSystemFont:12];
        labelEvent.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelEvent];
        
        NSTextField *labelOperation = [[NSTextField alloc] init];
        labelOperation.alignment = NSTextAlignmentLeft;
        labelOperation.bordered = NO;
        labelOperation.editable = NO;
        labelOperation.stringValue = LMLocalizedSelfBundleString(@"操作记录", nil);
        labelOperation.backgroundColor = [NSColor clearColor];
        labelOperation.font = [NSFontHelper getMediumSystemFont:12];
        labelOperation.textColor = [LMAppThemeHelper getSecondTextColor];
        [contentView addSubview:labelOperation];
        
        [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@9);
            make.centerX.equalTo(contentView);
        }];
        
        [labelProcess mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@(24+5));
            } else {
                make.left.equalTo(@24);
            }
        }];
        
        [labelTime mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                    make.left.equalTo(@(165+5));
                } else {
                    make.left.equalTo(@(180+5));
                }
            } else {
                make.left.equalTo(@180);
            }
        }];
        
        [labelEvent mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                if([LanguageHelper getCurrentSystemLanguageType] == SystemLanguageTypeEnglish){
                    make.left.equalTo(@(335+5));
                } else {
                    make.left.equalTo(@(350+5));
                }
            } else {
                make.left.equalTo(@(350));
            }
        }];
        
        [labelOperation mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(52));
            if (@available(macOS 11.0, *)) {
                make.left.equalTo(@(480+5));
            } else {
                make.left.equalTo(@(480));
            }
        }];
        
        [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(OwlWindowTitleHeight));
            make.left.equalTo(contentView);
            make.height.equalTo(@1);
            make.width.equalTo(contentView);
        }];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(owlLogChange:) name:OwlLogChangeNotication object:nil];
    }
    return self;
}



- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:self.bLineview];
    [LMAppThemeHelper setLayerBackgroundWithMainBgColorFor:self.scroller];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)owlLogChange:(NSNotification*)no{
    NSLog(@"owlLogChange");
    [tableView reloadData];
}

#pragma mark NSTableViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 40;
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    return [NSString stringWithFormat:@"%ld", row];
//}

//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    NSTextField *textField = [[NSTextField alloc] initWithFrame:(NSRect){.size = {100, 15}}];
//    textField.stringValue = [NSString stringWithFormat:@"%ld", row];
//    return textField;
//}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSDictionary *dict = [[Owl2Manager sharedManager].logArray objectAtIndex:row];
    NSString *time        = [dict objectForKey:OwlTime];
    NSString *appName     = [dict objectForKey:OwlAppName];
    NSString *appIconPath = [dict objectForKey:OwlAppIconPath];
    NSNumber *appAction   = [dict objectForKey:OwlAppAction];
    NSNumber *userAction  = [dict objectForKey:OwlUserAction];
    NSNumber *hardware    = [dict objectForKey:OwlHardware];
    
    NSString *idenifier = @"owlLogCellView";
    OwlCellView *view = [tableView makeViewWithIdentifier:idenifier owner:self];
    if (view == nil) {
        view = [[OwlCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 32)];
        view.identifier = idenifier;
    }
    view = [[OwlCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 32)];
    view.identifier = idenifier;
    
    void (^loadIconBlock)(NSImage *icon) = ^(NSImage *icon) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (icon) {
                view.iconImageView.image = icon;
            } else {
                view.iconImageView.image = [[NSBundle bundleForClass:[self class]] imageForResource:@"owl_default_icon"];
            }
        });
    };
    if (appIconPath) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 获取应用程序的图标
            NSData *data = [[NSData alloc] initWithContentsOfFile:appIconPath];
            if (data) {
                NSImage *image = [[NSImage alloc] initWithData:data];
                loadIconBlock(image);
            } else {
                loadIconBlock(nil);
            }
        });
    } else {
        loadIconBlock(nil);
    }

    if (time) view.labelTime.stringValue = time;
    if (appName) view.labelProcess.stringValue = appName;
    
    NSString *appActionStr = @"";
    switch (appAction.intValue) {
        case Owl2LogThirdAppActionStart:
            if (hardware.intValue == Owl2LogHardwareSystemAudio) {
                appActionStr = @"开始录制";
            } else {
                appActionStr = @"正在使用";
            }
            
            break;
        case Owl2LogThirdAppActionStartForScreenshot:
            appActionStr = @"已截取";
            break;
        case Owl2LogThirdAppActionStartForScreenRecording:
            appActionStr = @"开始录制";
            break;
        case Owl2LogThirdAppActionStop:
            if (hardware.intValue == Owl2LogHardwareSystemAudio) {
                appActionStr = @"结束录制";
            } else {
                appActionStr = @"停止使用";
            }
            break;
        case Owl2LogThirdAppActionStopForScreenRecording:
            appActionStr = @"结束录制";
            break;
        default:
            break;
    }
    
    NSString *hardwareStr = @"";    
    switch (hardware.intValue) {
        case Owl2LogHardwareVedio:
            hardwareStr = @"摄像头";
            break;
        case Owl2LogHardwareAudio:
            hardwareStr = @"麦克风";
            break;
        case Owl2LogHardwareSystemAudio:
            hardwareStr = @"扬声器音频";
            break;
        case Owl2LogHardwareScreen:
            hardwareStr = @"屏幕内容";
            break;
        default:
            break;
    }
    
    NSString *eventStr = [NSString stringWithFormat:@"%@%@", appActionStr, hardwareStr];
    view.labelEvent.stringValue = LMLocalizedSelfBundleString(eventStr, nil);;
    
    NSString *userActionStr = @"";
    switch (userAction.intValue) {
        case Owl2LogUserActionAllow:
            userActionStr = LMLocalizedSelfBundleString(@"本次允许", nil);
            break;
        case Owl2LogUserActionDefaultAllow: // 20s自动消失
        case Owl2LogUserActionClose:
        case Owl2LogUserActionContent:
            if (appAction.intValue == Owl2LogThirdAppActionStart ||
                appAction.intValue == Owl2LogThirdAppActionStartForScreenRecording ||
                appAction.intValue == Owl2LogThirdAppActionStartForScreenshot) {
                userActionStr = LMLocalizedSelfBundleString(@"默认允许", nil);
            }
            break;
        case Owl2LogUserActionAlwaysAllowed:
            userActionStr = LMLocalizedSelfBundleString(@"永久允许", nil);
            break;
        case Owl2LogUserActionPrevent:
            userActionStr = LMLocalizedSelfBundleString(@"阻止", nil);
            break;
        case Owl2LogUserActionNone:
        default:
            break;
    }
    view.labelOperation.stringValue = userActionStr;
    
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
    return [[OwlTableRowView alloc] initWithFrame:NSZeroRect];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [Owl2Manager sharedManager].logArray.count;
}

@end
