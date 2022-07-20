//
//  YRKSpinningProgressIndicator.m
//
//
//

#import "YRKSpinningProgressIndicator.h"


// Some constants to control the animation
#define kAlphaWhenStopped   0.15
#define kFadeMultiplier     0.85


@interface YRKSpinningProgressIndicator ()

- (void)updateFrame:(NSTimer *)timer;
- (void)animateInBackgroundThread;
- (void)actuallyStartAnimation;
- (void)actuallyStopAnimation;
- (void)generateFinColorsStartAtPosition:(int)startPosition;

@end


@implementation YRKSpinningProgressIndicator

@synthesize color = _foreColor;
@synthesize backgroundColor = _backColor;
@synthesize drawsBackground = _drawsBackground;
@synthesize displayedWhenStopped = _displayedWhenStopped;
@synthesize usesThreadedAnimation = _usesThreadedAnimation;
@synthesize indeterminate = _isIndeterminate;
@synthesize doubleValue = _currentValue;
@synthesize maxValue = _maxValue;


#pragma mark Init

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _position = 0;
        _numFins = 12;
        //_finColors = calloc(_numFins, sizeof(NSColor*));
        _finColors = [[NSMutableArray alloc] init];
        
        _isAnimating = NO;
        _isFadingOut = NO;
        
        _foreColor = [NSColor blackColor];
        _backColor = [NSColor clearColor];
        _drawsBackground = NO;
        
		_displayedWhenStopped = YES;
        _usesThreadedAnimation = NO;
        
        _isIndeterminate = YES;
        _currentValue = 0.0;
        _maxValue = 100.0;
    }
    return self;
}

- (void) dealloc
{
    if (_isAnimating) [self stopAnimation:self];
}

# pragma mark NSView overrides

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];

    if ([self window] == nil) {
        // No window?  View hierarchy may be going away.  Dispose timer to clear circular retain of timer to self to timer.
        [self actuallyStopAnimation];
    }
    else if (!self.isHidden) {
        if (_startAnimating)
            [self actuallyStartAnimation];
    }
}

- (void)drawRect:(NSRect)rect
{
    if ([_finColors count] < _numFins)
        return;
    // Determine size based on current bounds
    NSSize size = [self bounds].size;
    CGFloat theMaxSize;
    if(size.width >= size.height)
        theMaxSize = size.height;
    else
        theMaxSize = size.width;

    // fill the background, if set
    if(_drawsBackground) {
        [_backColor set];
        [NSBezierPath fillRect:[self bounds]];
    }

    CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [NSGraphicsContext saveGraphicsState];

    // Move the CTM so 0,0 is at the center of our bounds
    CGContextTranslateCTM(currentContext,[self bounds].size.width/2,[self bounds].size.height/2);

    if (_isIndeterminate) {
        NSBezierPath *path = [[NSBezierPath alloc] init];
        CGFloat lineWidth = 0.0859375 * theMaxSize; // should be 2.75 for 32x32
        CGFloat lineStart = 0.234375 * theMaxSize; // should be 7.5 for 32x32
        CGFloat lineEnd = 0.421875 * theMaxSize;  // should be 13.5 for 32x32
        [path setLineWidth:lineWidth];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path moveToPoint:NSMakePoint(0,lineStart)];
        [path lineToPoint:NSMakePoint(0,lineEnd)];

        for (int i=0; i<_numFins; i++) {
            if(_isAnimating) {
                [(NSColor *)[_finColors objectAtIndex:i] set];
            }
            else {
                [[_foreColor colorWithAlphaComponent:kAlphaWhenStopped] set];
            }

            [path stroke];

            // we draw all the fins by rotating the CTM, then just redraw the same segment again
            CGContextRotateCTM(currentContext, 6.282185/_numFins);
        }
    }
    else {
        CGFloat lineWidth = 1 + (0.01 * theMaxSize);
        CGFloat circleRadius = (theMaxSize - lineWidth) / 2.1;
        NSPoint circleCenter = NSMakePoint(0, 0);
        [_foreColor set];
        NSBezierPath *path = [[NSBezierPath alloc] init];
        [path setLineWidth:lineWidth];
        [path appendBezierPathWithOvalInRect:NSMakeRect(-circleRadius, -circleRadius, circleRadius*2, circleRadius*2)];
        [path stroke];
        path = [[NSBezierPath alloc] init];
        [path appendBezierPathWithArcWithCenter:circleCenter radius:circleRadius startAngle:90 endAngle:90-(360*(_currentValue/_maxValue)) clockwise:YES];
        [path lineToPoint:circleCenter] ;
        [path fill];
    }

    [NSGraphicsContext restoreGraphicsState];
}


#pragma mark NSProgressIndicator API

- (void)startAnimation:(id)sender
{
    if (!_isIndeterminate) return;
    if (_isAnimating && !_isFadingOut) return;
	_startAnimating = YES;
    [self actuallyStartAnimation];
}

- (void)stopAnimation:(id)sender
{
    _startAnimating = NO;
    // animate to stopped state
    _isFadingOut = YES;
}

/// Only the spinning style is implemented
- (void)setStyle:(NSProgressIndicatorStyle)style
{
    if (NSProgressIndicatorSpinningStyle != style) {
        NSAssert(NO, @"Non-spinning styles not available.");
    }
}


# pragma mark Custom Accessors

