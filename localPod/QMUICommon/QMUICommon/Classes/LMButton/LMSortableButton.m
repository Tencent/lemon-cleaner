//
//  LMHeaderButton.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMSortableButton.h"


@interface LMSortableButton() {
    NSImage *ascendingImage;
    NSImage *descendingImage;
}

@end

@implementation LMSortableButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        ascendingImage = [bundle imageForResource:@"sortAscending"];
        descendingImage = [bundle imageForResource:@"sortDescending"];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
//    NSDictionary *tdic = @{NSFontAttributeName:self.attributedTitle fontAttributesInRange:<#(NSRange)#>};
//    NSRect tr = [self.title boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin attributes:tdic];
//
    // Drawing code here.
}

- (void)setSortOrderType:(SortOrderType)sortOrderType {
    _sortOrderType = sortOrderType;
    if (self.sortOrderType == Ascending) {
        self.image = ascendingImage;
    } else {
        self.image = descendingImage;
    }
    
}

- (void)toggleSortType {
    if (self.sortOrderType == Ascending) {
        self.sortOrderType = Descending;
    } else {
        self.sortOrderType = Ascending;
    }
}

-(void)setRefreshType:(BOOL)isRefresh{
    if (isRefresh) {
        [self refreshType];
    }else{
        [self normalType];
    }
}

-(void)refreshType{
    self.image = nil;
}

-(void)normalType{
    if (self.sortOrderType == Ascending) {
        self.image = ascendingImage;
    } else {
        self.image = descendingImage;
    }
}

@end
