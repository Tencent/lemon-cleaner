//
//  Header.h
//  QMUICommon
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

typedef NS_ENUM(NSUInteger, QMBubbleTitleMode) {
    QMBubbleTitleModeArrow,
    QMBubbleTitleModeTitleBar
};
typedef NS_OPTIONS(NSUInteger, QMArrowDirection) {
    QMArrowTop = 1<<0,
    QMArrowBottom = 1<<1,
    QMArrowLeft = 1<<2,
    QMArrowRight = 1<<3,
    
    QMArrowSideTop = 1<<4,
    QMArrowSideLeft = 1<<5,
    QMArrowSideBottom = 1<<6,
    QMArrowSideRight = 1<<7,
    
    QMArrowCornerTopLeft = QMArrowTop | QMArrowLeft,
    QMArrowCornerTopRight = QMArrowTop | QMArrowRight,
    QMArrowCornerBottomLeft = QMArrowBottom | QMArrowLeft,
    QMArrowCornerBottomRight = QMArrowBottom | QMArrowRight,
    /// TopLeft表示在上边的左侧
    QMArrowTopLeft = QMArrowCornerTopLeft | QMArrowSideTop,
    QMArrowTopRight = QMArrowCornerTopRight | QMArrowSideTop,
    QMArrowBottomLeft = QMArrowCornerBottomLeft | QMArrowSideBottom,
    QMArrowBottomRight = QMArrowCornerBottomRight | QMArrowSideBottom,
    
    QMArrowLeftTop = QMArrowCornerTopLeft | QMArrowSideLeft,
    QMArrowLeftBottom = QMArrowCornerBottomLeft | QMArrowSideLeft,
    QMArrowRightTop = QMArrowCornerTopRight | QMArrowSideRight,
    QMArrowRightBottom = QMArrowCornerBottomRight | QMArrowSideRight
};
