//
//  JLNDragEffectManager.m
//  Drag Effect
//

//  Copyright 2009 Joshua Nozzi. All rights reserved.
//
//	 This software is supplied to you by Joshua Nozzi in consideration 
//	 of your agreement to the following terms, and your use, installation, 
//	 modification or redistribution of this software constitutes 
//	 acceptance of these terms. If you do not agree with these terms, 
//	 please do not use, install, modify or redistribute this software.
//	 
//	 In consideration of your agreement to abide by the following terms, 
//	 and subject to these terms, Joshua Nozzi grants you a personal, 
//	 non-exclusive license, to use, reproduce, modify and redistribute 
//	 the software, with or without modifications, in source and/or binary 
//	 forms; provided that if you redistribute the software in its entirety 
//	 and without modifications, you must retain this notice and the 
//	 following text and disclaimers in all such redistributions of the 
//	 software, and that in all cases attribution of Joshua Nozzi as the 
//	 original author of the source code shall be included in all such 
//	 resulting software products or distributions. Neither the name, 
//	 trademarks, service marks or logos of Joshua Nozzi may be used to 
//	 endorse or promote products derived from the software without specific 
//	 prior written permission from Joshua Nozzi. Except as expressly stated 
//	 in this notice, no other rights or licenses, express or implied, are 
//	 granted by Joshua Nozzi herein, including but not limited to any patent 
//	 rights that may be infringed by your derivative works or by other works 
//	 in which the software may be incorporated.
//	 
//	 THIS SOFTWARE IS PROVIDED BY JOSHUA NOZZI ON AN "AS IS" BASIS. JOSHUA 
//	 NOZZI MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT 
//	 LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
//	 AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE SOFTWARE OR ITS USE 
//	 AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//	 
//	 IN NO EVENT SHALL JOSHUA NOZZI BE LIABLE FOR ANY SPECIAL, INDIRECT, 
//	 INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
//	 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
//	 PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE 
//	 USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE SOFTWARE, 
//	 HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING 
//	 NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF JOSHUA NOZZI HAS 
//	 BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//	


#import "JLNDragEffectManager.h"
#import <QuartzCore/QuartzCore.h>


@implementation JLNDragEffectManager
@synthesize slideBack=_slideBack;

#pragma mark Factory

+ (id)sharedDragEffectManager
{
//    static id sharedDragEffectManager = nil;
//    if (sharedDragEffectManager == nil)
//        sharedDragEffectManager = [[self alloc] initWithWindow:nil];
//    return sharedDragEffectManager;
    
    static dispatch_once_t onceToken = 0;
    __strong static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initWithWindow:nil];
    });
    
    return instance;
}


#pragma mark Constructors / Destructors

- (id)initWithWindow:(NSWindow *)window
{
	// Create the window first (ignore any we're sent, create our own)
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 64, 64) 
                                         styleMask:NSBorderlessWindowMask 
                                           backing:NSBackingStoreBuffered 
                                             defer:NO];
	[window setReleasedWhenClosed:NO];
	[window setMovableByWindowBackground:NO];
	[window setBackgroundColor:[NSColor clearColor]];
	[window setLevel:(NSFloatingWindowLevel + 3000)];
	[window setOpaque:NO];
	[window setHasShadow:NO];
	[[window contentView] setWantsLayer:YES];
	
	// Now back to our regularly-scheduled initialization
	self = [super initWithWindow:window];
	if (self)
	{
		// Initialize our ivars (yes I know they really 
		// don't need to be, but I have OCD, so shut up)
		_slideBack = NO;
		_sourceRect = NSZeroRect;
		_offset = NSZeroSize;
		_startPoint = NSZeroPoint;
		_insideImageSize = NSZeroSize;
		_outsideImageSize = NSZeroSize;
		
		// Create and configure our NSImageViews (we retain them 
		// since we'll be swapping them in and out of the window)
		_imageViewA = [[NSImageView alloc] initWithFrame:[[window contentView] bounds]];
		[_imageViewA setImageScaling:NSScaleToFit];
		_imageViewB = [[NSImageView alloc] initWithFrame:[[window contentView] bounds]];
		[_imageViewB setImageScaling:NSScaleToFit];
		
		// Modify the window's fade animation to set self as delegate
		// (this is done so we can order the window out and clean up)
		CABasicAnimation * alphaValueAnimation = [CABasicAnimation animation];
		[alphaValueAnimation setDelegate:self];
		[window setAnimations:[NSMutableDictionary dictionaryWithObject:alphaValueAnimation forKey:@"alphaValue"]];
	}
	return self;
}



#pragma mark Drag Configuration & Update

