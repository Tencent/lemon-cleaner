//
//  THPostWebService.h
//  UserSystem
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QMCoreFunction/McWebService.h>

@interface McPostWebService : McWebService
{
    NSDictionary *_postDic;
}
@property (nonatomic, strong) NSDictionary *postDic;

@end
