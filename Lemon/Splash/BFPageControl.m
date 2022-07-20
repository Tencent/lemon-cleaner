//
//  BFPageControl.m
//

//  Copyright (c) 2012 boxedfolder.com. All rights reserved.
//

#import "BFPageControl.h"

@interface BFPageControl ()
-(void)_clickedItem: (id)sender;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation BFPageControlCell

@synthesize useHandCursor = _useHandCursor;
@synthesize drawingBlock = _drawingBlock;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Drawing

-(void)drawWithFrame: (NSRect)frame inView: (NSView *)view
{
    if(!_drawingBlock)
        return;
    
    [NSGraphicsContext saveGraphicsState];
    _drawingBlock(frame, view, [self state] == NSOnState, self.isHighlighted);
    [NSGraphicsContext restoreGraphicsState];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)resetCursorRect: (NSRect)cellFrame inView: (NSView *)controlView
{
    if(!_useHandCursor)
    {
        [super resetCursorRect: cellFrame inView: controlView];
        return;
    }
        
    NSCursor *cursor = [NSCursor pointingHandCursor];
    [controlView addCursorRect: cellFrame cursor: cursor];
    [cursor setOnMouseEntered: YES];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation BFPageControl
{
    void (^_drawingBlock)(NSRect, NSView *, BOOL, BOOL);
    NSMatrix *_matrix;
}

@synthesize currentPage = _currentPage;
@synthesize numberOfPages = _numberOfPages;
@synthesize hidesForSinglePage = _hidesForSinglePage;

@synthesize selectedColor = _selectedColor;
@synthesize highlightColor = _highlightColor;
@synthesize unselectedColor = _unselectedColor;
@synthesize indicatorDiameterSize = _indicatorDiameterSize;
@synthesize indicatorMargin = _indicatorMargin;
@synthesize useHandCursor = _useHandCursor;

@synthesize delegate = _delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Init

-(id)initWithFrame: (NSRect)frameRect
{
    if(self = [super initWithFrame: frameRect])
    {
        _numberOfPages = 0;
        _indicatorDiameterSize = 10.0;
        _indicatorMargin = 5.0;
        _matrix = nil;
        _useHandCursor = NO;
        _drawingBlock = nil;
        _hidesForSinglePage = NO;
    }
    
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Display Related Methods

-(void)updateCurrentPageDisplay
{
    if(_matrix)
        (void)([_matrix removeFromSuperview]), _matrix = nil;
    
    NSUInteger numberOfPages = self.numberOfPages;
    if(_hidesForSinglePage && numberOfPages < 2)
        return;
    
    NSSize size = [self sizeForNumberOfPages: _numberOfPages];
    
    CGRect bounds = self.bounds;
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    
    CGFloat x = floorf((W-size.width)/2);
    CGFloat y = floorf((H-size.height)/2);
    
    NSRect frame = NSMakeRect(x, y, size.width, size.height);
    
    _matrix = [[NSMatrix alloc] initWithFrame: frame mode: NSRadioModeMatrix cellClass: [BFPageControlCell class] numberOfRows: 1 numberOfColumns: _numberOfPages];
    _matrix.drawsBackground = YES;
    _matrix.backgroundColor = [NSColor clearColor];
    _matrix.cellSize = NSMakeSize(_indicatorDiameterSize, _indicatorDiameterSize);
    _matrix.intercellSpacing = NSMakeSize(_indicatorMargin, _indicatorMargin);
    _matrix.allowsEmptySelection = NO;
    [_matrix setTarget: self];
    [_matrix setAction: @selector(_clickedItem:)];
    _matrix.focusRingType = NSFocusRingTypeNone;
    [self addSubview: _matrix];
    
    __weak id wSelf = self;
    void(^block)(NSRect, NSView *, BOOL, BOOL) = ^(NSRect frame, NSView *theView, BOOL isSelected, BOOL isHighlighted){
        BFPageControl *aSelf = wSelf;
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: frame];
        NSColor *color = isSelected ? aSelf.selectedColor : aSelf.unselectedColor;
        
        if(isHighlighted)
            color = aSelf.highlightColor;
            
        [color set];
        [path fill];
    };

    [_matrix.cells enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop){
        BFPageControlCell *cell = (BFPageControlCell *)obj;
        [cell setDrawingBlock: _drawingBlock ?: block];
        [cell setUseHandCursor: _useHandCursor];
    }];
    
    [_matrix selectCellAtRow: 0 column: _currentPage];
    
    [self setNeedsDisplay: YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSSize)sizeForNumberOfPages: (NSInteger)pageCount
{
	return NSMakeSize(pageCount * _indicatorDiameterSize + (pageCount - 1) * _indicatorMargin, _indicatorDiameterSize);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Misc

-(void)_clickedItem: (id)sender
{
    NSUInteger page = [_matrix.cells indexOfObject: _matrix.selectedCell];
    _currentPage = page;
    
    // Call delegate
    if(_delegate && [_delegate respondsToSelector: @selector(pageControl:didSelectPageAtIndex:)])
        [_delegate pageControl: self didSelectPageAtIndex: page];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Accessor

-(void)setCurrentPage:(NSInteger)currentPage
{
    _currentPage = currentPage;
    
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setFrame: (NSRect)frameRect
{
    [super setFrame: frameRect];
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setBounds: (NSRect)aRect
{
    [super setBounds: aRect];
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSColor *)selectedColor
{
    if(!_selectedColor)
        _selectedColor = [NSColor darkGrayColor];
            
    return _selectedColor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setSelectedColor: (NSColor *)selectedColor
{
    _selectedColor = selectedColor;
    
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSColor *)highlightColor
{
    if(!_highlightColor)
        _highlightColor = [NSColor grayColor];
    
    return _highlightColor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setHighlightColor: (NSColor *)highlightColor
{
    _highlightColor = highlightColor;
    
    [self updateCurrentPageDisplay];
}


///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSColor *)unselectedColor
{
    if(!_unselectedColor)
        _unselectedColor = [NSColor lightGrayColor];
    
    return _unselectedColor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setUnselectedColor: (NSColor *)unselectedColor
{
    _unselectedColor = unselectedColor;
    
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setNumberOfPages: (NSInteger)numberOfPages
{
    _numberOfPages = numberOfPages;
    
    [self updateCurrentPageDisplay];
    [self invalidateIntrinsicContentSize];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setUseHandCursor: (BOOL)useHandCursor
{
    _useHandCursor = useHandCursor;
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(void)setDrawingBlock: (void (^)(NSRect frame, NSView *inView, BOOL isSelected, BOOL isHiglighted))drawingBlock;
{
    _drawingBlock = [drawingBlock copy];
    [self updateCurrentPageDisplay];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSSize)intrinsicContentSize
{
    //! size to fit the current setting
    return [self sizeForNumberOfPages: [self numberOfPages]];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

-(NSSize)fittingSize
{
    return [self intrinsicContentSize];
}

@end
