//
//  LMPortStatViewController.m
//  LemonNetSpeed
//
//  
//  Copyright © 2019年 tencent. All rights reserved.
//

#import "LMPortStatViewController.h"
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSString+Extension.h>
#import "LMGradientTitleButton.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMUICommon/MMScroller.h>
#import <Masonry/Masonry.h>
#import <QMUICommon/QMStaticField.h>
#import <QMUICommon/COSwitch.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>

typedef void(^onRadioChange)(NSInteger, id sender);
typedef enum : NSUInteger {
    LmPortNormal,
    LmPortEstablished,
    LmPortListen
} LmPortState;
const int lmPortConSpace = 20;

const NSString* LMPortNumKey = @"LMPortNumKey";
const NSString* LMPortProtocolKey = @"LMPortProtocolKey";
const NSString* LMPortSpecKey = @"LMPortSpecKey";
const NSString* LMPortOpKey = @"LMPortOpKey";
const NSString* LMPortStateKey = @"LMPortStateKey";

@interface LMPortViewCell : NSTableCellView{
    
}
@property (nonatomic, strong) NSTextField *tfPort;
@property (nonatomic, strong) NSTextField *tfNetProtocol;
@property (nonatomic, strong) NSTextField *tfPortSpec;
@property (nonatomic, strong) COSwitch *portController;
@property (nonatomic, strong) NSTextField *tfConnectState;
@property (nonatomic, strong) onRadioChange action;
@property (nonatomic, assign) NSInteger indexRow;
//@property (weak) IBOutlet NSTextField *tfPort;
//@property (weak) IBOutlet NSTextField *tfNetProtocol;
//@property (weak) IBOutlet NSTextField *tfPortSpec;
//@property (weak) IBOutlet NSTextField *tfConnectState;
@end

@implementation LMPortViewCell

+ (NSTextField*)buildLabel:(NSString*)title font:(NSFont*)font color:(NSColor*)color{
    NSTextField *labelTitle = [[NSTextField alloc] init];
    labelTitle.stringValue = title;
    labelTitle.font = font;
    labelTitle.alignment = NSTextAlignmentLeft;
    labelTitle.bordered = NO;
    labelTitle.editable = NO;
    labelTitle.textColor = color;
    labelTitle.backgroundColor = [NSColor clearColor];
    return labelTitle;
}

//- (instancetype)init
//{
//    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
//    if (self) {
//
//    }
//    return self;
//}
- (instancetype)init{
    self = [super init];
    if (self) {

    }
    return self;
}
- (void)makeViewCell{
    
    _tfPort = [LMPortViewCell buildLabel:@"" font:[NSFontHelper getRegularSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    [_tfPort setLineBreakMode:NSLineBreakByTruncatingTail];
    [self addSubview:_tfPort];
    
    _tfNetProtocol = [LMPortViewCell buildLabel:@"" font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    [self addSubview:_tfNetProtocol];
    
    _tfPortSpec = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_1553136870_1", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    [_tfPortSpec setLineBreakMode:NSLineBreakByTruncatingTail];
    [self addSubview:_tfPortSpec];
    
    self.portController = [[COSwitch alloc] init];
    self.portController.isAnimator = NO;
    self.portController.on = YES;
    [self addSubview:self.portController];
    
    _tfConnectState = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"OwlWhiteListViewController_initWithFrame_1553136870_2", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getLightSystemFont:12] color:[NSColor colorWithHex:0x94979B]];
    [self addSubview:_tfConnectState];
    
    [_tfPort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(@(lmPortConSpace));
        make.width.equalTo(@(106));
    }];
    [_tfNetProtocol mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.left.equalTo(@(90));
        make.width.equalTo(@(80));
    }];
    [_tfPortSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(160));
        make.centerY.equalTo(self);
        make.width.equalTo(@240);
        make.height.equalTo(@(18));
    }];
    [_tfConnectState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-14));
        make.centerY.equalTo(self);
        make.width.equalTo(@30);
    }];
    [self.portController mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-114));
        make.centerY.equalTo(self);
        make.width.equalTo(@(40));
        make.height.equalTo(@(19));
    }];
}
- (void)makeSwitchController{
    __weak typeof(self) weakSelf = self;
    [self.portController setOnValueChanged:^(COSwitch *button) {
        //BOOL btnState = button.isOn;
        weakSelf.action(weakSelf.indexRow, weakSelf);
    }];
}
- (void)upPortCell:(NSDictionary *)portDic{
    _tfPort.stringValue = [portDic objectForKey:LMPortNumKey];
    _tfNetProtocol.stringValue = [portDic objectForKey:LMPortProtocolKey];
    _tfPortSpec.stringValue = [portDic objectForKey:LMPortSpecKey];
    _tfPortSpec.toolTip = [portDic objectForKey:LMPortSpecKey];
    _portController.on = [[portDic objectForKey:LMPortOpKey] boolValue];
    if ([[portDic objectForKey:LMPortStateKey] intValue] == LmPortNormal) {
        _tfConnectState.stringValue = @"--";
    } else if ([[portDic objectForKey:LMPortStateKey] intValue] == LmPortEstablished) {
        _tfConnectState.stringValue = NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_upPortCell__tfConnectState_1", nil, [NSBundle bundleForClass:[self class]], @"");
    } else if ([[portDic objectForKey:LMPortStateKey] intValue] == LmPortListen) {
        _tfConnectState.stringValue = NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_upPortCell__tfConnectState_2", nil, [NSBundle bundleForClass:[self class]], @"");
    }
}
// fix 不同系统选中下，textfield的文字颜色不同，有些是黑有些是白的问题
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle{
    [super setBackgroundStyle:NSBackgroundStyleLight];
}

