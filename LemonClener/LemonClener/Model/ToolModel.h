//
//  ToolModel.h
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToolModel : NSObject

@property (strong, nonatomic) NSString *toolId;
@property (strong, nonatomic) NSString *toolPicName;
@property (strong, nonatomic) NSString *className;
@property (strong, nonatomic) NSString *toolName;
@property (strong, nonatomic) NSString *toolDesc;
@property (assign, nonatomic) NSInteger reportId;

-(id)initWithToolId:(NSString *)toolId toolPicName:(NSString *)toolPicName className:(NSString *)className toolName:(NSString *)toolName toolDesc:(NSString *)toolDesc reportId:(NSInteger)reportId;

@end
