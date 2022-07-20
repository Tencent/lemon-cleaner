//
//  LMPhotoCollectionViewLayout.m
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "LMPhotoCollectionViewLayout.h"

@implementation LMPhotoCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setItemSize:NSMakeSize(ITEM_WIDTH, ITEM_HEIGHT)];
        [self setMinimumInteritemSpacing:X_PADDING];
        [self setMinimumLineSpacing:Y_PADDING];
        [self setSectionInset:NSEdgeInsetsMake(Y_PADDING, X_PADDING, Y_PADDING, X_PADDING)];
    }
    return self;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath  API_AVAILABLE(macos(10.11)){
    NSCollectionViewLayoutAttributes *attributes;
    attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    [attributes setZIndex:[indexPath item]];
  
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(NSRect)rect {
    NSArray *layoutAttributesArray = [super layoutAttributesForElementsInRect:rect];
    for (NSCollectionViewLayoutAttributes *attributes in layoutAttributesArray) {
        [attributes setZIndex:[[attributes indexPath] item]];
    }
    return layoutAttributesArray;
}

@end
