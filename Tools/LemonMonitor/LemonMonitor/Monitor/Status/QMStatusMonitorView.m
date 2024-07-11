//
//  QMStatusMonitorView.m
//  LemonMonitor
//

//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMStatusMonitorView.h"
#import "QMStatusCircleView.h"
#import "QMStatusTextField.h"
#import "QMNetworkSpeedFormatter.h"
#import <Masonry/Masonry.h>
#import <CoreFoundation/CFPreferences.h>
#import <CoreFoundation/CFBase.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMUICommon/LMCommonHelper.h>

#import "QMDragEffectView.h"

@interface QMStatusMonitorView ()
{
    NSMutableArray* mArrayForDarkModeAdaptiveViews;

}
@end


// 特别注意 Monitor上的字体颜色. 1. 要分暗黑主题和普通主题.
// 2.在外接其他显示器时, 非 Focus屏幕的字体颜色会自动变色.(10.14.4 之后出现) 如果是写死的颜色如 FFFFFF,不会自动变色, 如果是使用[NSColor controlTextColor] 会自动变色.
// 另外图片会自动变灰, 带固定颜色背景的 View 不会自动变色.


@implementation QMStatusMonitorView
@synthesize upSpeed;
@synthesize downSpeed;

- (QMEffectMode)effectMode
{
    return QMEffectStatusMode;
}

- (instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
//        logo = [[NSImageView alloc]initWithFrame:NSMakeRect(2, 3, 16, 16)];
//        [self addSubview:logo];
    }
        return self;
}
- (void)awakeFromNib
{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    mDarkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    
    NSLog(@"%s,mDarkModeOn=%d", __PRETTY_FUNCTION__, mDarkModeOn);
    
    mArrayForDarkModeAdaptiveViews = [[NSMutableArray alloc] init];
}

-(NSView*)getLogoContainerView:(NSSize*)size
{
    NSView* container = [[NSView alloc] init];
    NSImageView *logo1 = [[NSImageView alloc] init];
    logo1.image = [[NSBundle mainBundle] imageForResource:@"LOGO_16_black"];
    [logo1.image setTemplate:YES];
    [container addSubview:logo1];
    [logo1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(container);
        make.width.height.equalTo(@16);
    }];
    
    (*size).height = 22;
    (*size).width = 22;
    
    return container;
}

-(NSView*)getMemContainerView:(NSSize*)size
{
    NSView* containerMem = [[NSView alloc] init];
    
    
    NSTextField* memTextField = [NSTextField labelWithStringCompat:@"100%"];
    memTextField.font = [NSFont systemFontOfSize:11];


    [containerMem addSubview:memTextField];
    [memTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerMem.mas_centerX);
        make.top.equalTo(containerMem.mas_top).offset(1);
    }];
    NSTextField* memTextField2 = [NSTextField labelWithStringCompat:@"MEM"];
    memTextField2.font = [NSFont systemFontOfSize:7];
    [containerMem addSubview:memTextField2];
    [memTextField2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerMem.mas_centerX);
        make.bottom.equalTo(containerMem.mas_bottom);
    }];
    
    
    //    NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
    //    memTextField.textColor = [NSColor colorWithHex:textColor alpha:1.0];
    //    memTextField2.textColor = [NSColor colorWithHex:textColor alpha:1.0];

    memTextField.textColor = [self getTextColor];
    memTextField2.textColor = [self getTextColor];

    (*size).height = 22;
    (*size).width = 30;
    mMemUsageField = memTextField;
    [self setRamUsed:self.ramUsed];
    [mArrayForDarkModeAdaptiveViews addObject:memTextField];
    [mArrayForDarkModeAdaptiveViews addObject:memTextField2];
    
    return containerMem;
}

-(NSView*)getDiskContainerView:(NSSize*)size
{
    NSView* containerDisk = [[NSView alloc] init];


    NSTextField* DiskTextField = [NSTextField labelWithStringCompat:@"100%"];
    DiskTextField.font = [NSFont systemFontOfSize:11];
    [containerDisk addSubview:DiskTextField];
    [DiskTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerDisk.mas_centerX);
        make.top.equalTo(containerDisk.mas_top).offset(1);
    }];

    NSTextField* DiskTextField2 = [NSTextField labelWithStringCompat:@"SSD"];
    DiskTextField2.font = [NSFont systemFontOfSize:7];
    [containerDisk addSubview:DiskTextField2];
    [DiskTextField2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerDisk.mas_centerX);
        make.bottom.equalTo(containerDisk.mas_bottom);
    }];
    
