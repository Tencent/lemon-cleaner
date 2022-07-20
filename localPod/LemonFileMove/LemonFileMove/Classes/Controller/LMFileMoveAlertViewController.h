//
//  LMFileMoveAlertViewController.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

#define LM_FILE_MOVE_ALERT_WINDOW_SIZE CGSizeMake(412, 140)

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveAlertViewController : NSViewController

- (instancetype)initWithImage:(NSImage *)image
                        title:(NSString *)title
          continueButtonTitle:(NSString *)continueButtonTitle
              stopButtonTitle:(NSString *)stopButtonTitle
              continueHandler:(dispatch_block_t)continueHandler
                  stopHandler:(dispatch_block_t)stopHandler;

@end

NS_ASSUME_NONNULL_END
