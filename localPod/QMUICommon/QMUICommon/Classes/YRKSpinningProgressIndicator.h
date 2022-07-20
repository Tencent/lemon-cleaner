//
//  YRKSpinningProgressIndicator.h
//
//
//


@interface YRKSpinningProgressIndicator : NSView {
    int _position;
    int _numFins;
    NSMutableArray *_finColors;
    
    BOOL _isAnimating;
    BOOL _isFadingOut;
    BOOL _startAnimating;
    NSTimer *_animationTimer;
	NSThread *_animationThread;
    
    NSColor *_foreColor;
    NSColor *_backColor;
    BOOL _drawsBackground;
    
    BOOL _displayedWhenStopped;
    BOOL _usesThreadedAnimation;
	
    // For determinate mode
    BOOL _isIndeterminate;
    double _currentValue;
    double _maxValue;
}

@property (nonatomic, retain) NSColor *color;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign, getter=isDisplayedWhenStopped) BOOL displayedWhenStopped;
@property (nonatomic, assign) BOOL usesThreadedAnimation;

@property (nonatomic, assign, getter=isIndeterminate) BOOL indeterminate;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) double maxValue;

- (void)stopAnimation:(id)sender;
- (void)startAnimation:(id)sender;

@end
