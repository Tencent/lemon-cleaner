//
//  McWebService.m
//  UserSystem
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McWebService.h"
#import "McWebDefine.h"

@implementation McWebService
@synthesize delegate=_delegate;
@synthesize url=_url;
@synthesize timeoutInterval=_timeoutInterval;
@synthesize webServiceBlock;

+ (NSData *)dataWithURL:(NSURL *)url
{
    McWebService *service = [[[self class] alloc] init];
    service.url = url;
    return [service startSynchronous];
}

+ (void)serviceWithURL:(NSURL *)url handler:(McWebServiceBlock)block
{
    McWebService *service = [[[self class] alloc] init];
    service.url = url;
    [service startWithHandler:block];
}

- (id)init
{
    self = [super init];
    if (self) {
        _timeoutInterval = kMcWebServiceTimeoutInterval;
    }
    return self;
}

- (void)stop
{
    [_con cancel];
    _con = nil;
}

- (NSURLRequest *)setUpRequest:(NSError **)error
{
    if (!_url)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                         code:kMcWebServiceErrorCodeURLBad
                                     userInfo:@{NSLocalizedDescriptionKey:@"URL Can not be nil!"}];
        }
        return nil;
    }
    
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc] initWithURL:_url
															  cachePolicy:NSURLRequestUseProtocolCachePolicy
														  timeoutInterval:_timeoutInterval];
    if (!request)
        return nil;
    
	[request setHTTPMethod:@"GET"];
    return request;
}

- (BOOL)startAsynchronous
{
    [self stop];
    NSError *error = nil;
    NSURLRequest *request = [self setUpRequest:&error];
    if (!request)
    {
        if ([_delegate respondsToSelector:@selector(webServiceFail:didFailWithError:)])
        {
            [_delegate webServiceFail:self didFailWithError:error];
        }
        return NO;
    }
    _data = [[NSMutableData alloc] init];
    _con = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [_con scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [_con start];
    return YES;
}

- (NSData *)startSynchronous
{
    [self stop];
    NSError *error = nil;
    NSURLRequest *request = [self setUpRequest:&error];
    if (!request) return nil;
    NSURLResponse  *response;
    NSData *receiveData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    return receiveData;
}

- (void)startWithHandler:(McWebServiceBlock)block
{
    [self stop];
    self.webServiceBlock = block;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLResponse  *response = nil;
        NSError *error = nil;
        NSData *receiveData = nil;
        NSURLRequest *request = [self setUpRequest:&error];
        if (request)
        {
            receiveData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        }
        if (self.webServiceBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.webServiceBlock(response,error,receiveData);
            });
        }
    });
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([_delegate respondsToSelector:@selector(webServiceBegin:)])
    {
		[_delegate webServiceBegin:self];
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData
{
    if(_con!=nil)
    {
	    [_data appendData:aData];
	}
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(webServiceFail:didFailWithError:)])
    {
		[_delegate webServiceFail:self didFailWithError:error];
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([_delegate respondsToSelector:@selector(webServiceFinish:didReceiveData:)])
    {
		[_delegate webServiceFinish:self didReceiveData:_data];
	}
}

@end
