//
//  AVMonitor.h
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import Cocoa;
@import Foundation;

#import <CoreAudio/CoreAudio.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardware.h>

#import "consts.h"
#import "Client.h"
#import "Event.h"
#import "LogMonitor.h"
#import <QMCoreFunction/QMSafeMutableArray.h>

typedef void (^AVMonitorCompleteBlock)(AVDevice device, NSControlStateValue state, Client* client);

@interface AVMonitor : NSObject

//video log monitor
@property(nonatomic, retain) LogMonitor *videoLogMonitor;

//audio log monitor
@property(nonatomic, retain) LogMonitor *audioLogMonitor;

//video clients
@property(nonatomic, retain) QMSafeMutableArray *videoClients;

//audio clients
@property(nonatomic, retain) QMSafeMutableArray *audioClients;

//audio (mic) callback
@property(nonatomic, copy) AudioObjectPropertyListenerBlock listenerBlock;

//camera state
@property NSControlStateValue cameraState;

//microphone state
@property NSControlStateValue microphoneState;

//last microphone state
@property(nonatomic, retain) Event* lastMicEvent;

//monitor callback
@property(nonatomic, copy) AVMonitorCompleteBlock completeBlock;

@end

@interface AVMonitor (API)
//start
-(void)start;

//stop
-(void)stop;

@end

