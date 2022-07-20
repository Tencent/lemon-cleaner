//
//  LMPhotoCollectionViewLayout.h
//  LemonPhotoCleaner
//
//  
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ITEM_WIDTH           80.0     // width  of the SlideCarrier image (which includes shadow margins) in points, and thus the width  that we give to a Slide's root view
#define ITEM_HEIGHT          80.0     // height of the SlideCarrier image (which includes shadow margins) in points, and thus the height that we give to a Slide's root view

#define SLIDE_SHADOW_MARGIN    10.0     // margin on each side between the actual slide shape edge and the edge of the SlideCarrier image
#define SLIDE_CORNER_RADIUS     8.0     // corner radius of the slide shape in points
#define SLIDE_BORDER_WIDTH      4.0     // thickness of border when shown, in points

#define HEADER_HEIGHT       20.0


#define X_PADDING        10.0
#define Y_PADDING        10.0

API_AVAILABLE(macos(10.11))
@interface LMPhotoCollectionViewLayout : NSCollectionViewFlowLayout

@end
