//
//  OwlCollectionViewItem.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "OwlCollectionViewItem.h"
#import "OwlConstant.h"
#import <QMUICommon/LMAppThemeHelper.h>
@interface OwlCollectionViewItem (){
    
}
@end

@implementation OwlCollectionViewItem

- (id)init
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:bundle];
    if (self)
    {
        _appImg = nil;
        _appName = nil;
        _iconPath = nil;
        _btnState = NO;
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.view setWantsLayer:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    NSLog(@"%s, %@, %@, %@", __FUNCTION__, [[self view] subviews], self.appImageView, self.selectBtn);

    if (self.appImg) {
        [self.appImageView setImage:self.appImg];
    }
    if (self.appName) {
        [self.tfAppName setStringValue:self.appName];
    }
    self.selectBtn.state = self.btnState;
    [LMAppThemeHelper setTitleColorForTextField:self.tfAppName];
}

- (IBAction)clickOwlWhiteItem:(id)sender {
//    if (self.action) {
//        self.action(sender, self.index);
//    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OwlSelectAction" object:self];
}

+ (NSImage*)getDefaultAppIcon{
    static NSImage *defaultIcon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
        [defaultIcon setSize:NSMakeSize(64, 64)];
    });
    return defaultIcon;
}
- (void)updateUIWithDic:(NSDictionary*)representedObject{
    self.iconPath = [representedObject valueForKey:OwlAppIcon];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    //        NSLog(@"self.iconPath: %@", self.iconPath);
    if (self.iconPath && [self.iconPath length] > 0 && [fm fileExistsAtPath:self.iconPath]) {
        NSImage * iconImage = nil;
        iconImage = [[NSImage alloc] initWithContentsOfFile:self.iconPath];
        //iconImage = [[NSWorkspace sharedWorkspace] iconForFile:self.iconPath];
        if (iconImage != nil)
        {
            [iconImage setSize:NSMakeSize(64, 64)];
            //[self.appImageView setImage:iconImage];
            self.appImg = iconImage;
        }
    } else {
        if ([self.iconPath isEqualToString:@"console"]) {
            NSBundle *bundle = [NSBundle bundleForClass:[self class]];
            //[self.appImageView setImage:[bundle imageForResource:@"defaultTeminate"]];
            self.appImg = [bundle imageForResource:@"defaultTeminate"];
        } else {
            //[self.appImageView setImage:[OwlCollectionViewItem getDefaultAppIcon]];
            self.appImg = [OwlCollectionViewItem getDefaultAppIcon];
        }
    }
//    NSLog(@"OwlAppName: %@", [representedObject valueForKey:OwlAppName]);
    //[self.tfAppName setStringValue:[representedObject valueForKey:OwlAppName]];
    self.appName = [representedObject valueForKey:OwlAppName];
    self.btnState = [[representedObject valueForKey:@"isSelected"] boolValue];
    self.index = [[representedObject valueForKey:@"itemIndex"] intValue];
    
    if (self.appImg) {
        [self.appImageView setImage:self.appImg];
    }
    if (self.appName) {
        [self.tfAppName setStringValue:self.appName];
    }
    self.selectBtn.state = self.btnState;
}
-(void)setRepresentedObject:(id)representedObject{
    [super setRepresentedObject:representedObject];
    if (representedObject !=nil)
    {
        [self updateUIWithDic:representedObject];
    }
    else
    {
        [self.appImageView setImage:nil];
        [self.tfAppName setStringValue:@""];
    }
}

@end
