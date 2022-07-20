//
//  BFPageControl.h
//

//  Copyright (c) 2012 boxedfolder.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BFPageControl;

@protocol BFPageControlDelegate <NSObject>
@optional
-(void)pageControl: (BFPageControl *)pageControl didSelectPageAtIndex: (NSInteger)index;
@end

@interface BFPageControlCell : NSButtonCell
@property (nonatomic)BOOL useHandCursor;
@property (copy)void (^drawingBlock)(NSRect, NSView *, BOOL, BOOL);
@end

@interface BFPageControl : NSView

///---------------------------------------------------------------------------------------
/// @name Managing the Page Navigation
///---------------------------------------------------------------------------------------

/**
 * The current page, shown by the receiver as a white dot.
 */
@property(nonatomic)NSInteger currentPage;

/**
 * The number of pages the receiver shows (as dots).
 */
@property(nonatomic)NSInteger numberOfPages;

/**
 *  A Boolean value that controls whether the page indicator is hidden when there is only one page.
 */
@property(nonatomic)BOOL hidesForSinglePage;

///---------------------------------------------------------------------------------------
/// @name Updating the Page Display
///---------------------------------------------------------------------------------------

/**
 *  Updates the page indicator to the current page.
 */
-(void)updateCurrentPageDisplay;

/**
 *  Returns the size the receiver’s bounds should be to accommodate the given number of pages.
 */
-(NSSize)sizeForNumberOfPages: (NSInteger)pageCount;

///---------------------------------------------------------------------------------------
/// @name Visual Properties
///---------------------------------------------------------------------------------------

/**
 *  Color for selected dot.
 */
@property (nonatomic)NSColor *selectedColor;

/**
 *  Color for highlight dot.
 */
@property (nonatomic)NSColor *highlightColor;

/**
 *  Color for unselected dot.
 */
@property (nonatomic)NSColor *unselectedColor;

/**
 *  Diameter size (Points).
 */
@property (nonatomic)CGFloat indicatorDiameterSize;

/**
 *  Margin between dots.
 */
@property (nonatomic)CGFloat indicatorMargin;

/**
 *  Use Hand-Cusor on dots.
 */
@property (nonatomic)BOOL useHandCursor;

/**
 *  Optional drawing block (custom dot drawing).
 */
-(void)setDrawingBlock: (void (^)(NSRect frame, NSView *inView, BOOL isSelected, BOOL isHiglighted))drawingBlock;

///---------------------------------------------------------------------------------------
/// @name Misc Properties
///---------------------------------------------------------------------------------------

@property (nonatomic, assign) IBOutlet id <BFPageControlDelegate>delegate;

@end