@end




@interface LMPortTableRowView : NSTableRowView

@property (nonatomic, strong) NSColor *selectedColor;

@end
@implementation LMPortTableRowView

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _selectedColor =  [NSColor colorWithHex:0xE8E8E8 alpha:0.6];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:self.bounds];
    [_selectedColor set];
    [path fill];
}

@end


@interface LMPortStatViewController ()<NSTableViewDelegate, NSTableViewDataSource>
{
    NSTableView *tableView;
    NSString *identifier;
}
@property (nonatomic, strong) QMStaticField *tfPortInfo;
@property (nonatomic, strong) NSMutableArray *portArray;
@property (nonatomic, strong) NSTimer *statPortTimer;
@property (nonatomic, strong) NSString *plistPath;

@end

@implementation LMPortStatViewController


- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadView];
    }
    
    return self;
}

- (void)loadView {
    NSRect rect = NSMakeRect(0, 0, 600, 372);
    NSView *view = [[NSView alloc] initWithFrame:rect];
    CALayer *layer = [[CALayer alloc] init];
    layer.backgroundColor = [NSColor whiteColor].CGColor;
    view.layer = layer;
    self.view = view;
    
    [self viewDidLoad];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//
//    NSView *topView = [[NSView alloc] init];
//    CALayer *topLayer = [[CALayer alloc] init];
//    topLayer.backgroundColor = [NSColor whiteColor].CGColor;
//    topView.layer = topLayer;
//    [self.view addSubview:topView];
    
    NSTextField *tfTitle = [[NSTextField alloc] initWithFrame:NSZeroRect];
    tfTitle.alignment = NSTextAlignmentCenter;
    tfTitle.bordered = NO;
    tfTitle.editable = NO;
    tfTitle.backgroundColor = [NSColor clearColor];
    
    tfTitle.font = [NSFontHelper getMediumSystemFont:16];
    tfTitle.textColor = [NSColor colorWithHex:0x515151];
    tfTitle.stringValue = NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_tfTitle_1", nil, [NSBundle bundleForClass:[self class]], @"");
    [self.view addSubview:tfTitle];
    
    self.tfPortInfo = [[QMStaticField alloc] initWithFrame:NSZeroRect];
    self.tfPortInfo.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:self.tfPortInfo];
    
    NSView *bLineview = [[NSView alloc] init];
    bLineview.wantsLayer = YES;
    CALayer *lineLayer = [[CALayer alloc] init];
    lineLayer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:1].CGColor;
    bLineview.layer = lineLayer;
    [self.view addSubview:bLineview];
    
    NSTextField *labelPort = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_labelPort _2", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getMediumSystemFont:12]color:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:labelPort];
    NSTextField *labelProtocol = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_labelProtocol _3", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getMediumSystemFont:12]color:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:labelProtocol];
    NSTextField *labelSpec = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_labelSpec _4", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getMediumSystemFont:12]color:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:labelSpec];
    NSTextField *labelOp = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_labelOp _5", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getMediumSystemFont:12]color:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:labelOp];
    NSTextField *labelState = [LMPortViewCell buildLabel:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_viewDidLoad_labelState _6", nil, [NSBundle bundleForClass:[self class]], @"") font:[NSFontHelper getMediumSystemFont:12]color:[NSColor colorWithHex:0x515151]];
    [self.view addSubview:labelState];
    
    int titleTop = 42;
    int portInfoHeight = 32;
    NSRect frame = NSMakeRect(0, 0, 600, 372);
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height-titleTop-portInfoHeight-40)];
    
    tableView = [[NSTableView alloc] init];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setAutoresizesSubviews:YES];
    identifier = @"LMPortViewCell";
    
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizesSubviews:YES];
    [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [scrollView setDocumentView:tableView];
    
    MMScroller *scroller = [[MMScroller alloc] init];
    [scrollView setVerticalScroller:scroller];
    [tableView setBackgroundColor:[NSColor whiteColor]];
    
    [tableView setHeaderView:nil];
    NSTableColumn *portColumn = [[NSTableColumn alloc] initWithIdentifier:identifier];
//    NSTableColumn *portColumn = [[NSTableColumn alloc] init];
    portColumn.width = frame.size.width;
    [tableView addTableColumn:portColumn];
    tableView.frame = NSMakeRect(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
    [self.view addSubview:scrollView];
    
    
    int headTop = 10;
    [tfTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@9);
        make.centerX.equalTo(self.view);
    }];
    [bLineview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(titleTop+portInfoHeight));
        make.left.equalTo(@(lmPortConSpace-2));
        make.height.equalTo(@1);
        make.right.equalTo(@(-lmPortConSpace-2));
    }];
    [self.tfPortInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(bLineview.mas_top).offset(-headTop);
        make.left.equalTo(@(lmPortConSpace));
    }];
    [labelPort mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bLineview.mas_bottom).offset(headTop);
        make.left.equalTo(@(lmPortConSpace));
        make.width.equalTo(@(106));
    }];
    [labelProtocol mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bLineview.mas_bottom).offset(headTop);
        make.left.equalTo(@(90));
        make.width.equalTo(@(80));
    }];
    [labelSpec mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(160));
        make.top.equalTo(bLineview.mas_bottom).offset(headTop);
        make.width.equalTo(@160);
    }];
    [labelState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-30));
        make.top.equalTo(bLineview.mas_bottom).offset(headTop);
        make.width.equalTo(@30);
    }];
    [labelOp mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@(-96));
        make.top.equalTo(bLineview.mas_bottom).offset(headTop);
        make.width.equalTo(@(80));
        make.height.equalTo(@(19));
    }];
    self.portArray = [[NSMutableArray alloc] init];
