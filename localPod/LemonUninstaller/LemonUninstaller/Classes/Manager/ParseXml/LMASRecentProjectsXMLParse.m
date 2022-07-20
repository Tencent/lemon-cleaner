//
//  LMASRecentProjectsXMLParse.m
//  LemonUninstaller
//
//  
//  Copyright (c) 2021年 Tencent. All rights reserved.
//

#import "LMASRecentProjectsXMLParse.h"

// androidstudio的用户工程目录解析
@interface LMASRecentProjectsXMLParse () {

    NSMutableArray<NSString *>      *_recentProjectsPathList;   ///< 用户工程目录文件集合
    BOOL                            _inRecentPathsTag;          ///< XML文件里工程目录文件tag，用于定位
    BOOL                            _hasError;                  ///< 发生错误

}



@end

@implementation LMASRecentProjectsXMLParse

- (id)init
{
    if (self = [super init])
    {
        _recentProjectsPathList = [NSMutableArray array];
    }
    return self;
}

- (NSArray<NSString *> *)parseXMLWithPath:(NSString *)xmlFilePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath]) {
        return nil;
    }
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlFilePath];
    if (!xmlData || xmlData.length == 0) {
        return nil;
    }
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
    xmlParser.delegate = self;
    [xmlParser parse];
    return [_recentProjectsPathList copy];
}


#pragma mark-
#pragma mark 解析XML委托

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    [_recentProjectsPathList removeAllObjects];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;
{
    _hasError = YES;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    _hasError = YES;
}

///元素开始解析时调用
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if (_hasError) {
        return;
    }
    if ([elementName isEqualToString:@"option"] && [attributeDict[@"name"] isEqualToString:@"recentPaths"]) {
        _inRecentPathsTag = YES;
        return;
    }
    if (_inRecentPathsTag && [elementName isEqualToString:@"option"]) {
        NSString *value = attributeDict[@"value"];
        if (value) {
            NSString *realExistPath = [self getExistFile:value];
            if (realExistPath && realExistPath.length > 0) {
                [_recentProjectsPathList addObject:realExistPath];
            }
        }
    }
}

///元素解析结束调用
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (_inRecentPathsTag && [elementName isEqualToString:@"list"]) {
        _inRecentPathsTag = NO;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{

}

#pragma mark - 内部函数

- (NSString *)getExistFile:(NSString *)projectPathString
{
    if (!projectPathString || projectPathString.length == 0) {
        return nil;
    }
    NSMutableString *path = [NSMutableString stringWithString:projectPathString];
    // 替换$USER_HOME$
    NSString *userHome = [@"~" stringByExpandingTildeInPath];
    NSString *realPath = [path stringByReplacingOccurrencesOfString:@"$USER_HOME$" withString:userHome];
    if ([[NSFileManager defaultManager] fileExistsAtPath:realPath]) {
        return [realPath copy];
    }
    return nil;
}

@end
