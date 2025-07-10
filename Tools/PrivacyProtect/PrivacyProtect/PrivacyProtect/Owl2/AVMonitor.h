//
//  AVMonitor.h
//  Application
//
//  Created by Patrick Wardle on 4/30/21.
//  Copyright © 2021 Objective-See. All rights reserved.
//

@import Cocoa;
@import Foundation;
@import UserNotifications;

#import <CoreAudio/CoreAudio.h>
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardware.h>
#import <AVFoundation/AVCaptureDevice.h>

#import "Event.h"
#import "LogMonitor.h"

typedef void (^AVMonitorEventBlock)(Event* event);

@interface AVMonitor : NSObject <UNUserNotificationCenterDelegate>

//log monitor
@property(nonatomic, retain)LogMonitor* logMonitor;

// 原 logMonitor 没有监听macOS12系统上音频日志，补充监听
@property(nonatomic, retain) LogMonitor* audio12logMonitor;

@property(nonatomic, retain) LogMonitor* controlCenterLogMonitor;
@property(nonatomic, retain) LogMonitor* screenLogMonitor;
@property(nonatomic, retain) LogMonitor* frontMostWindowLogMonitor;   // frontmost window from windowserver
@property(nonatomic, retain) LogMonitor* automaticLogMonitor;         // 自动化权限被使用

//event callback
@property(nonatomic, copy) AVMonitorEventBlock eventCallback;

//camera attributions
@property(nonatomic, retain)NSMutableArray* cameraAttributions;

//audio attributions
@property(nonatomic, retain)NSMutableArray* audioAttributions;

//built in mic
@property(nonatomic, retain)AVCaptureDevice* builtInMic;

//built in camera
@property(nonatomic, retain)AVCaptureDevice* builtInCamera;

//inital mic state
@property NSControlStateValue initialMicState;

//initial camera state
@property NSControlStateValue initialCameraState;

//last camera client
@property NSInteger lastCameraClient;

//last camera off
@property(nonatomic, retain)AVCaptureDevice* lastCameraOff;

//last mic client
@property NSInteger lastMicClient;

//last mic off
@property(nonatomic, retain)AVCaptureDevice* lastMicOff;

//audio listeners
@property(nonatomic, retain)NSMutableDictionary* audioListeners;

//camera listeners
@property(nonatomic, retain)NSMutableDictionary* cameraListeners;

//per device events
@property(nonatomic, retain)NSMutableDictionary* deviceEvents;

//last alert (default) interaction
@property(nonatomic, retain)NSDate* lastNotificationDefaultAction;

//listener queue
@property(nonatomic, retain)dispatch_queue_t eventQueue;

// 当前窗口置顶获得焦点的应用bundleid
@property (nonatomic, copy, nullable) NSString *currentFrontMostAppBundleId;


/* METHODS */

//start
-(void)start;
- (void)watchAllAudioDevice;
- (void)watchAllVideoDevice;
- (void)watchAllScreen;
- (void)unwatchAllAudioDevice;
- (void)unwatchAllVideoDevice;
- (void)unwatchAllScreen;
- (void)watchAutomatic;
- (void)unwatchAutomatic;
- (void)watchFrontMostWindow;
- (void)unwatchFrontMostWindow;

//enumerate active devices
-(NSMutableArray*)enumerateActiveDevices;

- (void)killScreenCaptureAppWithBundleID:(NSString *)bundleID;

//stop
-(void)stop;

@end