- (void)startDragShowFromSourceScreenRect:(NSRect)aScreenRect 
						  startingAtPoint:(NSPoint)aStartPoint 
								   offset:(NSSize)anOffset 
							  insideImage:(NSImage *)insideImage 
							 outsideImage:(NSImage *)outsideImage 
								slideBack:(BOOL)slideBackFlag
{
	// Record the state
	_sourceRect = aScreenRect;
	_startPoint = aStartPoint;
	_offset = anOffset;
	_slideBack = slideBackFlag;
	_insideImageSize = [insideImage size];
	_outsideImageSize = [outsideImage size];
	
	// Set the window's size to the larger of the two images
	NSSize largestDimensions = NSZeroSize;
	largestDimensions.width = MAX(_insideImageSize.width, _outsideImageSize.width);
	largestDimensions.height = MAX(_insideImageSize.height, _outsideImageSize.height);
	NSRect frame = [[self window] frame];
	frame.size = largestDimensions;
	[[self window] setFrame:frame display:NO];
	
	// Center imageViewA's frame within the content view bounds & set its size
	NSRect frameA = NSZeroRect;
	frameA.size = _insideImageSize;
	frameA.origin = NSMakePoint(NSWidth([[[self window] contentView] bounds]) / 2 - NSWidth(frameA) / 2, NSHeight([[[self window] contentView] bounds]) / 2 - NSHeight(frameA) / 2);
	[_imageViewA setFrame:NSIntegralRect(frameA)];
	
	// Set imageViewB's size
	NSRect frameB = NSZeroRect;
	frameB.size = _outsideImageSize;
	[_imageViewB setFrame:NSIntegralRect(frameB)];
	
	// Make sure view b isn't in the window and view b is
	if ([_imageViewB superview])
		[_imageViewB removeFromSuperview];
	if ([_imageViewA superview] != [[self window] contentView])
		[[[self window] contentView] addSubview:_imageViewA];
	
	// Set the image views' images
	[_imageViewA setImage:insideImage];
	[_imageViewB setImage:outsideImage];
	
	// Position the window's center over the start point 
	// (no animation, just go straight there)
	[self _centerWindowOverPoint:_startPoint 
					  withOffset:_offset 
						 animate:NO];
	
	// Set the window's alpha to zero and order it in 
	// (start position, ready to fade)
	[[self window] setAlphaValue:0.0];
	[[self window] orderFront:self];
	
	// Fade in quickly
	[[NSAnimationContext currentContext] setDuration:0.125];
	[[[self window] animator] setAlphaValue:1.0];
}

- (void)updatePosition
{
	// We need the mouse's current location in screen coordinates
	NSPoint mouseLocation = [NSEvent mouseLocation];
	
	// Position the window's center over the current location (no animation, just go straight there)
	[self _centerWindowOverPoint:mouseLocation 
					  withOffset:_offset 
						 animate:NO];
	
	// Which is the source and which is the target?
	NSImageView * target = (NSPointInRect(mouseLocation, _sourceRect)) ? _imageViewA : _imageViewB;
	NSImageView * source = (target == _imageViewA) ? _imageViewB : _imageViewA;
	
	// Figure out the target frame (centered, same size as image)
	NSRect imageViewTargetFrame = NSZeroRect;
	imageViewTargetFrame.size = (target == _imageViewA) ? _insideImageSize : _outsideImageSize;
	imageViewTargetFrame.origin = NSMakePoint(NSWidth([[[self window] contentView] bounds]) / 2 - NSWidth(imageViewTargetFrame) / 2, 
											  NSHeight([[[self window] contentView] bounds]) / 2 - NSHeight(imageViewTargetFrame) / 2);
	
	// If the target view is not already visible, swap it in (and animate)
	if ([target superview] != [[self window] contentView])
	{
		// Set the target view's frame to that of the existing view
		[target setFrame:[source frame]];
		
		// Animate the swap and size change (this gives the effect of
		// one object morphing into another a la Interface Builder)
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		[[[[self window] contentView] animator] replaceSubview:source with:target];
		[[target animator] setFrame:NSIntegralRect(imageViewTargetFrame)];
		[NSAnimationContext endGrouping];
	}
}

- (void)endDragShowWithResult:(NSDragOperation)dragOperation
{
	// If the drag operation is none and slide-back is requested, start slide-back effect
	if (dragOperation == NSDragOperationNone && _slideBack)
		[self _centerWindowOverPoint:_startPoint 
						  withOffset:_offset 
							 animate:YES];
	
	// Always start fade-out effect
	[[[self window] animator] setAlphaValue:0.0];
}


#pragma mark Internal Window Management

- (void)_centerWindowOverPoint:(NSPoint)point 
					withOffset:(NSSize)offset 
					   animate:(BOOL)animate
{
	// Determine the frame
	NSRect frame = [[self window] frame];
	frame.origin = NSMakePoint(point.x - (NSWidth(frame) / 2) + offset.width,
							   point.y - (NSHeight(frame) / 2) + offset.height);
	
	// Animate and fade out if requested, else just set the frame.
	if (animate)
	{
		[[NSAnimationContext currentContext] setDuration:0.15];
		[[[self window] animator] setFrame:frame display:YES];
	} else {
		[[self window] setFrame:frame display:YES];
	}
}

- (void)_orderOutAndCleanUp
{
	// Order our window out
	[[self window] orderOut:self];
	
	// Clean up the state
	_slideBack = NO;
	_sourceRect = NSZeroRect;
	_offset = NSZeroSize;
	_startPoint = NSZeroPoint;
	_insideImageSize = NSZeroSize;
	_outsideImageSize = NSZeroSize;
	
	// Drop the images
	[_imageViewA setImage:nil];
	[_imageViewB setImage:nil];
}


#pragma mark Animation Delegation

- (void)animationDidStop:(CAAnimation *)theAnimation 
				finished:(BOOL)flag
{
	// We only care about the window's fade-out animation
	// We want to clean up if successfully faded out
	if (flag && [[self window] alphaValue] == 0.0)
		[self _orderOutAndCleanUp];
}


@end

