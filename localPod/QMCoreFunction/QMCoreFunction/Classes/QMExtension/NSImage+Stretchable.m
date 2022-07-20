//
//  NSImage+Stretchable.m
//  Test
//
//  
//  Copyright (c) 2013 http://www.tanhao.me. All rights reserved.
//

#import "NSImage+Stretchable.h"

@implementation NSImage (Stretchable)

- (NSImage *)stretchableImageWithSize:(NSSize)size edgeInsets:(NSEdgeInsets)insets
{
    void (^makeAreas)(NSRect, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *, NSRect *) = ^(NSRect srcRect, NSRect *tl, NSRect *tc, NSRect *tr, NSRect *ml, NSRect *mc, NSRect *mr, NSRect *bl, NSRect *bc, NSRect *br) {
        CGFloat w = NSWidth(srcRect);
        CGFloat h = NSHeight(srcRect);
        CGFloat cw = w - insets.left - insets.right;
        CGFloat ch = h - insets.top - insets.bottom;
        
        CGFloat x0 = NSMinX(srcRect);
        CGFloat x1 = x0 + insets.left;
        CGFloat x2 = NSMaxX(srcRect) - insets.right;
        
        CGFloat y0 = NSMinY(srcRect);
        CGFloat y1 = y0 + insets.bottom;
        CGFloat y2 = NSMaxY(srcRect) - insets.top;
        
        *tl = NSMakeRect(x0, y2, insets.left, insets.top);
        *tc = NSMakeRect(x1, y2, cw, insets.top);
        *tr = NSMakeRect(x2, y2, insets.right, insets.top);
        
        *ml = NSMakeRect(x0, y1, insets.left, ch);
        *mc = NSMakeRect(x1, y1, cw, ch);
        *mr = NSMakeRect(x2, y1, insets.right, ch);
        
        *bl = NSMakeRect(x0, y0, insets.left, insets.bottom);
        *bc = NSMakeRect(x1, y0, cw, insets.bottom);
        *br = NSMakeRect(x2, y0, insets.right, insets.bottom);
    };
    NSImage *resultImage = [[NSImage alloc] init];
    
    for (NSImageRep *imageRep in self.representations) {
        float scale = imageRep.pixelsWide / self.size.width;
        NSRect rect = NSMakeRect(0, 0, size.width * scale, size.height * scale);
        // Source rects
        NSRect srcRect = (NSRect){NSZeroPoint, imageRep.size};
        NSRect srcTopL, srcTopC, srcTopR, srcMidL, srcMidC, srcMidR, srcBotL, srcBotC, srcBotR;
        makeAreas(srcRect, &srcTopL, &srcTopC, &srcTopR, &srcMidL, &srcMidC, &srcMidR, &srcBotL, &srcBotC, &srcBotR);
        
        // Destinations rects
        NSRect dstTopL, dstTopC, dstTopR, dstMidL, dstMidC, dstMidR, dstBotL, dstBotC, dstBotR;
        makeAreas(rect, &dstTopL, &dstTopC, &dstTopR, &dstMidL, &dstMidC, &dstMidR, &dstBotL, &dstBotC, &dstBotR);
        
        NSRect srcRects[] = {srcTopL, srcTopC, srcTopR, srcMidL, srcMidC, srcMidR, srcBotL, srcBotC, srcBotR};
        NSRect dstRects[] = {dstTopL, dstTopC, dstTopR, dstMidL, dstMidC, dstMidR, dstBotL, dstBotC, dstBotR};
        NSMutableArray *partImgs = [NSMutableArray arrayWithCapacity:9];
        for (int i=0;i<9;i++)
        {
            NSRect aSrcRect = srcRects[i];
            NSRect aDstRect = dstRects[i];
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaPremultipliedLast;
            CGContextRef ctx = CGBitmapContextCreate(NULL, aDstRect.size.width, aDstRect.size.height, 8, aDstRect.size.width * 4, colorSpace, bitmapInfo);
            NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
            [NSGraphicsContext setCurrentContext:graphicsContext];
//            NSImage *partImg = [[NSImage alloc] initWithSize:aSrcRect.size];
//            [partImg lockFocus];
            [imageRep drawInRect:(NSRect){NSZeroPoint, aDstRect.size} fromRect:aSrcRect operation:NSCompositeCopy fraction:1 respectFlipped:NO hints:nil];
//            [self drawAtPoint:NSZeroPoint fromRect:aSrcRect operation:NSCompositeCopy fraction:1.0];
//            [partImg setSize:aDstRect.size];
//            [partImg unlockFocus];
            CGImageRef outImage = CGBitmapContextCreateImage(ctx);
            NSImage *partImg = [[NSImage alloc] initWithCGImage:outImage size:aDstRect.size];
            [partImgs addObject:partImg];
            CGImageRelease(outImage);
            CGContextRelease(ctx);
            CGColorSpaceRelease(colorSpace);
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaPremultipliedLast;
        CGContextRef ctx = CGBitmapContextCreate(NULL, rect.size.width, rect.size.height, 8, rect.size.width * 4, colorSpace, bitmapInfo);
        NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
        [NSGraphicsContext setCurrentContext:graphicsContext];

        // Draw
//        NSRect drawRect = NSMakeRect(0, 0, rect.size.width, rect.size.height);
//        NSImage *resultImg = [[NSImage alloc] initWithSize:drawRect.size];
//        [resultImg lockFocus];
        NSDrawNinePartImage(rect,
                            [partImgs objectAtIndex:0],
                            [partImgs objectAtIndex:1],
                            [partImgs objectAtIndex:2],
                            [partImgs objectAtIndex:3],
                            [partImgs objectAtIndex:4],
                            [partImgs objectAtIndex:5],
                            [partImgs objectAtIndex:6],
                            [partImgs objectAtIndex:7],
                            [partImgs objectAtIndex:8],
                            NSCompositeSourceOver, 1, NO);
//        [resultImg unlockFocus];
        CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
        NSImage *resultImg = [[NSImage alloc] initWithCGImage:cgImage size:rect.size];
        CGImageRelease(cgImage);
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorSpace);
        NSImageRep *rep = resultImg.representations[0];
        rep.size = size;
        [resultImage addRepresentation:rep];
    }
    return resultImage;
}

