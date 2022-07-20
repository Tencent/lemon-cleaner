//
//  LMSpaceMainViewController.h
//  LemonSpaceAnalyse
//
//  
//

#import "LMSpaceBaseViewController.h"

@class LMItem;

@protocol LMSpaceMainViewControllerDelegate <NSObject>

-(void)spaceMainViewControllerEnd:(LMItem *)topItem;

@end

@interface LMSpaceMainViewController : LMSpaceBaseViewController

@property (nonatomic, weak) id<LMSpaceMainViewControllerDelegate> delegete;
@property (strong) IBOutlet NSView *scanView;
@property (weak) IBOutlet NSView *startView;

- (void)showStartView;
- (void)restartScan;
- (void)SpaceMainWindowShouldClose;
@end


