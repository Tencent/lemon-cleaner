//
//  LMWorkWeChatScan.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMResultItem.h"
#import "LMFileMoveManger.h"


@protocol LMWorkWeChatScanDelegate <NSObject>

- (void)workWeChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMWorkWeChatScan : NSObject

@property (nonatomic, weak) id<LMWorkWeChatScanDelegate> delegate;

+ (instancetype)shareInstance;

- (void)starScanWorkWeChat;

- (void)scanWorkWeChat:(LMFileMoveScanType)type before:(BOOL)before;

@end
