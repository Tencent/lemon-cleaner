//
//  LemonHardwareViewController.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LemonHardwareViewController.h"
#import "HardwareDataCenter.h"
#import <QMUICommon/NSFontHelper.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <Masonry/Masonry.h>
#import "HardwareCellView.h"
#import "HardwareTableRowView.h"
#import <QMUICommon/MMScroller.h>
#import <QMUICommon/LMAppThemeHelper.h>

#define HARDWARE_CELL_VIEW              @"HardwareCellView"
#define HARDWARE_CELL_MORE_VIEW         @"HardwareMoreCellView"
#define HARDWARE_CELL_ELECTRIC_VIEW     @"HardwareElectircCellView"

#define MAIN_APP_BUNDLEID       @"com.tencent.Lemon"
#define DEFAULT_APP_PATH        @"/Applications/Tencent Lemon.app"

@interface LemonHardwareViewController ()<NSOutlineViewDelegate, NSOutlineViewDataSource,HardwareCellViewDelegate>{
    NSView* titleLineView;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) NSTextField *nameLabel;
@property (nonatomic, weak) NSTextField *descLabel;
@property (weak) NSProgressIndicator *progressView;
@property (nonatomic, strong) NSTimer *updateBattTimer;//刷新电池定时器


@end

@implementation LemonHardwareViewController

-(id)init{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle bundleForClass:self.class]];
    if (self) {
        
    }
    
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self initView];
    [self getData];
}

-(void)initView{
    NSTextField* titleLabel = [NSTextField labelWithStringCompat:NSLocalizedStringFromTableInBundle(@"LemonHardwareViewController_initView_1558009402_1", nil, [NSBundle bundleForClass:[self class]], @"")];
    titleLabel.alignment = NSTextAlignmentCenter;
    titleLabel.textColor = [LMAppThemeHelper getTitleColor];
    [titleLabel setFont:[NSFont systemFontOfSize:16]];
    [self.view addSubview:titleLabel];
    
    titleLineView = [[NSView alloc] init];
    CALayer *titleLineLayer = [[CALayer alloc] init];
    titleLineLayer.backgroundColor = [NSColor colorWithHex:0xF1F1F1].CGColor;
    titleLineView.layer = titleLineLayer;
    [self.view addSubview:titleLineView];
    
    NSTextField* nameLabel = [NSTextField labelWithStringCompat:@""];
    nameLabel.alignment = NSTextAlignmentCenter;
    nameLabel.textColor = [LMAppThemeHelper getTitleColor];
    [nameLabel setFont:[NSFont systemFontOfSize:24]];
    [self.view addSubview:nameLabel];
    self.nameLabel = nameLabel;
    
    NSTextField* descLabel = [NSTextField labelWithStringCompat:@""];
    descLabel.alignment = NSTextAlignmentCenter;
    descLabel.textColor = [NSColor colorWithHex:0x94979B];
    [descLabel setFont:[NSFont systemFontOfSize:12]];
    [self.view addSubview:descLabel];
    self.descLabel = descLabel;
    
    NSProgressIndicator *progressView = [[NSProgressIndicator alloc] init];
    progressView.style = NSProgressIndicatorStyleSpinning;
    progressView.indeterminate = YES;
    progressView.displayedWhenStopped = YES;
    [progressView setUsesThreadedAnimation:YES];
    [self.view addSubview:progressView];
    self.progressView = progressView;
    
    [self.outlineView setBackgroundColor:[LMAppThemeHelper getMainBgColor]];
    [self.outlineView setHeaderView:nil];
    //单击展开和收起
    self.outlineView.target = self;
    self.outlineView.action = @selector(clickExpandOrShrink);
    
    MMScroller *scrller = [[MMScroller alloc] init];
    [self.scrollView setVerticalScroller:scrller];
    
    //布局
    NSView *mView = self.view;
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(mView).offset(7);
        make.centerX.equalTo(mView);
    }];
    
    [titleLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(10);
        make.centerX.equalTo(mView);
        make.width.equalTo(mView);
        make.height.equalTo(@0.5);
    }];
    
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(mView).offset(60);
        make.top.equalTo(titleLineView.mas_bottom).offset(40);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nameLabel.mas_right).offset(7);
        make.centerY.equalTo(nameLabel);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.height.equalTo(@16);
        make.width.equalTo(@16);
    }];
}

- (void)viewWillLayout{
    [super viewWillLayout];
    [LMAppThemeHelper setDivideLineColorFor:titleLineView];
}

-(void)getData{
    [self.progressView setHidden:NO];
    [self.progressView startAnimation:nil];
    __weak LemonHardwareViewController *weakSelf = self;
    [[HardwareDataCenter shareInstance] getAllHardwareInfoWithBlock:^(NSMutableArray *infoArr, NSDictionary *infoDic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *name = [infoDic objectForKey:@"name"];
            NSString *value = [infoDic objectForKey:@"value"];
            if(name != nil){
                [weakSelf.nameLabel setStringValue:name];
            }
            if(value != nil){
                [weakSelf.descLabel setStringValue:value];
            }
            [weakSelf.progressView stopAnimation:nil];
            [weakSelf.progressView setHidden:YES];
            weakSelf.dataSource = infoArr;
            [weakSelf.outlineView reloadData];
            
            HardwareModel *diskModel = nil;
            if ((infoArr != nil) && ([infoArr count] > 0)) {
                for (HardwareModel *tempModel in infoArr) {
                    if (tempModel.hardwareType == HardwareTypeDisk) {
                        diskModel = tempModel;
                    }
                }
            }
            
            //如果有电池 就开启定时进行刷新
            BOOL isHaveBatt = [[HardwareDataCenter shareInstance] getIsHaveBattery];
            if (isHaveBatt) {
                [self startTimer];
            }
        });
    }];
}