//    NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
//    DiskTextField.textColor = [NSColor colorWithHex:textColor alpha:1.0];
//    DiskTextField2.textColor = [NSColor colorWithHex:textColor alpha:1.0];

    DiskTextField.textColor = [self getTextColor];
    DiskTextField2.textColor = [self getTextColor];
    
    (*size).height = 22;
    (*size).width = 30;
    mDiskUsageField = DiskTextField;
    [self setDiskUsed:self.diskUsed];
    [mArrayForDarkModeAdaptiveViews addObject:DiskTextField];
    [mArrayForDarkModeAdaptiveViews addObject:DiskTextField2];
    
    return containerDisk;
}

-(NSView*)getTmpContainerView:(NSSize*)size
{
    NSView* container = [[NSView alloc] init];
    
    
    NSTextField* mTextField = [NSTextField labelWithStringCompat:@"90C"];
    mTextField.font = [NSFont systemFontOfSize:11];
    [container addSubview:mTextField];
    [mTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container.mas_centerX);
        make.top.equalTo(container.mas_top).offset(1);
    }];
    
    NSTextField* mTextField2 = [NSTextField labelWithStringCompat:@"SEN"];
    mTextField2.font = [NSFont systemFontOfSize:7];
    [container addSubview:mTextField2];
    [mTextField2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container.mas_centerX);
        make.bottom.equalTo(container.mas_bottom);
    }];
    
//    NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
//    mTextField.textColor = [NSColor colorWithHex:textColor alpha:1.0];
//    mTextField2.textColor = [NSColor colorWithHex:textColor alpha:1.0];
    mTextField.textColor = [self getTextColor];
    mTextField2.textColor = [self getTextColor];
    
    (*size).height = 22;
    (*size).width = 30;
    mCpuTempField = mTextField;
    [self setTemperatureValue:self.temperatureValue];
    [mArrayForDarkModeAdaptiveViews addObject:mTextField];
    [mArrayForDarkModeAdaptiveViews addObject:mTextField2];
    
    return container;
}


-(NSView*)getRpmContainerView:(NSSize*)size
{
    NSView* container = [[NSView alloc] init];
    
    NSTextField* mTextField = [NSTextField labelWithStringCompat:@"9999"];
    mTextField.font = [NSFont systemFontOfSize:11];
    [container addSubview:mTextField];
    [mTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container.mas_centerX);
        make.top.equalTo(container.mas_top).offset(1);
    }];
    
    NSTextField* mTextField2 = [NSTextField labelWithStringCompat:@"RPM"];
    mTextField2.font = [NSFont systemFontOfSize:7];
    [container addSubview:mTextField2];
    [mTextField2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(container.mas_centerX);
        make.bottom.equalTo(container.mas_bottom);
    }];
    
//    NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
//    mTextField.textColor = [NSColor colorWithHex:textColor alpha:1.0];
//    mTextField2.textColor = [NSColor colorWithHex:textColor alpha:1.0];
    mTextField.textColor = [self getTextColor];
    mTextField2.textColor = [self getTextColor];
    
    (*size).height = 22;
    (*size).width = 30;
    mCpuFanSpeedField = mTextField;
    [self setFanSpeedValue:self.fanSpeedValue];
    [mArrayForDarkModeAdaptiveViews addObject:mTextField];
    [mArrayForDarkModeAdaptiveViews addObject:mTextField2];
    
    return container;
}

-(NSView*)getNetContainerView:(NSSize*)size
{
    // network container
    NSView* colNetContainerView = [[NSView alloc] init];
    
    
    NSImageView* upLoadSpeedIcon = [[NSImageView alloc] init];
    [colNetContainerView addSubview:upLoadSpeedIcon];
    [upLoadSpeedIcon setImage:[[NSBundle mainBundle] imageForResource:@"lemon_status_net_upload_white"]];
    [upLoadSpeedIcon.image setTemplate:YES];
    [upLoadSpeedIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(colNetContainerView.mas_left);
        make.top.mas_equalTo(colNetContainerView.mas_top);
        make.width.equalTo(@10);
        make.height.equalTo(@12);
    }];
    
    NSTextField* upLoadSpeedText = [NSTextField labelWithStringCompat:@"0"];
    upLoadSpeedText.attributedStringValue = [self getAttrStringFromNetSpeed:0];
    upLoadSpeedText.font = [NSFont systemFontOfSize:11];
    [colNetContainerView addSubview:upLoadSpeedText];
    [upLoadSpeedText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(upLoadSpeedIcon.mas_right);
        make.centerY.equalTo(upLoadSpeedIcon);
        //        make.top.mas_equalTo(colNetContainerView.mas_top).offset(16);
    }];
    
    NSImageView* downLoadSpeedIcon = [[NSImageView alloc] init];
    [colNetContainerView addSubview:downLoadSpeedIcon];
    [downLoadSpeedIcon setImage:[[NSBundle mainBundle]  imageForResource:@"lemon_status_net_download_white"]];
    [downLoadSpeedIcon.image setTemplate:YES];
    [downLoadSpeedIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(colNetContainerView.mas_left);
        make.bottom.mas_equalTo(colNetContainerView.mas_bottom);
        make.width.equalTo(@10);
        make.height.equalTo(@12);
    }];
    
    NSTextField* downLoadSpeedText = [NSTextField labelWithStringCompat:@"0"];
    downLoadSpeedText.attributedStringValue = [self getAttrStringFromNetSpeed:0];
    downLoadSpeedText.font = [NSFont systemFontOfSize:11];
    [colNetContainerView addSubview:downLoadSpeedText];
    [downLoadSpeedText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(downLoadSpeedIcon.mas_right);
        make.centerY.equalTo(downLoadSpeedIcon);
        //        make.bottom.mas_equalTo(colNetContainerView.mas_bottom).offset(-20);
    }];
    

