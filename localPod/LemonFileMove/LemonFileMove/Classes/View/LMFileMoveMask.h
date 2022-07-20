//
//  LMFileMoveMask.h
//  LemonFileMove
//
//  
//

#import <Cocoa/Cocoa.h>

@protocol LMFileMoveMaskDelegate <NSObject>

- (void)fileMoveMaskMoveIn;
- (void)fileMoveMaskMoveOut;
- (void)fileMoveMaskSelect:(BOOL)select;

@end

@interface LMFileMoveMask : NSView

@property (nonatomic, assign) BOOL isSelected;

@property (nonatomic, weak) id<LMFileMoveMaskDelegate> delegate;

@end
