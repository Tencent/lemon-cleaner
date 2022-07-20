//
//  LMAppCategoryItem.m
//  LemonFileMove
//
//  
//

#import "LMAppCategoryItem.h"
#import "LMFileCategoryItem.h"

@implementation LMAppCategoryItem

- (instancetype)initWithType:(LMAppCategoryItemType)type {
    self = [super init];
    if (self) {
        _type = type;
        
        [self setupFileArr];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LMAppCategoryItem *item = [super copyWithZone:zone];
    item.type = self.type;
    item.des = self.des;
    item.iconName = self.iconName;
    
    return item;
}

- (void)setupFileArr {
    self.subItems = [NSMutableArray array];
    LMFileCategoryItem *image90Before = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_Image90Before];
    LMFileCategoryItem *image90 = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_Image90];
    
    LMFileCategoryItem *file90Before = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_File90Before];
    LMFileCategoryItem *file90 = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_File90];
    
    LMFileCategoryItem *video90Before = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_Video90Before];
    LMFileCategoryItem *video90 = [[LMFileCategoryItem alloc] initWithType:LMFileCategoryItemType_Video90];
 
    [self.subItems addObject:file90Before];
    [self.subItems addObject:file90];
    [self.subItems addObject:image90Before];
    [self.subItems addObject:image90];
    [self.subItems addObject:video90Before];
    [self.subItems addObject:video90];

    if (_type == LMAppCategoryItemType_WeChat) {
        self.title = NSLocalizedStringFromTableInBundle(@"WeChat", nil, [NSBundle bundleForClass:[self class]], @"");
        self.des = NSLocalizedStringFromTableInBundle(@"Media from WeChat chat history", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"wx_icon";
    } else if (_type == LMAppCategoryItemType_WeCom) {
        self.title = NSLocalizedStringFromTableInBundle(@"WeCom", nil, [NSBundle bundleForClass:[self class]], @"");
        self.des = NSLocalizedStringFromTableInBundle(@"Media from WeCom chat history", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"wecom_icon";
    } else {
        self.title = @"QQ";
        self.des = NSLocalizedStringFromTableInBundle(@"Media from QQ chat history", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"qq_icon";
    }
}

- (NSControlStateValue)updateSelectState {
    int selectOnNum = 0;
    int selectMixNum = 0;
    if (self.subItems && self.subItems.count > 0) {
        for (LMFileCategoryItem *item in self.subItems) {
            [item updateSelectState];
            if (item.selecteState == NSControlStateValueMixed) {
                selectMixNum ++;
            } else if (item.selecteState == NSControlStateValueOn) {
                selectOnNum ++;
            }
        }
        if (selectOnNum == self.subItems.count) {
            self.selecteState = NSControlStateValueOn;
            return NSControlStateValueOn;
        } else if ((selectMixNum +selectOnNum) == 0) {
            self.selecteState = NSControlStateValueOff;
            return NSControlStateValueOff;
        } else {
            self.selecteState = NSControlStateValueMixed;
            return NSControlStateValueMixed;
        }
        
    } else {
        return  self.selecteState;
    }
}

@end
