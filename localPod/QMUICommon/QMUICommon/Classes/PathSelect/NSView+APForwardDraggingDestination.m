//
//  NSView+ForwardDraggingDestination.m
//
//  Created by Adam Preble on 1/22/15.
//  Copyright (c) 2015 Adam Preble. All rights reserved.
//

#import "NSView+APForwardDraggingDestination.h"
#import <objc/runtime.h>

static void *DraggingDelegateKey = &DraggingDelegateKey;


@implementation NSView (ForwardDraggingDestination)

- (void)ap_forwardDraggingDestinationTo:(id<NSDraggingDestination>)draggingDestination {
    
    // Store the dragging destination to forward to:
    objc_setAssociatedObject(self, DraggingDelegateKey, draggingDestination, OBJC_ASSOCIATION_ASSIGN);
    
    [self.class ap_swizzleToForwardDraggingDestinationIfNeeded];
}

+ (void)ap_swizzleToForwardDraggingDestinationIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ // Only swizzle it once!
        const Class class = self.class;
        
        // Walk the methods of NSDraggingDestination:
        unsigned int count = 0;
        struct objc_method_description *protocolMethods = protocol_copyMethodDescriptionList(@protocol(NSDraggingDestination), NO, YES, &count);
        for (int i = 0; i < count; i++) {
            // For each protocol method, swizzle it with the apFwdDragDest_ analog,
            // each of which will attempt to call the delegate first.
            
            SEL originalSelector = protocolMethods[i].name;
            SEL swizzledSelector = NSSelectorFromString([@"apFwdDragDest_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            
            // originalMethod will be nil in cases where NSView doesn't implement that method.
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            
            BOOL didAddMethod = class_addMethod(class,
                                                originalSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(class,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
        if (protocolMethods != nil) {
            free(protocolMethods);
        }
    });
}

#define DRAGGING_DELEGATE id<NSDraggingDestination> delegate = objc_getAssociatedObject(self, DraggingDelegateKey)

- (NSDragOperation)apFwdDragDest_draggingEntered:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        return [delegate draggingEntered:sender];
    }
    else {
        return [self apFwdDragDest_draggingEntered:sender];
    }
}

- (NSDragOperation)apFwdDragDest_draggingUpdated:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        return [delegate draggingUpdated:sender];
    }
    else {
        return [self apFwdDragDest_draggingUpdated:sender];
    }
}

- (void)apFwdDragDest_draggingExited:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate draggingExited:sender];
    }
    else {
        [self apFwdDragDest_draggingExited:sender];
    }
}

- (BOOL)apFwdDragDest_prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        return [delegate prepareForDragOperation:sender];
    }
    else {
        return [self apFwdDragDest_prepareForDragOperation:sender];
    }
}

- (BOOL)apFwdDragDest_performDragOperation:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        return [delegate performDragOperation:sender];
    }
    else {
        return [self apFwdDragDest_performDragOperation:sender];
    }
}

- (void)apFwdDragDest_concludeDragOperation:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate concludeDragOperation:sender];
    }
    else {
        [self apFwdDragDest_concludeDragOperation:sender];
    }
}

// NSView does not implement the following methods.
// Thus they do not return [self apFwdDragDest_*].

- (void)apFwdDragDest_draggingEnded:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate draggingEnded:sender];
    }
}

- (BOOL)apFwdDragDest_wantsPeriodicDraggingUpdates
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        return [delegate wantsPeriodicDraggingUpdates];
    }
    return NO;
}

- (void)apFwdDragDest_updateDraggingItemsForDrag:(id<NSDraggingInfo>)sender
{
    DRAGGING_DELEGATE;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate updateDraggingItemsForDrag:sender];
    }
}

#undef DRAGGING_DELEGATE

@end
