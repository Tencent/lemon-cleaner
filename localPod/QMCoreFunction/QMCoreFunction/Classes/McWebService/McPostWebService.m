//
//  McPostWebService.m
//  UserSystem
//
//  
//  Copyright (c) 2012 Magican Software Ltd. All rights reserved.
//

#import "McPostWebService.h"
#import "McWebDefine.h"

static NSString *kBoundaryStr=@"_insert_some_boundary_here_";

@implementation McPostWebService
@synthesize postDic=_postDic;

//
- (NSData*)generateFormData:(NSDictionary*)dict
{
	NSString* boundary = [NSString stringWithString:kBoundaryStr];
	NSArray* keys = [dict allKeys];
	NSMutableData* result = [[NSMutableData alloc] init];
    
    NSStringEncoding  encoding = NSUTF8StringEncoding; //NSASCIIStringEncoding;
	for (int i = 0; i < [keys count]; i++) 
	{
		id value = [dict valueForKey: [keys objectAtIndex: i]];
		[result appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:encoding]];
		if ([value isKindOfClass:[NSString class]])
		{
			[result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:encoding]];
			[result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:encoding]];
		}
        if ([value isKindOfClass:[NSNumber class]])
		{
			[result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:encoding]];
			[result appendData:[[value stringValue] dataUsingEncoding:encoding]];
		}
		else if ([value isKindOfClass:[NSURL class]] && [value isFileURL])
		{
			[result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [keys objectAtIndex:i], [[value path] lastPathComponent]] dataUsingEncoding:encoding]];
			[result appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:encoding]];
			[result appendData:[NSData dataWithContentsOfFile:[value path]]];
		}
        else if ([value isKindOfClass:[NSData class]])
        {
            [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"NONAME\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:encoding]];
			[result appendData:value];
        }
		[result appendData:[@"\r\n" dataUsingEncoding:encoding]];
	}
	[result appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:encoding]];
	
	return result;
}

- (NSURLRequest *)setUpRequest:(NSError **)error
{
    if (!_url)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                         code:kMcWebServiceErrorCodeURLBad
                                     userInfo:@{NSLocalizedDescriptionKey: @"URL Can not be nil!"}];
        }
        return nil;
    }
    
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc] initWithURL:_url
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:_timeoutInterval];
    if (!request)
        return nil;
        
    //设置request的属性和Header
    [request setHTTPMethod:@"POST"];    
    NSString *header_type = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundaryStr];
    [request addValue: header_type forHTTPHeaderField: @"Content-Type"];
    
    //按照HTTP的相关协议格式化数据
    NSData *postData=[self generateFormData:_postDic];
    [request addValue:[NSString stringWithFormat:@"%ld",[postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
    if (error) *error = NULL;
    return request;
}

@end
