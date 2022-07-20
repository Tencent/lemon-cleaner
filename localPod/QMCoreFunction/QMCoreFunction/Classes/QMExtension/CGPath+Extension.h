//
//  CGPath+Extension.h
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#ifndef CGPATH_EXTENSION_H
#define CGPATH_EXTENSION_H

__BEGIN_DECLS

/// 拷贝path并删除里面的垂直线
CGMutablePathRef CGPathCopyByRemovingVerticalLine(CGPathRef const path);

__END_DECLS

#endif
