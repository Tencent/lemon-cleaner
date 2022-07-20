//
//  LMWeChatScan.h
//  LemonFileMove
//
//  
//

#import <Foundation/Foundation.h>
#import "LMResultItem.h"
#import "LMFileMoveManger.h"

@protocol LMWeChatScanDelegate <NSObject>

- (void)weChatScanWithType:(LMFileMoveScanType)type resultItem:(LMResultItem *)item;

@end


@interface LMWeChatScan : NSObject

@property (nonatomic, weak) id<LMWeChatScanDelegate> delegate;

+ (instancetype)shareInstance;

- (void)starScanWechat;

- (void)scanWechat:(LMFileMoveScanType)type before:(BOOL)before;

@end
