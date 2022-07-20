//
//  QMExtension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <QMCoreFunction/QMDataCenter.h>
#import <QMCoreFunction/NSString+Extension.h>
#import <QMCoreFunction/NSArray+Extension.h>
#import <QMCoreFunction/NSTimer+Extension.h>
#import <QMCoreFunction/NSFileManager+Extension.h>
#import <QMCoreFunction/NSAttributedString+Extension.h>
#import <QMCoreFunction/NSBundle+Extension.h>

#ifdef _APPKITDEFINES_H
#import <QMCoreFunction/NSFont+Extension.h>
#import <QMCoreFunction/NSColor+Extension.h>
#import <QMCoreFunction/NSTextField+Extension.h>
#import <QMCoreFunction/NSButton+Extension.h>
#import <QMCoreFunction/NSView+Extension.h>
#import <QMCoreFunction/NSScreen+Extension.h>
#import <QMCoreFunction/NSEvent+Extension.h>
#import <QMCoreFunction/NSImage+Extension.h>
#import <QMCoreFunction/NSImage+Stretchable.h>
#import <QMCoreFunction/NSDate+Extension.h>
#endif

#ifdef CGIMAGE_H_
#import <QMCoreFunction/CGImage+Extension.h>
#endif

#ifdef QUARTZCORE_H
#import <QMCoreFunction/CALayer+Extension.h>
#endif

#ifdef COREGRAPHICS_H_
#import <QMCoreFunction/CGPath+Extension.h>
#endif

#define kQMDEFAULT_GLOBAL_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
