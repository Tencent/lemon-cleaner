//
//  MMDrawingUtils.h
//  MiniMail
//
//  Created by DINH Viêt Hoà on 21/02/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

void MMFillRoundedRect(NSRect rect, CGFloat x, CGFloat y);
void MMStrokeRoundedRect(NSRect rect, CGFloat x, CGFloat y);

void MMCGContextFillRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight);
void MMCGContextStrokeRoundRect(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight);
