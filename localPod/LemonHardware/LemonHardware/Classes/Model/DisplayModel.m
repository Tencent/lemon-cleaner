//
//  DisplayModel.m
//  LemonHardware
//
//  
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "DisplayModel.h"
#import <CoreGraphics/CoreGraphics.h>
#import <AppKit/AppKit.h>
#import "HardwareHeader.h"

#define DISPLAY_PLIST @"display.plist"

@implementation ScreenModel

-(NSString *)description{
    return [NSString stringWithFormat:@"isMainScreen = %hhd, resolution = %@", self.isMainScreen, self.resolution];
}

@end

@implementation GraphicModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.screenArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"graphicModel = %@, graphicVendor = %@, graphicSize = %@, screenArr = %@", self.graphicModel, self.graphicVendor, self.graphicSize, self.screenArr];
}

@end

@implementation DisplayModel

-(instancetype)init{
    self = [super init];
    if (self) {
        self.grapicArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(BOOL)getHardWareInfo{
    //    __weak DisplayModel *weakSelf = self;
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self writeFileToFile];
    [self readFromFile];
    self.isInit = YES;
    //    });
    
    return YES;
}

-(void)writeFileToFile{
    NSString *pathName = [self getHardWareInfoPathByName:DISPLAY_PLIST];
    pathName = [pathName stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    NSString *shellString = [NSString stringWithFormat:@"system_profiler SPDisplaysDataType -xml > %@", pathName];
    @try{
        [QMShellExcuteHelper excuteCmd:shellString];
    }
    @catch(NSException *exception){
        NSLog(@"exception = %@", exception);
    }
}

-(BOOL)readFromFile{
    NSString *fileName = [self getHardWareInfoPathByName:DISPLAY_PLIST];
    NSArray *displayArr = [[NSArray alloc] initWithContentsOfFile:fileName];
    if ([displayArr count] == 0) {
        return NO;
    }
    NSDictionary *dispalyDic = [displayArr objectAtIndex:0];
    if (dispalyDic == nil) {
        return NO;
    }
    if (![[dispalyDic allKeys] containsObject:@"_items"]) {
        return NO;
    }
    NSArray *_itemsArr = [dispalyDic objectForKey:@"_items"];
    if ([_itemsArr count] == 0) {
        return NO;
    }
    
    for (NSDictionary *graphicDic in _itemsArr) {
        if (graphicDic == nil) {
            continue;
        }
        
        GraphicModel *grapicModel = [[GraphicModel alloc] init];
        if (graphicDic[@"sppci_model"] != nil) {
            grapicModel.graphicModel = graphicDic[@"sppci_model"];
        }else{
            grapicModel.graphicModel = graphicDic[@"sppci_device_type"];
        }
        
        grapicModel.graphicVendor = graphicDic[@"spdisplays_vendor"];
        if(graphicDic[@"spdisplays_vram_shared"] == nil || [graphicDic[@"spdisplays_vram_shared"] isEqualToString:@""]){
            grapicModel.graphicSize = graphicDic[@"spdisplays_vram"];
        }else{
            grapicModel.graphicSize = graphicDic[@"spdisplays_vram_shared"];
        }
        
        //再去拿显示器信息
        NSArray *screenArr = graphicDic[@"spdisplays_ndrvs"];
        if ([screenArr count] > 0) {
            for (NSDictionary *screenDic in screenArr) {
                
                ScreenModel *screenModel = [[ScreenModel alloc] init];
                NSString *main_display = screenDic[@"spdisplays_main"];
                if ([main_display isEqualToString:@"spdisplays_yes"]) {
                    screenModel.isMainScreen = YES;
                }else{
                    screenModel.isMainScreen = NO;
                }
                
                NSString *resolution = screenDic[@"spdisplays_pixelresolution"];
                if ((resolution != nil) && [resolution containsString:@"Retina"]) {
                    resolution  = [resolution stringByReplacingOccurrencesOfString:@"spdisplays_" withString:@""];
                    resolution = [resolution stringByReplacingOccurrencesOfString:@"Retina" withString:@""];
                }else{
                    if(@available(macOS 11.4, *)){
                        resolution = [self getScreenResolutionFromOS114];
                    }else{
                        resolution = screenDic[@"_spdisplays_pixels"];
                    }
                }
                
                screenModel.resolution = resolution;
                [grapicModel.screenArr addObject:screenModel];
            }
        }
        [self.grapicArr addObject:grapicModel];
    }
    
//    NSLog(@"DisplayModel = %@", self);
    
    return YES;
}

- (NSString *)getScreenResolutionFromOS114 {
    
    NSDictionary* screenDictionary = [[NSScreen mainScreen] deviceDescription];
    
    NSNumber* screenID = [screenDictionary objectForKey:@"NSScreenNumber"];
    CGDirectDisplayID display = [screenID unsignedIntValue];
    
    Auto options = @{
        (__bridge NSString *)kCGDisplayShowDuplicateLowResolutionModes: (__bridge NSNumber *)kCFBooleanTrue
    };

    CFArrayRef ms = CGDisplayCopyAllDisplayModes(display, (__bridge CFDictionaryRef)options);
    CFIndex n = CFArrayGetCount(ms);
    NSSize ns;
    for(int i = 0; i < n; ++i){
        CGDisplayModeRef m = (CGDisplayModeRef)CFArrayGetValueAtIndex(ms, i);
        if(CGDisplayModeGetIOFlags(m) & kDisplayModeNativeFlag){
            ns.width = CGDisplayModeGetPixelWidth(m);
            ns.height = CGDisplayModeGetPixelHeight(m);
            break;
        }
    }
    CFRelease(ms);
    
    return  [NSString stringWithFormat:@"%d×%d",(int)ns.width ,(int)ns.height];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"grapicArr = %@", self.grapicArr];
}

@end