//    NSString *strPath = @"/Users/torsysmeng/Library/Containers/com.tencent.WeWorkMac/Data/Library/Application Support/WXWork/Data/1688850523110004/Cache/File/2019-04/端口.txt";
//    NSString *originPort = [NSString stringWithContentsOfFile:strPath encoding:NSUTF8StringEncoding error:nil];
//    NSArray *oPortArray = [originPort componentsSeparatedByString:@"\n"];
//    for (int i = 0; i < oPortArray.count; i++) {
//        NSArray *itemPortArray = [[oPortArray objectAtIndex:i] componentsSeparatedByString:@" "];
//        if (itemPortArray.count < 3) {
//            continue;
//        }
//        NSMutableDictionary *item = [NSMutableDictionary dictionary];
//        [item setObject:[itemPortArray objectAtIndex:0] forKey:LMPortNumKey];
//        [item setObject:[itemPortArray objectAtIndex:1] forKey:LMPortProtocolKey];
//        [item setObject:[itemPortArray objectAtIndex:2] forKey:LMPortSpecKey];
//        [item setObject:@(YES) forKey:LMPortOpKey];
//        [item setObject:@(LmPortNormal) forKey:LMPortStateKey];
//        [self.portArray addObject:item];
//    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *support = [[NSString getUserHomePath] stringByAppendingPathComponent:@"Library/Application Support/com.tencent.lemon/net"];
    self.plistPath = [support stringByAppendingPathComponent:@"port.plist"];
    if (![fm fileExistsAtPath:support]){
        NSError *error = nil;
        if (![fm createDirectoryAtPath:support withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"create port support path fail:%@", error);
        }
        NSString *orginPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"port.plist"];
        if (![fm moveItemAtPath:orginPath toPath:self.plistPath error:&error]){
            NSLog(@"move port support path fail:%@", error);
        }
        //[self.portArray writeToFile:self.plistPath atomically:YES];
    }
    self.portArray = [[NSMutableArray alloc] initWithContentsOfFile:self.plistPath];
    
    [tableView reloadData];
    [self startPortTimer];
}
- (void)dealloc{
    [self stopPortTimer];
    [self savePlistFile];
}

