//
//  LMSpaceBubbleViewController.m
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceBubbleViewController.h"
#import "MPScrollingTextField.h"
#import "LMItem.h"
#import <Masonry/Masonry.h>

#import "NSColor+Extension.h"
#import "LMPopoverRootView.h"

@interface LMSpaceBubbleViewController ()

@property(nonatomic, strong) NSImageView *iconImage;
@property(nonatomic, strong) MPScrollingTextField *nameLabel;
@property(nonatomic, strong) NSTextField *sizeLabel;
@property(nonatomic, strong) NSTextField *subLabel;
@property(nonatomic, strong) NSTextField *numLabel;
@property(nonatomic, strong) NSBox *box;
@property(nonatomic, strong) LMItem *item;

@end

@implementation LMSpaceBubbleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.s
    
//    self.view.wantsLayer = YES;
//    self.view.layer.backgroundColor = [NSColor blackColor].CGColor;
    
    
    self.iconImage = [[NSImageView alloc] init];
    [self.view addSubview:self.iconImage];
    [self.iconImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.equalTo(@30);
        make.leading.equalTo(self.view.mas_leading).offset(15);
        make.centerY.equalTo(self.view.mas_centerY);
    }];
    //
    self.nameLabel = [[MPScrollingTextField alloc] init];
    self.nameLabel.font = [NSFont systemFontOfSize:14.0];
    self.nameLabel.bordered = NO;
    self.nameLabel.editable = NO;
    self.nameLabel.alignment = NSTextAlignmentLeft;
    self.nameLabel.textColor = [NSColor whiteColor];
    self.nameLabel.backgroundColor = [NSColor blackColor];
    [self.view addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@16);
        make.top.equalTo(self.view.mas_top).offset(8);
        make.leading.equalTo(self.iconImage.mas_trailing).offset(8);
//        make.trailing.equalTo(self.mas_trailing).offset(-13);
    }];
    self.nameLabel.scrollingOffset = 10;
    //
    self.sizeLabel = [[NSTextField alloc] init];
    self.sizeLabel.alignment = NSTextAlignmentLeft;
    self.sizeLabel.font = [NSFont systemFontOfSize:12.0];
    self.sizeLabel.bordered = NO;
    self.sizeLabel.editable = NO;
    self.sizeLabel.backgroundColor = [NSColor blackColor];
    self.sizeLabel.textColor = [NSColor whiteColor];
    [self.view addSubview:self.sizeLabel];
    [self.sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@14);
        make.bottom.equalTo(self.view.mas_bottom).offset(-8);
        make.leading.equalTo(self.iconImage.mas_trailing).offset(8);
    }];
    //
    self.box = [[NSBox alloc] init];
    self.box.boxType = NSBoxCustom;
    self.box.wantsLayer = YES;
    self.box.layer.backgroundColor = [NSColor colorWithHex:0xC0C0C0].CGColor;
    [self.view addSubview:self.box];
    [self.box mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@12);
        make.width.equalTo(@1);
        make.leading.equalTo(self.sizeLabel.mas_trailing).offset(3);
        make.bottom.equalTo(self.view.mas_bottom).offset(-8);
    }];
    
    self.subLabel = [[NSTextField alloc] init];
    self.subLabel.alignment = NSTextAlignmentLeft;
    self.subLabel.font = [NSFont systemFontOfSize:12.0];
    self.subLabel.bordered = NO;
    self.subLabel.editable = NO;
    self.subLabel.backgroundColor = [NSColor blackColor];
    self.subLabel.textColor = [NSColor colorWithHex:0xC0C0C0];
    [self.view addSubview:self.subLabel];
    [self.subLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@14);
        make.bottom.equalTo(self.view.mas_bottom).offset(-8);
        make.leading.equalTo(self.box.mas_trailing).offset(3);
    }];
}


- (void)setUpData:(LMItem *)item {
    self.item = item;
    if (self.item.isDirectory == YES) {
        NSUInteger childNum = self.item.childItems.count;
        if (childNum > 9999) {
            self.subLabel.stringValue = NSLocalizedStringFromTableInBundle(@"more items", nil, [NSBundle bundleForClass:[self class]], @"");
        }else{
            self.subLabel.stringValue = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lu items", nil, [NSBundle bundleForClass:[self class]], @""),childNum];
        }
    }else{
        self.box.hidden = YES;
        self.subLabel.hidden = YES;
    }
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSImage *image = [workspace iconForFile:self.item.fullPath];
    self.iconImage.image = image;
    
    
    
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingMiddle;
    style.alignment = NSTextAlignmentLeft;
    
//    NSAttributedString *nameStr = [[NSAttributedString alloc] initWithString:self.item.fileName attributes:nameDict];
    self.nameLabel.stringValue = self.item.fileName;
    
    
    NSDictionary * sizeDict = @{
                            NSParagraphStyleAttributeName:style,
                            NSFontAttributeName:[NSFont systemFontOfSize:12.0]
                            };
    NSAttributedString *sizeStr = [[NSAttributedString alloc] initWithString:[self changeSizeStr:self.item.sizeInBytes] attributes:sizeDict];
    self.sizeLabel.attributedStringValue = sizeStr;
}


- (NSString *)changeSizeStr:(long long)text {
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
    return fileSizeStr;
}


- (void)loadView
{
    NSRect rect = NSMakeRect(0, 0, 190 , 48);
    LMPopoverRootView *view = [[LMPopoverRootView alloc] initWithFrame:rect];
    self.view = view;
    [self viewDidLoad];
}

@end
