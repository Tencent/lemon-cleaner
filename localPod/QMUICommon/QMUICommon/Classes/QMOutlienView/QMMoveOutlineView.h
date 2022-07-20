//
//  QMOutlineView.h
//  QMCleaner
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QMMoveOutlineViewDelegate <NSObject>

- (NSButton *)outlineViewMoveButton;

@optional
- (NSPoint)moveButtonPoint:(NSInteger)row;
- (BOOL)canShowMoveButton:(NSInteger)row;
- (void)outlineViewWillShowMenu:(NSInteger)row;

@end

@interface QMMoveOutlineView : NSOutlineView
{
    NSInteger m_lastRow;
}
@property (assign) id<QMMoveOutlineViewDelegate> moveOutlineViewDelegate;
@property (nonatomic, assign) BOOL needAnimation;

- (void)hiddenMoveButton;
- (void)resetMoveButton;

@end


@interface QMMoveScrollView : NSScrollView
{
    IBOutlet QMMoveOutlineView * outlineView;
}

@end
