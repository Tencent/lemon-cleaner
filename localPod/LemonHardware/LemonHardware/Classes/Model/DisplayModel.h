//
//  DisplayModel.h
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

//显卡和显示器信息

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface ScreenModel : BaseModel

@property (nonatomic, assign) BOOL isMainScreen;
@property (nonatomic, strong) NSString *resolution;//分辨率

@end

@interface GraphicModel : BaseModel

@property (nonatomic, strong) NSString *graphicModel;//显存型号
@property (nonatomic, strong) NSString *graphicVendor;//显存提供商
@property (nonatomic, strong) NSString *graphicSize;//显存大小
@property (nonatomic, strong) NSMutableArray *screenArr;//该显卡下的屏幕

@end

@interface DisplayModel : BaseModel

@property (nonatomic, strong) NSMutableArray *grapicArr;//多个显卡

-(BOOL)getHardWareInfo;

@end
