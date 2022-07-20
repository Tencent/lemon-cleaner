//
//  LMUninstallXMLParseManager.h
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMUninstallItem.h"

NS_ASSUME_NONNULL_BEGIN

//暂时没使用
@protocol LMUninstallXMLParseDelegate <NSObject>

- (void)xmlParseDidEndDocument;

@end

@interface LMUninstallXMLParseManager : NSObject<NSXMLParserDelegate>

+(LMUninstallXMLParseManager *)sharedManager;
-(void)startParseXML;

@property NSMutableArray<LMUninstallItem *> *uninstallItems;
@property NSString *version;

@property id<LMUninstallXMLParseDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
