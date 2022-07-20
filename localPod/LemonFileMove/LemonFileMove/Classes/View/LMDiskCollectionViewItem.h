//
//  LMDiskCollectionViewItem.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import "LMCircleDiskView.h"
#import "Disk.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LMDiskCollectionViewItemDelegate <NSObject>

- (void)collectionViewItemBeSelect:(Disk *)model;

@end

@interface LMDiskCollectionViewItem : NSCollectionViewItem

@property (nonatomic, strong) NSImageView *diskImageBgView;
@property (nonatomic, strong) NSImageView *diskImageView;
@property (nonatomic, strong) LMCircleDiskView *diskImageCircleView;
@property (nonatomic, strong) NSTextField *diskNameLabel;
@property (nonatomic, strong) NSTextField *diskSizeLabel;
@property (nonatomic, strong) NSView *maskView;
@property (nonatomic, assign) BOOL isNone;
@property (nonatomic, assign) BOOL noEnough;
@property (nonatomic, strong) Disk *model;
@property (nonatomic, weak) id<LMDiskCollectionViewItemDelegate> delegate;

- (void)setNoneDisk;
- (void)setDiskModel:(Disk *)model;
@end

NS_ASSUME_NONNULL_END
