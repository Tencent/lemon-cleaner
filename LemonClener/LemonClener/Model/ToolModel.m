//
//  ToolModel.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "ToolModel.h"

@implementation ToolModel

-(id)initWithToolId:(NSString *)toolId toolPicName:(NSString *)toolPicName className:(NSString *)className toolName:(NSString *)toolName toolDesc:(NSString *)toolDesc reportId:(NSInteger)reportId{
    self = [super init];
    if (self) {
        self.toolId = toolId;
        self.toolPicName = toolPicName;
        self.className = className;
        self.toolName = toolName;
        self.toolDesc = toolDesc;
        self.reportId = reportId;
    }
    
    return self;
}

@end
