//
//  LMWorkWeChatScan.h
//  LemonFileMove
//
//  
//

#import "LMBaseScan.h"

@protocol LMWorkWeChatScanDelegate <NSObject>

- (void)workWeChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMWorkWeChatScan : LMBaseScan

@property (nonatomic, weak) id<LMWorkWeChatScanDelegate> delegate;

+ (instancetype)shareInstance;

- (void)starScanWorkWeChat;

- (void)scanWorkWeChat:(LMFileMoveScanType)type before:(BOOL)before;

@end
