//
//  LMQQScan.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMResultItem.h"
#import "LMFileMoveManger.h"

@protocol LMQQScanDelegate <NSObject>

- (void)QQScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMQQScan : NSObject

@property (nonatomic, weak) id<LMQQScanDelegate> delegate;

+ (instancetype)shareInstance;

- (void)starScanQQ;

- (void)scanQQ:(LMFileMoveScanType)type before:(BOOL)before;

@end
