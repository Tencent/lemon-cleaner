//
//  QMLazyImageView.m
//  LazyImageView
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMLazyImageView.h"
#import <QMCoreFunction/QMDataCache.h>

@interface QMLazyImageView ()
{
    NSMutableData *_data;
    NSImage *_showImage;
    NSURLConnection *_connection;
}
@end

@implementation QMLazyImageView
@synthesize defaultImage;
@synthesize loadingImage;
@synthesize errorImage;
@synthesize link;

- (NSString *)link
{
    return link;
}

- (void)setLink:(NSString *)value
{
    //防止重复加载
    if ([link isEqualToString:value] && (_connection||_showImage))
        return;
    
    _showImage = nil;
    link = [value copy];
    if (!link)
    {
        [self setImage:errorImage?errorImage:defaultImage];
        return;
    }
    
    //检查缓存
    NSData *imgCache = [[QMDataCache sharedCache] dataForKey:link];
    if (imgCache)
    {
        _showImage = [[NSImage alloc] initWithData:imgCache];
        if (_showImage)
        {
            [self setImage:_showImage];
            return;
        }
    }
    
    //暂停当前下载
    _data = nil;
    [_connection cancel];
    [self setImage:loadingImage?loadingImage:defaultImage];
    
    //开启新的加载
    NSURL *url = [NSURL URLWithString:link];
    if (!url)
    {
        [self setImage:errorImage?errorImage:defaultImage];
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	_data = [[NSMutableData alloc] init];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData
{
    [_data appendData:aData];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _data = nil;
    [self setImage:errorImage?errorImage:defaultImage];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _showImage = [[NSImage alloc] initWithData:_data];
    if (_showImage)
    {
        [self setImage:_showImage];
        [[QMDataCache sharedCache] setData:_data forKey:link];
    }else
    {
        [self setImage:errorImage?errorImage:defaultImage];
    }
    
    _data = nil;
}

@end
