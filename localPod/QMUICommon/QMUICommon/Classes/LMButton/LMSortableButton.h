//
//  LMHeaderButton.h
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SortOrderType) {
    Descending = 0,
    Ascending
};

@interface LMSortableButton : NSButton
- (void)setSortOrderType:(SortOrderType)sortOrderType;
@property (nonatomic) SortOrderType sortOrderType;
- (void)toggleSortType;

-(void)setRefreshType:(BOOL)isRefresh;

@end

NS_ASSUME_NONNULL_END
