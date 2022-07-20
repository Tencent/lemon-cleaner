//
//  LMSpaceView.h
//  LemonSpaceAnalyse
//
//  
//

#import <Cocoa/Cocoa.h>

@class LMItem;
@class LMSpaceView;

@protocol LMSpaceViewDelegate <NSObject>

-(void)LMSpaceViewmouseDown:(LMSpaceView *)view;

@end

@protocol LMSpaceViewMoveDelegate <NSObject>

-(void)LMSpaceViewmouse:(LMItem *)item;

-(void)LMSpaceViewInfoClose:(BOOL)result;

-(void)LMSpaceViewInfoPoint:(NSPoint)point;

@end

@interface LMSpaceView : NSButton

@property(nonatomic, strong) LMItem *item;
@property (nonatomic, weak) id <LMSpaceViewDelegate> delegate;
@property (nonatomic, weak) id <LMSpaceViewMoveDelegate> moveDelegate;

@end