- (void)setColor:(NSColor *)value
{
    if (_foreColor != value) {
        _foreColor = value;
        
        // generate all the fin colors, with the alpha components
        // they already have
        [_finColors removeAllObjects];
        for (int i=0; i<_numFins; i++) {
            [_finColors addObject:[_foreColor colorWithAlphaComponent:0]];
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)value
{
    if (_backColor != value) {
        _backColor = value;
        [self setNeedsDisplay:YES];
    }
}

- (void)setDrawsBackground:(BOOL)value
{
    if (_drawsBackground != value) {
        _drawsBackground = value;
    }
    [self setNeedsDisplay:YES];
}

- (void)setIndeterminate:(BOOL)isIndeterminate
{
    _isIndeterminate = isIndeterminate;
    if (!_isIndeterminate && _isAnimating) [self stopAnimation:self];
    [self setNeedsDisplay:YES];
}

- (void)setDoubleValue:(double)doubleValue
{
    // Automatically put it into determinate mode if it's not already.
    if (_isIndeterminate) {
        [self setIndeterminate:NO];
    }
    _currentValue = doubleValue;
    [self setNeedsDisplay:YES];
}

- (void)setMaxValue:(double)maxValue
{
    _maxValue = maxValue;
    [self setNeedsDisplay:YES];
}

- (void)setUsesThreadedAnimation:(BOOL)useThreaded
{
    if (_usesThreadedAnimation != useThreaded) {
        _usesThreadedAnimation = useThreaded;
        
        if (_isAnimating) {
            // restart the timer to use the new mode
            [self stopAnimation:self];
            [self startAnimation:self];
        }
    }
}

- (void)setDisplayedWhenStopped:(BOOL)displayedWhenStopped
{
	_displayedWhenStopped = displayedWhenStopped;
	
	// Show/hide ourself if necessary
	if (!_isAnimating) {
		if (_displayedWhenStopped && [self isHidden]) {
			[self setHidden:NO];
		}
		else if (!_displayedWhenStopped && ![self isHidden]) {
			[self setHidden:YES];
		}
	}
}


#pragma mark Private

- (void)updateFrame:(NSTimer *)timer
{
    if(_position > 0) {
        _position--;
    }
    else {
        _position = _numFins - 1;
    }
    
    if ([_finColors count] < _numFins)
        return;
    
    // update the colors
    CGFloat minAlpha = _displayedWhenStopped ? kAlphaWhenStopped : 0.01;
    for (int i=0; i<_numFins; i++) {
        // want each fin to fade exponentially over _numFins frames of animation
        CGFloat newAlpha = [_finColors[i] alphaComponent] * kFadeMultiplier;
        if (newAlpha < minAlpha)
            newAlpha = minAlpha;
        _finColors[i] = [_foreColor colorWithAlphaComponent:newAlpha];
    }
    
    if (_isFadingOut) {
        // check if the fadeout is done
        BOOL done = YES;
        for (int i=0; i<_numFins; i++) {
            if (fabs([_finColors[i] alphaComponent] - minAlpha) > 0.01) {
                done = NO;
                break;
            }
        }
        if (done) {
            [self actuallyStopAnimation];
        }
    }
    else {
        // "light up" the next fin (with full alpha)
        _finColors[_position] = _foreColor;
    }
    
    if (_usesThreadedAnimation) {
        // draw now instead of waiting for setNeedsDisplay (that's the whole reason
        // we're animating from background thread)
        [self display];
    }
    else {
        [self setNeedsDisplay:YES];
    }
}

- (void)actuallyStartAnimation
{
    // Just to be safe kill any existing timer.
    [self actuallyStopAnimation];
    
    _isAnimating = YES;
    _isFadingOut = NO;
    
    // always start from the top
    _position = 1;
    
	if (!_displayedWhenStopped)
		[self setHidden:NO];

    if ([self window]) {
        // Why animate if not visible?  viewDidMoveToWindow will re-call this method when needed.
        if (_usesThreadedAnimation) {
            _animationThread = [[NSThread alloc] initWithTarget:self selector:@selector(animateInBackgroundThread) object:nil];
            [_animationThread start];
        }
        else {
            _animationTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)0.04
                                                       target:self
                                                     selector:@selector(updateFrame:)
                                                     userInfo:nil
                                                      repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSEventTrackingRunLoopMode];
        }
    }
}

- (void)actuallyStopAnimation
{
    _isAnimating = NO;
    _isFadingOut = NO;
    
    if (!_displayedWhenStopped)
        [self setHidden:YES];
    
    if (_animationThread) {
        // we were using threaded animation
		[_animationThread cancel];
		if (![_animationThread isFinished]) {
			[[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
		}
        _animationThread = nil;
	}
    else if (_animationTimer) {
        // we were using timer-based animation
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
    [self setNeedsDisplay:YES];
}

- (void)generateFinColorsStartAtPosition:(int)startPosition
{
    for (int i=0; i<_numFins; i++) {
        NSColor *oldColor = _finColors[i];
        CGFloat alpha = [oldColor alphaComponent];
        _finColors[i] = [_foreColor colorWithAlphaComponent:alpha];
    }
}

- (void)animateInBackgroundThread
{
	// Set up the animation speed to subtly change with size > 32.
	// int animationDelay = 38000 + (2000 * ([self bounds].size.height / 32));
    
    // Set the rev per minute here
    int omega = 150; // RPM
    int animationDelay = 60*1000000/omega/_numFins;
	int poolFlushCounter = 0;
    
	do {
		[self updateFrame:nil];
		usleep(animationDelay);
		poolFlushCounter++;
		if (poolFlushCounter > 256) {
			poolFlushCounter = 0;
		}
	} while (![[NSThread currentThread] isCancelled]);
}

@end
