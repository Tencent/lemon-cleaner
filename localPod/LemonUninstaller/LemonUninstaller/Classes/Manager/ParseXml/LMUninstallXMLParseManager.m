//
//  LMUninstallXMLParseManager.m
//  LemonUninstaller
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "LMUninstallXMLParseManager.h"
#import "LMUninstallItem.h"

#define XMLElemtUninstall @"uninstall"
#define XMLElemtBundle @"bundle"
#define XMLElemtApplicationSupport @"application_support"
#define XMLELemtCrashReporter   @"crashReporter"
#define XMLElemtLaunchService @"launchService"
#define XMLElemtOther @"other"

#define XMLKeyVersion @"version"
#define XMLKeyBundleId @"bundleId"
#define XMLKeyVersion @"version"
#define XMLKeyName @"name"


@interface LMUninstallXMLParseManager ()

@property LMUninstallItem *currentItem;

@end

@implementation LMUninstallXMLParseManager

+ (LMUninstallXMLParseManager *)sharedManager{
    static LMUninstallXMLParseManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LMUninstallXMLParseManager alloc] init];
    });
    return instance;
}



-(void)startParseXML{
    NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"uninstall" ofType:@"xml"];
    self.uninstallItems = [[NSMutableArray alloc] init];
    NSData *data = [NSData dataWithContentsOfFile:sourcePath];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    [parser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
//    NSLog(@"%s",__FUNCTION__);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict{
//    NSLog(@"%s",__FUNCTION__);
    if ([elementName isEqualToString:XMLElemtUninstall]) { //头节点
        NSString *version = attributeDict[XMLKeyVersion];
        self.version = version;
    }else if ([elementName isEqualToString:XMLElemtBundle]){
        NSString *bundleId = attributeDict[XMLKeyBundleId];
        self.currentItem = [[LMUninstallItem alloc] init];
        self.currentItem.bundleId = bundleId;
    }else if ([elementName isEqualToString:XMLElemtApplicationSupport]){
        NSString *supportName = attributeDict[XMLKeyName];
        self.currentItem.applicationSupportName = supportName;
    }else if ([elementName isEqualToString:XMLElemtOther]){
        NSString *otherName = attributeDict[XMLKeyName];
        self.currentItem.otherName = otherName;
    }else if ([elementName isEqualToString:XMLELemtCrashReporter]){
        NSString *crashName = attributeDict[XMLKeyName];
        self.currentItem.crashReporterName = crashName;
    }else if ([elementName isEqualToString:XMLElemtLaunchService]){
        NSString *launchName = attributeDict[XMLKeyName];
        self.currentItem.launchServiceName = launchName;
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if([elementName isEqualToString:XMLElemtBundle]){ //bundle解析结束添加到数组中
        [self.uninstallItems addObject:self.currentItem];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
//    NSLog(@"%s",__FUNCTION__);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
//    NSLog(@"%s",__FUNCTION__);
    if(self.delegate){
        [self.delegate xmlParseDidEndDocument];
    }
    
}



@end
