//
//  QMHeaderResponse.m
//  QMDownload
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMHeaderResponse.h"

#define kQMHEADER_TRYMAX 3

@interface QMHeaderResponse ()
{
    NSURL *url;
    int tryCount;
    NSError *error;
    NSURLConnection *connection;
    NSHTTPURLResponse *response;
    dispatch_semaphore_t semaphore;
}
@end

@implementation QMHeaderResponse

+ (NSHTTPURLResponse *)headerResponse:(NSURL *)url error:(NSError **)error
{
    if (!url) return nil;
    QMHeaderResponse *headerResponse = [[QMHeaderResponse alloc] initWithURL:url];
    return [headerResponse headerResponse:error];
}

- (id)initWithURL:(NSURL *)aURL
{
    self = [super init];
    if (self)
    {
        url = aURL;
    }
    return self;
}

- (NSHTTPURLResponse *)headerResponse:(NSError **)aError
{
    //等待子线程结束的信号量
    semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self createConnection];
        CFRunLoopRun();
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    if (aError && error)
    {
        *aError = error;
    }
    
    return response;
}

- (void)createConnection
{
    tryCount++;
    [connection cancel];
    connection = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:10];
    //在10.9以前就算指定了HEAD同步请求仍然会请求到内容,所以此处仍然采用异步方式,获得头之后立即中断
    //[request setHTTPMethod:@"HEAD"];
    //macx.cn竟然对HEAD方式支持不友好,返回的Response取suggestedFilename会有一个.txt后缀
    [request setHTTPMethod:@"GET"];
    
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark -

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse
{
    NSInteger statusCode = [(NSHTTPURLResponse *)aResponse statusCode];
    if (statusCode >= 400)
    {
        if (tryCount < kQMHEADER_TRYMAX)
        {
            [self createConnection];
            return;
        }else
        {
            NSString *localizedForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
            NSDictionary *errorInfo = localizedForStatusCode ? @{NSLocalizedDescriptionKey: localizedForStatusCode} : nil;
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:response.statusCode userInfo:errorInfo];
        }
    }
    [connection cancel];
    connection = nil;
    response = (NSHTTPURLResponse *)aResponse;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)aError
{
    if (tryCount < kQMHEADER_TRYMAX)
    {
        [self createConnection];
        return;
    }
    [connection cancel];
    connection = nil;
    error = aError;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