- (void)startPortTimer{
    if (!self.statPortTimer) {
        self.statPortTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(statPort) userInfo:nil repeats:YES];
        [self.statPortTimer fire];
    }
}
- (void)stopPortTimer{
    if (self.statPortTimer) {
        [self.statPortTimer invalidate];
        self.statPortTimer = nil;
    }
}
- (void)savePlistFile{
    [self.portArray writeToFile:self.plistPath atomically:NO];
}
- (void)statPort{
    //NSLog(@"%s", __FUNCTION__);
    for (int i = 0; i < self.portArray.count; i++) {
        NSMutableDictionary *oldItem = [self.portArray objectAtIndex:i];
        [oldItem setObject:@(LmPortNormal) forKey:LMPortStateKey];
    }
    //NSString *outputStr = [QMShellExcuteHelper excuteCmd:@"netstat -f inet -n"];
    NSString *outputStr = [QMShellExcuteHelper excuteCmd:@"netstat -vatn |grep -E 'tcp4|tcp6|tcp46|udp4|udp6|udp46'"];
    NSArray *portArr = [outputStr componentsSeparatedByString:@"\n"];
    for (NSString *portItem in portArr) {
        //if ([portItem containsString:@"*.*                    *.*"]) {
        //    continue;
        //}
        //NSLog(@"portItem: %@", portItem);
        
        NSError* error;
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[^ ]+" options:0 error:&error];
        NSArray *tempArr = [regex matchesInString:portItem options:0 range:NSMakeRange(0, [portItem length])];
        NSMutableArray *reArr = [NSMutableArray arrayWithArray:tempArr];
        //netstat -f inet -n
        //tcp4       0      0  192.168.141.1.59960    192.168.141.128.445    ESTABLISHED
        //netstat -vatn |grep -E 'tcp4|tcp6|tcp46|udp4|udp6|udp46'
        //tcp4       0      0  10.68.56.61.53315      10.14.36.100.8080      ESTABLISHED 131072 131376  32971      0
        [reArr removeLastObject];
        [reArr removeLastObject];
        [reArr removeLastObject];
        [reArr removeLastObject];
        NSMutableArray *pis = [NSMutableArray array];
        for (NSTextCheckingResult *res in reArr) {
            [pis addObject:[portItem substringWithRange:res.range]];
        }
        if (pis.count < 5) {
            continue;
        }
        if ([[pis objectAtIndex:3] isEqualToString:@"*.*"] &&
            [[pis objectAtIndex:4] isEqualToString:@"*.*"]) {
            continue;
        }
        for (int i = 0; i < self.portArray.count; i++) {
            NSMutableDictionary *oldItem = [self.portArray objectAtIndex:i];
            if ([[[oldItem objectForKey:LMPortProtocolKey] lowercaseString] hasPrefix:@"tcp"] &&
                [[pis objectAtIndex:0] hasPrefix:@"tcp"]) {
                if ([[pis objectAtIndex:3] hasSuffix:[NSString stringWithFormat:@".%@", [oldItem objectForKey:LMPortNumKey]]]) {
                    if ([[pis objectAtIndex:5] hasSuffix:@"ESTABLISHED"]) {
                        [oldItem setObject:@(LmPortEstablished) forKey:LMPortStateKey];
                    } else if ([[pis objectAtIndex:5] hasSuffix:@"LISTEN"]) {
                        //如果已经获取到ESTABLISHED，忽略该Listent的
                        //TORSYSMENG-MC1:learn torsysmeng$ netstat -vatn |grep -E 'tcp4|tcp6|tcp46|udp4|udp6|udp46' |grep 110
                        //tcp4       0      0  127.0.0.1.110          127.0.0.1.52042        ESTABLISHED 371820 146988  34325      0
                        //tcp4       0      0  127.0.0.1.52042        127.0.0.1.110          ESTABLISHED 371820 146988  34373      0
                        //tcp4       0      0  *.110                  *.*                    LISTEN      131072 131072  34325      0
                        if ([[oldItem objectForKey:LMPortStateKey] intValue] != LmPortEstablished) {
                            [oldItem setObject:@(LmPortListen) forKey:LMPortStateKey];
                        }
                    } else {
                        [oldItem setObject:@(LmPortNormal) forKey:LMPortStateKey];
                    }
                    break;
                }
            } else if ([[[[self.portArray objectAtIndex:i] objectForKey:LMPortProtocolKey] lowercaseString] hasPrefix:@"udp"] &&
                       [[pis objectAtIndex:0] hasPrefix:@"udp"]) {
                if ([[pis objectAtIndex:3] hasSuffix:[NSString stringWithFormat:@".%@", [oldItem objectForKey:LMPortNumKey]]]) {
                    [oldItem setObject:@(LmPortListen) forKey:LMPortStateKey];
                    break;
                }
            }
        }
    }
    //非xib的方式，cell复用会失效（cell中保护有block等非一般对象情况下）
    //[tableView reloadData];
    for (int i = 0; i < [tableView subviews].count; i++) {
        LMPortTableRowView *rv = [[tableView subviews] objectAtIndex:i];
        if ([rv isKindOfClass:[LMPortTableRowView class]]) {
            for (int j = 0; j < [rv subviews].count; j++) {
                LMPortViewCell *viewCell = [[rv subviews] objectAtIndex:j];
                if ([viewCell isKindOfClass:[LMPortViewCell class]]) {
                    [viewCell upPortCell:[self.portArray objectAtIndex:i]];
                }
            }
        }
    }
    
    [self updateSpecLabel];
}
- (void)updateSpecLabel{
    int portTotal = (int)self.portArray.count, portUse = 0;
    
    for (int i = 0; i < self.portArray.count; i++) {
        NSMutableDictionary *oldItem = [self.portArray objectAtIndex:i];
        if ([[oldItem objectForKey:LMPortStateKey] intValue] > 0) {
            portUse++;
        }
    }
    //NSString *strPort = [NSString stringWithFormat:@"当前共有 %d 个常用端口，%d 个已连接", portTotal, portUse];
    NSString *strPort = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"LMPortStatViewController_updateSpecLabel_NSString_1", nil, [NSBundle bundleForClass:[self class]], @""), portUse, portTotal];
    NSString *strTotal = [NSString stringWithFormat:@"%d", portTotal];
    NSString *strUse = [NSString stringWithFormat:@"%d", portUse];
    int pos1 = 0, length1 = 0, pos2 = 0, length2 = 0;
    length1 = (int)[strUse length];
    pos1 = (int)[strPort rangeOfString:strUse].location;
    length2 = (int)[strTotal length];
    pos2 = (int)[[strPort substringWithRange:NSMakeRange(pos1+length1, [strPort length]-(pos1+length1))] rangeOfString:strTotal].location;
    pos2 = pos2 + pos1 + length1;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strPort];
    [attrStr addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x94979B]}
                     range:NSMakeRange(0, strPort.length)];
    [attrStr addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x04D999]}
                     range:NSMakeRange(pos1, length1)];
    [attrStr addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:12],
                             NSForegroundColorAttributeName: [NSColor colorWithHex:0x04D999]}
                     range:NSMakeRange(pos2, length2)];
    self.tfPortInfo.attributedStringValue = attrStr;
}

