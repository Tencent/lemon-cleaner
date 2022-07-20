//
//  FolderSelectCollectionViewItem.h
//  PathSelect
//
//  
//  Copyright © 2019 xuanqi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PathRemoveDelegate <NSObject>

- (void)removePath:(NSString *)path;

@end


@interface PathSelectCollectionViewItem : NSCollectionViewItem

@property(weak, nonatomic) NSImageView *folderImageView;
@property(weak, nonatomic) NSTextField *folderNameLabel;
@property(weak, nonatomic) id <PathRemoveDelegate> pathRemoveDelegate;


- (void)updateViewWith:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
