//
//  LMFileCustomPathView.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LMFileCustomPathViewDelegate <NSObject>

- (void)fileCustomPathViewDidClick;

@end

@interface LMFileCustomPathView : NSView

@property (nonatomic, strong) NSImageView *diskImageBgView;
@property (nonatomic, strong) NSImageView *diskImageView;
@property (nonatomic, strong) NSTextField *diskNameLabel;
@property (nonatomic, strong) NSTextField *diskSizeLabel;
@property (nonatomic, strong) NSView *maskView;
@property (nonatomic, assign) BOOL selected;


@property (nonatomic, weak) id<LMFileCustomPathViewDelegate> delegate;

- (void)changeMaskLightColor:(BOOL)needChange;

@end

NS_ASSUME_NONNULL_END