#pragma mark -- 按钮回调

-(void)clickExpandOrShrink{
    NSInteger row = self.outlineView.clickedRow;
    id item = [self.outlineView itemAtRow:row];
    if ([item isKindOfClass:HardwareModel.class]) {
        HardwareModel *model = (HardwareModel *)item;
        if ([model.infoArr count] > 1) {
            if ([self.outlineView isItemExpanded:item]) {
                [self.outlineView.animator collapseItem:item];
            }else{
                [self.outlineView.animator expandItem:item];
            }
        }
    }
    
}

#pragma mark -- functionnal method 功能方法
//去除电池信息 重新加入
-(HardwareModel *)updateBatteryInfoWithNewBattModel:(HardwareModel *)newBattModel{
    HardwareModel *battModel = nil;
    for (HardwareModel *tempModel in self.dataSource) {
        if (tempModel.hardwareType == HardwareTypeElectroic) {
            battModel = tempModel;
        }
    }
    if (battModel != nil) {
        [battModel updateValueWithHardwareModel:newBattModel];
        return battModel;
    }
    
    return nil;
}

-(void)startTimer{
    if (self.updateBattTimer != nil) {
        return;
    }
    
    self.updateBattTimer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(updateBattInfo) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.updateBattTimer forMode:NSRunLoopCommonModes];
}

-(void)stopTimer{
    if (self.updateBattTimer == nil) {
        return;
    }
    
    [self.updateBattTimer invalidate];
    self.updateBattTimer = nil;
}

-(void)updateBattInfo{
    [[HardwareDataCenter shareInstance] getBatteryInfo:^(BOOL status, HardwareModel *model) {
        if (!status) {
            return ;
        }
        __weak LemonHardwareViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            HardwareModel *battModel = [weakSelf updateBatteryInfoWithNewBattModel:model];
            if (model != nil) {
                if (@available(macOS 10.13, *)) {
                    [weakSelf.outlineView reloadItem:battModel];
                }else{
                    [weakSelf.outlineView reloadData];
                }
            }
        });
    }];
}

#pragma mark -
#pragma mark outline view delegate

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    HardwareTableRowView *rowView = [[HardwareTableRowView alloc] initWithFrame:NSZeroRect];
    return rowView;
    return [[NSTableRowView alloc] init];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item) return [self.dataSource objectAtIndex:index];

    if ([item isKindOfClass:[HardwareModel class]])
    {
        HardwareModel *hardModel = (HardwareModel *)item;
        if ([hardModel.infoArr count] <= (index + 1)) {
            return [hardModel.infoArr lastObject];
        }else{
            return [hardModel.infoArr objectAtIndex:index + 1];
        }
    }

    return item;
}


- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if ([item isKindOfClass:[HardwareInfoModel class]]) {
        return 40;
    }
    return 58;
}

// Returns a Boolean value that indicates whether the a given item is expandable
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[HardwareModel class]]) {
        HardwareModel *hardModel = (HardwareModel *)item;
        if ([hardModel.infoArr count] > 1) {
            return YES;
        }
    }
    return NO;
}

// Returns the number of child items encompassed by a given item
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item) return [self.dataSource count];

    if ([item isKindOfClass:[HardwareModel class]])
    {
        HardwareModel *hardModel = (HardwareModel *)item;
        return [hardModel.infoArr count] - 1;
    }
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return item;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    HardwareCellView *cell = nil;
    if ([item isKindOfClass:[HardwareModel class]]) {
        HardwareModel *model = item;
        if (model.hardwareType == HardwareTypeElectroic) {
            cell = [outlineView makeViewWithIdentifier:HARDWARE_CELL_ELECTRIC_VIEW owner:self];
        }else{
            cell = [outlineView makeViewWithIdentifier:HARDWARE_CELL_VIEW owner:self];
        }
    }else if ([item isKindOfClass:[HardwareModel class]]){
        
    }else if([item isKindOfClass:[HardwareInfoModel class]]){
        cell = [outlineView makeViewWithIdentifier:HARDWARE_CELL_MORE_VIEW owner:self];
    }
    
    [cell setCellWithArr:item];
    // 当前是否选中
    //    [cell setHightLightStyle:([_outLineView selectedRow] == [_outLineView rowForItem:item])];
    cell.delegate = self;
    return cell;
}

- (void)HardwareCellViewDidSpaceButon {

    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:MAIN_APP_BUNDLEID].count == 0) {
        NSArray *arguments = @[[NSString stringWithFormat:@"1030"]];
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:DEFAULT_APP_PATH]
                                                      options:NSWorkspaceLaunchWithoutAddingToRecents
                                                configuration:@{NSWorkspaceLaunchConfigurationArguments: arguments}
                                                        error:NULL];
    }else {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kLEMON_MONITOR_NEED_DISK_SPACE"
                                                                       object:nil
                                                                     userInfo:nil
                                                           deliverImmediately:YES];

    }
    [self.view.window close];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    //    id subItem = [[item subItemArray] lastObject];
    //    if ([subItem isKindOfClass:[QMResultItem class]]
    //        && [[(QMResultItem *)subItem subItemArray] count] == 0)
    //        return YES;
    return NO;
}

@end
