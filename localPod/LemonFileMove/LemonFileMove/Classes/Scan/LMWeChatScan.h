//
//  LMWeChatScan.h
//  LemonFileMove
//
//  
//

#import "LMBaseScan.h"

@protocol LMWeChatScanDelegate <NSObject>

- (void)weChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMWeChatScan : LMBaseScan

@property (nonatomic, weak) id<LMWeChatScanDelegate> delegate;

- (void)startScanWeChat;

- (void)scanWeChat:(LMFileMoveScanType)type before:(BOOL)before;

@end