- (NSImage *)stretchableImageWithLeftCapWidth:(float)leftWidth middleWidth:(float)middleWidth rightCapWidth:(float)rightWidth
{
    // Calculate the new images dimensions
    float imageWidth = leftWidth + middleWidth + rightWidth;
    float imageHeight = self.size.height;
    
    // Generate the left image
    NSRect rectLeft = NSMakeRect(0, 0, leftWidth, imageHeight);
    NSImage *imageLeft = [[NSImage alloc] initWithSize:rectLeft.size];
    if (imageLeft.size.width > 0) {
        [imageLeft lockFocus];
        [self drawInRect:rectLeft fromRect:rectLeft operation:NSCompositeCopy fraction:1.0];
        [imageLeft unlockFocus];
    }
    
    // Generate the middle image
    NSRect rectMiddle = NSMakeRect(0, 0, middleWidth, imageHeight);
    NSImage *imageMiddle = [[NSImage alloc] initWithSize:rectMiddle.size];
    if (imageMiddle.size.width > 0) {
        [imageMiddle lockFocus];
        [self drawInRect:rectMiddle fromRect:NSMakeRect(leftWidth, 0, self.size.width-rightWidth-leftWidth,imageHeight) operation:NSCompositeCopy fraction:1.0];
        [imageMiddle unlockFocus];
    }
    
    // Generate the right image
    NSRect rectRight = NSMakeRect(0, 0, rightWidth, imageHeight);
    NSImage *imageRight = [[NSImage alloc] initWithSize:rectRight.size];
    if (imageRight.size.width > 0) {
        [imageRight lockFocus];
        [self drawInRect:rectRight fromRect:NSMakeRect(self.size.width - rightWidth, 0, rightWidth, imageHeight) operation:NSCompositeCopy fraction:1.0];
        [imageRight unlockFocus];
    }
    
    // Combine the images
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(imageWidth,  imageHeight)];
    if (newImage.size.width > 0) {
        [newImage lockFocus];
        NSDrawThreePartImage(NSMakeRect(0, 0, imageWidth, imageHeight), imageLeft, imageMiddle, imageRight, NO, NSCompositeSourceOver, 1, NO);
        [newImage unlockFocus];
    }
    
    // Release the images and return the new image
    return newImage;
}

@end
