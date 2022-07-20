//
//  NSView+ForwardDraggingDestination.h
//
//  Created by Adam Preble on 1/22/15.
//  Copyright (c) 2015 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (APForwardDraggingDestination)

/**
 Forward NSDraggingDestination methods for this view to the object of your choice.
 */
- (void)ap_forwardDraggingDestinationTo:(id<NSDraggingDestination>)draggingDestination;

@end
