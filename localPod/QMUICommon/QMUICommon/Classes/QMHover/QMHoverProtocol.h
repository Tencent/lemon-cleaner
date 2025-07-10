//
//  QMHoverProtocol.h
//  QMUICommon
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol QMHoverProtocol <NSObject>

@property (nonatomic, readonly) BOOL isHovered;
@property (nonatomic, copy) void (^hoverDidChange)(id<QMHoverProtocol> view);

@end

NS_ASSUME_NONNULL_END
