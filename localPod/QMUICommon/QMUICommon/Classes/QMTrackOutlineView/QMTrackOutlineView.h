//
//  QMTrackOutlineView.h
//  QMUICommon
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QMUICommon/QMBaseOutlineView.h>

@interface QMTrackOutlineView : QMBaseOutlineView
@property (nonatomic, strong) NSView *overView;
@property (nonatomic, strong) NSIndexSet *showLevel;
@property (nonatomic, readonly) NSInteger trackRow;

@end
