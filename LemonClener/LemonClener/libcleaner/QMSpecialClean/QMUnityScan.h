//
//  QMUnityRepo.h
//  LemonClener
//
//  Created by watermoon on 2024/8/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMActionItem.h"

@interface QMUnityScan : NSObject

@property (weak) id<QMScanDelegate> delegate;

-(void)scanArtifacts:(QMActionItem *)actionItem;

-(void)scanBuilds:(QMActionItem *)actionItem;

-(void)scanStevedore:(QMActionItem *)actionItem;

-(void)scanProj:(QMActionItem *)actionItem;

@end
