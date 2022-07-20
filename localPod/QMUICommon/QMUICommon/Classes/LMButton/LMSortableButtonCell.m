//
//  LMHeaderButtonCell.m
//  LemonUninstaller
//
//  
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "LMSortableButtonCell.h"

@implementation LMSortableButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    if (!self.isEnabled) {
        if (self.state == NSControlStateValueOn)
            return [super drawTitle:[self attributedAlternateTitle] withFrame:frame inView:controlView];
        else
            return [super drawTitle:[self attributedTitle] withFrame:frame inView:controlView];
    }
    return [super drawTitle:title withFrame:frame inView:controlView];
}

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView {
    if (@available(macOS 10.13, *)) {
        frame.origin.x  = frame.origin.x + 6;
    } else {
        frame.origin.x  = frame.origin.x - 16;
    }
    [super drawImage:image withFrame:frame inView:controlView];
//    NSLog(@"drawImage with frame %@", );
}



@end
