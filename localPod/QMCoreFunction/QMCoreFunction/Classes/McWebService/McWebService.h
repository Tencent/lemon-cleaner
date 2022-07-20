//
//  McWebService.h
//  UserSystem
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^McWebServiceBlock) (NSURLResponse *response, NSError *error, NSData *data);

@protocol McWebServiceDelegate;
@interface McWebService : NSObject
{
	id<McWebServiceDelegate>   __unsafe_unretained _delegate;
	NSURL                      *_url;
    NSTimeInterval  _timeoutInterval;
	
@protected
	NSURLConnection            *_con;
	NSMutableData              *_data;
}
@property (nonatomic, unsafe_unretained) id<McWebServiceDelegate> delegate;
@property (nonatomic, strong) NSURL  *url;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, copy) McWebServiceBlock webServiceBlock;

- (void)stop;
- (BOOL)startAsynchronous;
- (NSData *)startSynchronous;
- (void)startWithHandler:(McWebServiceBlock)block;

+ (NSData *)dataWithURL:(NSURL *)url;
+ (void)serviceWithURL:(NSURL *)url handler:(McWebServiceBlock)block;

@end

@protocol McWebServiceDelegate<NSObject>

- (void)webServiceBegin:(McWebService *)webService;
- (void)webServiceFinish:(McWebService *)webService didReceiveData:(NSData *)data;
- (void)webServiceFail:(McWebService *)webService didFailWithError:(NSError *)error;

@end