//    NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
//    upLoadSpeedText.textColor = [NSColor colorWithHex:textColor alpha:1.0];
//    downLoadSpeedText.textColor = [NSColor colorWithHex:textColor alpha:1.0];
    upLoadSpeedText.textColor = [self getTextColor];
    downLoadSpeedText.textColor = [self getTextColor];
    
    (*size).height = 22;
    (*size).width = 50;
    mDownSpeedField = downLoadSpeedText;
    mUpSpeedField = upLoadSpeedText;
//    mUpLoadSpeedMeasurement = upLoadSpeedMeasurement;
//    mDownLoadSpeedMeasurement = downLoadSpeedMeasurement;
    [self setDownSpeed:self.downSpeed];
    [self setUpSpeed:self.upSpeed];
    [mArrayForDarkModeAdaptiveViews addObject:upLoadSpeedText];
    [mArrayForDarkModeAdaptiveViews addObject:downLoadSpeedText];
    
    return colNetContainerView;
}

- (NSView *)getCpuUsageContainerView:(NSSize *)size {
    NSView *containerView = [[NSView alloc] init];
    NSTextField *cpuValueText = [NSTextField labelWithStringCompat:@"%"];
    cpuValueText.font = [NSFont systemFontOfSize:11];
    [containerView addSubview:cpuValueText];
    [cpuValueText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.top.equalTo(containerView).offset(1);
    }];
    NSTextField *cpuLabel = [NSTextField labelWithStringCompat:@"CPU"];
    cpuLabel.font = [NSFont systemFontOfSize:7];
    [containerView addSubview:cpuLabel];
    [cpuLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.bottom.equalTo(containerView);
    }];
    cpuLabel.textColor = [self getTextColor];
    cpuValueText.textColor = [self getTextColor];
    (*size).height = 22;
    (*size).width = 30;
    mCpuUsageField = cpuValueText;
    [self setCpuUsed:self.cpuUsed];
    [mArrayForDarkModeAdaptiveViews addObject:cpuValueText];
    [mArrayForDarkModeAdaptiveViews addObject:cpuLabel];
    return containerView;
}

- (NSView *)getGpuUsageContainerView:(NSSize *)size {
    NSView *containerView = [[NSView alloc] init];
    NSTextField *gpuValueText = [NSTextField labelWithStringCompat:@"%"];
    gpuValueText.font = [NSFont systemFontOfSize:11];
    [containerView addSubview:gpuValueText];
    [gpuValueText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.top.equalTo(containerView).offset(1);
    }];
    NSTextField *gpuLabel = [NSTextField labelWithStringCompat:@"GPU"];
    gpuLabel.font = [NSFont systemFontOfSize:7];
    [containerView addSubview:gpuLabel];
    [gpuLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.bottom.equalTo(containerView);
    }];
    gpuLabel.textColor = [self getTextColor];
    gpuValueText.textColor = [self getTextColor];
    (*size).height = 22;
    (*size).width = 30;
    mGpuUsageField = gpuValueText;
    [self setGpuUsed:self.cpuUsed];
    [mArrayForDarkModeAdaptiveViews addObject:gpuValueText];
    [mArrayForDarkModeAdaptiveViews addObject:gpuLabel];
    return containerView;
}

- (NSColor *)getTextColor {
    return [NSColor controlTextColor];
}