#pragma mark NSTableViewDelegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 40;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
//    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
//    if (cellView == nil)
//    {
//        NSLog(@"%s, %@, %d", __FUNCTION__, identifier, row);
//        NSRect cellFrame = [self.view bounds];
//        cellFrame.size.height = 65;
//
//        cellView = [[NSTableCellView alloc] initWithFrame:cellFrame];
//        [cellView setIdentifier:identifier];
//    }
//
//    return cellView;
    LMPortViewCell *view = [tableView makeViewWithIdentifier:self.identifier owner:self];
    if (view == nil) {
        view = [[LMPortViewCell alloc] init];
//        NSArray *topLevelObjects;
//        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"LMPortViewCell" bundle:[NSBundle bundleForClass:[LMPortViewCell class]]];
//        if (![nib instantiateWithOwner:self topLevelObjects:&topLevelObjects]) {
//            NSLog(@"%s, %d", __FUNCTION__, errno);
//        }
//        view = topLevelObjects.lastObject;
        [view makeViewCell];
        view.identifier = self.identifier;
        //NSLog(@"%s, %d", __FUNCTION__, row);
    }
    __weak typeof(self) weakSelf = self;
    view.indexRow = row;
    [view upPortCell:[self.portArray objectAtIndex:row]];
    view.action = ^(NSInteger indexRow, id sender) {
        NSMutableDictionary *portItem = [weakSelf.portArray objectAtIndex:indexRow];
        [portItem setObject:@(![[portItem objectForKey:LMPortOpKey] boolValue]) forKey:LMPortOpKey];

        NSString *strTcpPort = @"";
        NSString *strUdpPort = @"";
        //LMPortViewCell *opCell = (LMPortViewCell*)sender;
        for (NSDictionary *portItem in weakSelf.portArray) {
            if ([[portItem objectForKey:LMPortProtocolKey] isEqualToString:@"TCP"]) {
                if (![[portItem objectForKey:LMPortOpKey] boolValue]) {
                    if ([strTcpPort length] == 0) {
                        strTcpPort = [strTcpPort stringByAppendingString:[portItem objectForKey:LMPortNumKey]];
                    } else {
                        strTcpPort = [strTcpPort stringByAppendingString:[NSString stringWithFormat:@", %@", [portItem objectForKey:LMPortNumKey]]];
                    }
                }
            } else if ([[portItem objectForKey:LMPortProtocolKey] isEqualToString:@"UDP"]) {
                if (![[portItem objectForKey:LMPortOpKey] boolValue]) {
                    if ([strUdpPort length] == 0) {
                        strUdpPort = [strUdpPort stringByAppendingString:[portItem objectForKey:LMPortNumKey]];
                    } else {
                        strUdpPort = [strUdpPort stringByAppendingString:[NSString stringWithFormat:@", %@", [portItem objectForKey:LMPortNumKey]]];
                    }
                }
            }
        }
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[McCoreFunction shareCoreFuction] setLemonFirewallPortPF:strTcpPort udpPort:strUdpPort];
            
            [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(savePlistFile) object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf savePlistFile];
            });
        });
    };
    [view makeSwitchController];
    view.portController.isAnimator = YES;
    return view;
}

- (nullable NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row{
//    LMPortTableRowView *view = [tableView makeViewWithIdentifier:@"LMPortTableRowView" owner:self];
//    if (view == nil) {
//        view = [[LMPortTableRowView alloc] initWithFrame:NSZeroRect];
//        view.identifier = @"LMPortTableRowView";
//    }
    return [[LMPortTableRowView alloc] initWithFrame:NSZeroRect];;
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.portArray.count;
}

@end
