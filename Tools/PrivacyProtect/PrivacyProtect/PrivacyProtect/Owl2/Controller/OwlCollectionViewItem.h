//
//  OwlCollectionViewItem.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/LMCheckboxButton.h>

typedef void(^selectOwlWhiteListItem)(id, int);
@interface OwlCollectionViewItem : NSCollectionViewItem

@property (weak) IBOutlet LMCheckboxButton *selectBtn;
@property (assign) int index;
@property (weak) IBOutlet NSTextField *tfAppName;
@property (weak) IBOutlet NSImageView *appImageView;
@property (strong) NSImage *appImg;
@property (strong) NSString *appName;
@property (strong) NSString *iconPath;
@property (assign) BOOL btnState;
@property (nonatomic, strong) selectOwlWhiteListItem action;

+ (NSImage*)getDefaultAppIcon;
- (void)updateUIWithDic:(NSDictionary*)representedObject;
@end