- (void)updateTrackingAreas
{
    NSArray *trackingAreas = [self trackingAreas];
    for (NSTrackingArea *area in trackingAreas)
    {
        [self removeTrackingArea:area];
    }
    NSRect bounds = self.bounds;
    bounds.size.height += 1;
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:bounds options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveAlways
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}


- (void)setRamUsed:(double)value
{
    [super setRamUsed:value];
    mMemUsageField.stringValue = [NSString stringWithFormat:@"%d%%",(int)round(value*100)];
//    [super setRamUsed:value];
//
//    ramPieView.progress = value;
//    ramFieldView.progress = value;
}



-(void)setDiskUsed:(double)value {
    [super setDiskUsed:value];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->mDiskUsageField.stringValue = [NSString stringWithFormat:@"%d%%",(int)round(value*100)];
    });
}

- (void)setCpuUsed:(double)cpuUsed {
//    [super setCpuUsed:cpuUsed];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->mCpuUsageField.stringValue = [NSString stringWithFormat:@"%d%%",(int)round(cpuUsed*100)];
    });
}

- (void)setGpuUsed:(double)gpuUsed {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->mGpuUsageField.stringValue = [NSString stringWithFormat:@"%d%%",(int)round(gpuUsed*100)];
    });
}

-(NSAttributedString*)getAttrStringFromNetSpeed:(float)value
{
    const float oneMB = 1024;
    float _value = 0;
    NSString * formatStr = nil;
    if (value > 1000)
    {
        _value = value / oneMB;
        formatStr = @" M/s";
    }
    else
    {
        _value = value;
        formatStr = @" K/s";
    }
    if (_value > 100)
    {
        NSString* str =  [NSString stringWithFormat:@"%d%@", (int)_value, formatStr];
//        NSString* str = [NSString stringWithFormat:@"%d M/s", (int)valueForShow];
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:str];
        [attributeString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:8] range:NSMakeRange(str.length-3, 3)];
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
        paragraph.alignment = NSTextAlignmentCenter;
        [attributeString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, str.length)];
        return attributeString;
    }
    else
    {
        NSString* str = [NSString stringWithFormat:@"%.1f%@", _value, formatStr];
//        NSString* str = [NSString stringWithFormat:@"%.1f K/s", valueForShow];
        NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:str];
        [attributeString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:8] range:NSMakeRange(str.length-3, 3)];
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init];
        paragraph.alignment = NSTextAlignmentCenter;
        [attributeString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, str.length)];
        return attributeString;
    }
}

- (void)setUpSpeed:(float)value
{
    [super setUpSpeed:value];
    mUpSpeedField.attributedStringValue = [self getAttrStringFromNetSpeed:value/1000.f];
    

}

- (void)setDownSpeed:(float)value
{
    [super setDownSpeed:value];
    mDownSpeedField.attributedStringValue = [self getAttrStringFromNetSpeed:value/1000.f];
    
}

-(void)setTemperatureValue:(double)value
{
    [super setTemperatureValue:value];
    mCpuTempField.stringValue = [NSString stringWithFormat:@"%d°C", (int)(value)];
}

-(void)setFanSpeedValue:(float)value
{
    [super setFanSpeedValue:value];
    mCpuFanSpeedField.stringValue = [NSString stringWithFormat:@"%d", (int)(value)];
}





