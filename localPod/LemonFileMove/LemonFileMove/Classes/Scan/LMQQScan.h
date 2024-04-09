//
//  LMQQScan.h
//  LemonFileMove
//
//  
//

#import "LMBaseScan.h"

@protocol LMQQScanDelegate <NSObject>

- (void)QQScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMQQScan : LMBaseScan

@property (nonatomic, weak) id<LMQQScanDelegate> delegate;

- (void)startScanQQ;

- (void)scanQQ:(LMFileMoveScanType)type before:(BOOL)before;

@end
