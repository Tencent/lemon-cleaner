//
//  AcceptSubViewClickOutlineView.h
//  QMUICommon
//
//  
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>



// outlineView 和 tableView 的 cell 中的 view 无法响应 mouse/gesture 事件(button 可以响应)
// 通过addAcceptSubViewType 可以运行特定类型的 view 响应 上述事件.
NS_ASSUME_NONNULL_BEGIN

@interface AcceptSubViewClickOutlineView : NSOutlineView

- (void)addAcceptSubViewType:(Class)class;
@end

NS_ASSUME_NONNULL_END