- (void)setStatusType:(long)type
{
    NSLog(@"%s, type=%lx", __PRETTY_FUNCTION__, type);
    
    // remove all subview
    while (self.subviews.count > 0) {
        NSView* subview = (NSView*)self.subviews.firstObject;
        [subview removeFromSuperview];
    }
    
    [mArrayForDarkModeAdaptiveViews removeAllObjects];
        
//    self.wantsLayer = true;
//    self.layer.backgroundColor = [NSColor colorWithHex:0xff0000 alpha:1.0f].CGColor;
//    type = STATUS_TYPE_LOGO|STATUS_TYPE_NET| STATUS_TYPE_MEM | STATUS_TYPE_DISK| STATUS_TYPE_FAN| STATUS_TYPE_TEP|STATUS_TYPE_NET;
//   STATUS_TYPE_LOGO | STATUS_TYPE_MEM | STATUS_TYPE_DISK| STATUS_TYPE_FAN| STATUS_TYPE_TEP|STATUS_TYPE_NET;
    
    NSMutableArray* containerArray= [[NSMutableArray alloc] init];
    NSMutableArray* containerSize = [[NSMutableArray alloc] init];
    self.statusNum = 0;
    NSSize size;
    BOOL showOne = NO;
    if (type & STATUS_TYPE_LOGO)
    {
        NSView* containerLogo = [self getLogoContainerView:&size];
        [containerArray addObject:containerLogo];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    
    if (type & STATUS_TYPE_CPU)
    {
        NSView* containerCpu = [self getCpuUsageContainerView:&size];
        [containerArray addObject:containerCpu];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    
    if (type & STATUS_TYPE_GPU) {
        NSView* containerGpu = [self getGpuUsageContainerView:&size];
        [containerArray addObject:containerGpu];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    
    if (type & STATUS_TYPE_MEM)
    {
        NSView* containerMem = [self getMemContainerView:&size];
        [containerArray addObject:containerMem];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }

    if (type & STATUS_TYPE_DISK)
    {
        NSView* containerDisk = [self getDiskContainerView:&size];
        [containerArray addObject:containerDisk];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    
    if (type & STATUS_TYPE_TEP)
    {
        NSView* containerTmp = [self getTmpContainerView:&size];
        [containerArray addObject:containerTmp];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }

    if (type & STATUS_TYPE_FAN)
    {
        NSView* containerRpm = [self getRpmContainerView:&size];
        [containerArray addObject:containerRpm];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    
    if (type & STATUS_TYPE_NET)
    {
        NSView* containerNet = [self getNetContainerView:&size];
        [containerArray addObject:containerNet];
        [containerSize addObject:[NSValue valueWithSize:size]];
        showOne = YES;
    }
    self.statusNum = (int)containerArray.count ;
    if (!showOne) {
        NSView* containerLogo = [self getLogoContainerView:&size];
        [containerArray addObject:containerLogo];
        [containerSize addObject:[NSValue valueWithSize:size]];
    }
    
    for (int i=0; i<containerArray.count ; i++)
    {
        NSView* container  = [containerArray objectAtIndex:i];
        NSNumber* width = [NSNumber numberWithFloat:[[containerSize objectAtIndex:i] sizeValue].width];
        NSNumber* height = [NSNumber numberWithFloat:[[containerSize objectAtIndex:i] sizeValue].height];
        
        if (i == 0)
        {
            [self addSubview:container];
            [container mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.mas_centerY);
                if (containerArray.count == 1)
                {
                    make.left.equalTo(self.mas_left).offset(2);
                    make.right.equalTo(self.mas_right).offset(-2);
                }
                else
                {
                    make.left.equalTo(self.mas_left).offset(0);
                }
                make.height.equalTo(height);
                make.width.equalTo(width);
            }];
        }
        else if (i == containerArray.count - 1)
        {
            //
            NSView* containerPre = [containerArray objectAtIndex:i-1];
            NSImageView *dividerIcon = [self getDividerImageView];
            [self addSubview:dividerIcon];
            [dividerIcon mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(containerPre.mas_right).offset(3);
                make.centerY.equalTo(self.mas_centerY);
                make.width.equalTo(@1);
                make.height.equalTo(@16);
            }];
            
            [self addSubview:container];
            [container mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.mas_centerY);
                make.left.equalTo(dividerIcon.mas_right).offset(3);
                make.right.equalTo(self.mas_right);
                make.height.equalTo(height);
                make.width.mas_equalTo(width.intValue + 10);
            }];
        }
        else
        {
            NSView* containerPre = [containerArray objectAtIndex:i-1];
            NSImageView *dividerIcon = [self getDividerImageView];
            [self addSubview:dividerIcon];

            [dividerIcon mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(containerPre.mas_right).offset(3);
                make.centerY.equalTo(self.mas_centerY);
                make.width.equalTo(@1);
                make.height.equalTo(@16);
            }];
            
            //
            [self addSubview:container];
            [container mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(self.mas_centerY);
                make.left.equalTo(dividerIcon.mas_right).offset(3);
                make.height.equalTo(height);
                make.width.equalTo(width);
            }];
        }
    }
}

- (NSImageView *)getDividerImageView {
    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.image = [NSImage imageNamed:@"status_divider"];
    [imageView.image setTemplate:YES];
    return imageView;
}

-(void)onDarkModeChange
{
    if ([LMCommonHelper isMacOS11]) {
        return;
    }
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    mDarkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    
    NSLog(@"%s,mDarkModeOn=%d", __PRETTY_FUNCTION__, mDarkModeOn);

    for (NSTextField* textField in mArrayForDarkModeAdaptiveViews)
    {
//        NSInteger textColor = mDarkModeOn ? 0xFFFFFF : 0x333333;
//        textField.textColor = [NSColor colorWithHex:textColor alpha:1.0];
        textField.textColor = [NSColor controlTextColor];
    }
}

@end
