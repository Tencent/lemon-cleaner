//
//  logMonitor.m
//  logAPI
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import OSLog;

#import "LogMonitor.h"

/* GLOBALS */

//log handle
extern os_log_t logHandle;

@implementation OSLogEvent
+ (instancetype) OSLogEvent {
    return [[self alloc] init];
}
@end

//parse the private OSLogEventProxy event
// pull out items of interest, and save into our defined event
static OSLogEvent* parseEvent(OSLogEventProxy* event)
{
    //sanity check
    if (!event) {
        NSLog(@"parseEvent: event is nil");
        return nil;
    }
    
    //wrap in @try-@catch to prevent crashes from accessing deallocated event
    @try {
        OSLogEvent *logEvent = [OSLogEvent OSLogEvent];
        logEvent.process = event.process;
        logEvent.processImagePath = event.processImagePath;
        logEvent.processIdentifier = [NSNumber numberWithInt:event.processIdentifier];
        logEvent.sender = event.sender;
        logEvent.senderImagePath = event.senderImagePath;
        logEvent.category = event.category;
        logEvent.subsystem = event.subsystem;
        logEvent.date = event.date;
        logEvent.composedMessage = event.composedMessage;
        return logEvent;
    }
    @catch (NSException *exception) {
        os_log_error(logHandle, "ERROR: parseEvent threw exception: %{public}@", exception);
        return nil;
    }
}

@implementation LogMonitor

//init
// load private framework, etc
-(id)init
{
    //error
    NSError* error = nil;

    //super
    self = [super init];
    if(nil != self)
    {
        //ensure `LoggingSupport.framework` is loaded
        if(YES != [[NSBundle bundleWithPath:LOGGING_SUPPORT] loadAndReturnError:&error])
        {
            //err msg
            os_log_error(logHandle, "ERROR: failed to load logging framework %{public}@ (error: %{public}@)", LOGGING_SUPPORT, error);

            //unset
            self = nil;

            //bail
            goto bail;
        }
    }

bail:

    return self;
}

//start logging
// pass in predicate to match, and callback
-(BOOL)start:(NSPredicate*)predicate level:(NSUInteger)level callback:(void(^)(OSLogEvent*))callback
{
    //flag
    BOOL started = NO;

    //live stream class
    Class LiveStream = nil;

    //event handler callback
    void (^eventHandler)(OSLogEventProxy* event) = ^void(OSLogEventProxy* event) {
        
        //parse event safely
        OSLogEvent *parsedEvent = parseEvent(event);
        
        //check if parsing succeeded
        if (!parsedEvent) {
            NSLog(@"Failed to parse OSLogEventProxy, skipping callback");
            return;
        }
        
        //invoke callback with parsed event
        callback(parsedEvent);
    };

    //get 'OSLogEventLiveStream' class
    if(nil == (LiveStream = NSClassFromString(@"OSLogEventLiveStream")))
    {
        //bail
        goto bail;
    }

    //若已有旧的 liveStream（重复 start），先 invalidate 并释放，避免旧流泄漏、旧 callback 在途投递
    if(nil != self.liveStream)
    {
        [self stop];
    }

    //init live stream
    self.liveStream = [[LiveStream alloc] init];
    if(nil == self.liveStream)
    {
        //bail
        goto bail;
    }

    //sanity check
    // obj responds to `setFilterPredicate:`?
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"setFilterPredicate:")])
    {
        //bail
        goto bail;
    }

    //set predicate
    [self.liveStream setFilterPredicate:predicate];

    //sanity check
    // obj responds to `setInvalidationHandler:`?
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"setInvalidationHandler:")])
    {
        //bail
        goto bail;
    }

    //set invalidation handler
    // note: need to have somethigng set as this get called (indirectly) when
    //       the 'invalidate' method is called ... but don't need to do anything
    [self.liveStream setInvalidationHandler:^void (int reason, id streamPosition) {
        //NSLog(@"invalidation handler called with %d!", reason);
        ;
    }];

    //sanity check
    // obj responds to `setDroppedEventHandler:`?
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"setDroppedEventHandler:")])
    {
        //bail
        goto bail;
    }

    //set dropped msg handler
    // note: need to have somethigng set as this get called (indirectly)
    [self.liveStream setDroppedEventHandler:^void (id droppedMessage)
    {
        //NSLog(@"invalidation handler called with %d!", reason);
        ;
    }];

    //sanity check
    // obj responds to `setEventHandler:`?
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"setEventHandler:")])
    {
        //bail
        goto bail;
    }

    //set event handler
    [self.liveStream setEventHandler:eventHandler];

    //sanity check
    // obj responds to `activate:`?
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"activate")])
    {
        //bail
        goto bail;
    }
    
    //
    if(YES != [self.liveStream respondsToSelector:NSSelectorFromString(@"setFlags:")])
    {
        //bail
        goto bail;
    }

    //set debug & info flags
    [self.liveStream setFlags:level];
    
    //activate
    [self.liveStream activate];

    //happy
    started = YES;

bail:

    return started;
}

//stop stream
// invalidates live stream
-(void)stop
{
    //not nil?
    // invalidate & release our reference
    if(nil != self.liveStream)
    {
        //invalidate（停止系统侧事件投递）
        if(YES == [self.liveStream respondsToSelector:NSSelectorFromString(@"invalidate")])
        {
            [self.liveStream invalidate];
        }

        //断开我方强引用，使 liveStream 及其持有的 eventHandler/callback block 尽快释放，
        //避免重复 start 覆盖时旧 liveStream 泄漏、以及在途回调窗口被拉长
        self.liveStream = nil;
    }
}

//dealloc
// 兜底：对象销毁时确保 liveStream 被 invalidate 并释放
-(void)dealloc
{
    [self stop];
}

@end
