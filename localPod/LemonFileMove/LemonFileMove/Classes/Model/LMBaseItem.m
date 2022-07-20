//
//  LMBaseItem.m
//  LemonFileMove
//
//  
//

#import "LMBaseItem.h"

@implementation LMBaseItem

- (void)setStateWithSubItemsIfHave:(NSControlStateValue)stateValue {
    if (self.subItems) {
        for (LMBaseItem *item in self.subItems) {
            // 注意: 这里需要使用stateValue 而不是 self.state, 因为 self.state 还未改变.
            [item setStateWithSubItemsIfHave:stateValue];
        }
    }

    self.selecteState = stateValue;
}

- (NSControlStateValue)updateSelectState {
    return NSControlStateValueOn;
}

- (id)copyWithZone:(NSZone *)zone {
    LMBaseItem *item = [[[self class] alloc] init];
    item.subItems = [self.subItems mutableCopy];
    item.selecteState = self.selecteState;
    item.title = [self.title copy];
    item.fileSize = self.fileSize;
    item.isMoveFailed = self.isMoveFailed;
    item.moveFailedFileSize = self.moveFailedFileSize;
    
    return item;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@, size:%lld, state=%ld, isMoveFailed=%@, subItems=\n%@", self.title, self.fileSize, self.selecteState, self.isMoveFailed?@"YES":@"NO", [self.subItems debugDescription]];
}

@end
