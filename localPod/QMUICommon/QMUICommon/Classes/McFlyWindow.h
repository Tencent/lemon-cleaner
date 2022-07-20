//
//  McFlyWindow.h
//  McUICommon
//
//  Created by developer on 8/31/12.
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    McFlyEffectFadeOut,
    McFlyEffectFadeIn
};
typedef NSInteger McFlyEffect;

@interface McFlyWindow : NSWindow
{
    NSImageView *imgView;    
}
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, assign) NSTimeInterval flyDuration;
@property (nonatomic, assign) McFlyEffect flyEffect;

- (void)flyWithFrom:(NSPoint)fromPoint to:(NSPoint)toPoint completionHandler:(void(^)(void))completionHandler;

@end
