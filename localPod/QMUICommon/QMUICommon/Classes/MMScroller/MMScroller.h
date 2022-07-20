//
//  MMScroller.h
//  MiniMail
//
//  Created by DINH Viêt Hoà on 21/02/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MMScroller : NSScroller {
	int _animationStep;
	float _oldValue;
	BOOL _scheduled;
	BOOL _disableFade;
    BOOL _shouldClearBackground;
}

@property (nonatomic, assign) BOOL shouldClearBackground;

- (void) showScroller;

@end
