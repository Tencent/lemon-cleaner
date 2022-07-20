//
//  LMFileMoveWnController.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseWindowController.h>

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveWnController : QMBaseWindowController

- (void)showMainView;

- (void)showProcessView;

- (void)showResultViewWithSuccessStatus:(BOOL)isSucceed;

@end

NS_ASSUME_NONNULL_END
