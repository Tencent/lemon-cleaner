//
//  LMFileCategoryItem.m
//  LemonFileMove
//
//  
//

#import "LMFileCategoryItem.h"
#import "LMResultItem.h"

@implementation LMFileCategoryItem

- (instancetype)initWithType:(LMFileCategoryItemType)type {
    self = [super init];
    if (self) {
        _type = type;
        
        [self setInit];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LMFileCategoryItem *item = [super copyWithZone:zone];
    item.type = self.type;
    item.iconName = self.iconName;
    
    return item;
}

- (void)setInit {
    self.subItems = [NSMutableArray array];
    if (_type == LMFileCategoryItemType_File90Before) {
        self.title = NSLocalizedStringFromTableInBundle(@"Documents created before 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"file_icon";
    } else if (_type == LMFileCategoryItemType_File90) {
        self.title = NSLocalizedStringFromTableInBundle(@"Documents created within the past 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"file_icon";
    } else if (_type == LMFileCategoryItemType_Image90Before) {
        self.title = NSLocalizedStringFromTableInBundle(@"Images created before 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"image_icon";
    } else if (_type == LMFileCategoryItemType_Image90) {
        self.title = NSLocalizedStringFromTableInBundle(@"Images created within the past 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"image_icon";
    } else if (_type == LMFileCategoryItemType_Video90Before) {
        self.title = NSLocalizedStringFromTableInBundle(@"Videos created before 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"video_icon";
    } else if (_type == LMFileCategoryItemType_Video90) {
        self.title = NSLocalizedStringFromTableInBundle(@"Videos created within the past 90 days", nil, [NSBundle bundleForClass:[self class]], @"");
        self.iconName = @"video_icon";
    }
}

- (NSControlStateValue)updateSelectState {
    int selectNum = 0;
    if (self.subItems && self.subItems.count > 0) {
        for (LMResultItem *item in self.subItems) {
            if (item.selecteState == NSControlStateValueOn) {
                selectNum ++;
            }
        }
        if (selectNum == 0) {
            self.selecteState = NSControlStateValueOff;
            return NSControlStateValueOff;
        } else if (selectNum < self.subItems.count) {
            self.selecteState = NSControlStateValueMixed;
            return NSControlStateValueMixed;
        } else if(selectNum >= self.subItems.count) {
            self.selecteState = NSControlStateValueOn;
            return NSControlStateValueOn;
        }
        return NSControlStateValueOff;
        
    } else {
        return  self.selecteState;
    }
}

@end
