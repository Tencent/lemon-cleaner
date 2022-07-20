//
//  logMonitor.h
//  logAPI
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define LOGGING_SUPPORT @"/System/Library/PrivateFrameworks/LoggingSupport.framework"

// public OSLogEvent object
@interface OSLogEvent : NSObject
@property NSString *process;
@property NSNumber* processIdentifier;
@property NSString *processImagePath;
@property NSString *sender;
@property NSString *senderImagePath;
@property NSString *category;
@property NSString *subsystem;
@property NSDate *date;
@property NSString *composedMessage;
@end

//private log stream object
@interface OSLogEventLiveStream : NSObject

- (void)activate;
- (void)invalidate;
- (void)setFilterPredicate:(NSPredicate*)predicate;
- (void)setDroppedEventHandler:(void(^)(id))callback;
- (void)setInvalidationHandler:(void(^)(int, id))callback;
- (void)setEventHandler:(void(^)(id))callback;

@property(nonatomic) unsigned long long flags;

@end

//private log event object
//implementation in framework
@interface OSLogEventProxy : NSObject

@property(readonly, nonatomic) NSString *process;
@property(readonly, nonatomic) int processIdentifier;
@property(readonly, nonatomic) NSString *processImagePath;

@property(readonly, nonatomic) NSString *sender;
@property(readonly, nonatomic) NSString *senderImagePath;

@property(readonly, nonatomic) NSString *category;
@property(readonly, nonatomic) NSString *subsystem;

@property(readonly, nonatomic) NSDate *date;

@property(readonly, nonatomic) NSString *composedMessage;

@end


//(our) log monitor object
@interface LogMonitor : NSObject

//instance of live stream
@property(nonatomic, retain, nullable)OSLogEventLiveStream* liveStream;

/* METHODS */

//start
-(BOOL)start:(NSPredicate*)predicate level:(NSUInteger)level callback:(void(^)(OSLogEvent*))callback;

//stop
-(void)stop;

@end

NS_ASSUME_NONNULL_END
