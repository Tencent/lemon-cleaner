//
//  LMFileMoveResultSuccessView.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>
#import "LMFileMoveManger.h"

NS_ASSUME_NONNULL_BEGIN

@interface LMFileMoveResultSuccessView : NSView

@property (nonatomic, strong) dispatch_block_t returnButtonClickHandler;
@property (nonatomic, strong) dispatch_block_t showInFinderLabelOnClickHandler;

+ (instancetype)resultViewWithType:(LMFileMoveTargetPathType)type
                      releaseSpace:(long long)releaseSpace
                    targetFilePath:(NSString *)targetFilePath;

@end

NS_ASSUME_NONNULL_END
