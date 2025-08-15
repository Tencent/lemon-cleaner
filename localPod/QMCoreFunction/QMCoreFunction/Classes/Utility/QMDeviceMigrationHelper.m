//
//  QMDeviceMigrationHelper.m
//  QMCoreFunction
//
//

#import "QMDeviceMigrationHelper.h"

static NSString * const kSerialNumberKey = @"QMDeviceMigrationHelperSerialNumberKey";

@implementation QMDeviceMigrationHelper

+ (void)checkForDeviceMigrationWithCompletion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *serialCache = [[NSUserDefaults standardUserDefaults] stringForKey:kSerialNumberKey];
        NSString *currentSerial = [self __getCurrentSerialNumber];
        
        BOOL didSwitchDevice = YES;
        if (serialCache && currentSerial) {
            didSwitchDevice = ![serialCache isEqualToString:currentSerial];
        }
        
        if (didSwitchDevice) {
            [[NSUserDefaults standardUserDefaults] setObject:currentSerial forKey:kSerialNumberKey];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(didSwitchDevice);
        });
    });
}

+ (NSString *)__getCurrentSerialNumber {
    CFStringRef serialNumber = NULL;
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 IOServiceMatching("IOPlatformExpertDevice"));
    
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString =
        IORegistryEntryCreateCFProperty(platformExpert,
                                        CFSTR(kIOPlatformSerialNumberKey),
                                        kCFAllocatorDefault, 0);
        if (serialNumberAsCFString) {
            serialNumber = serialNumberAsCFString;
        }
        
        IOObjectRelease(platformExpert);
    }
    
    return (__bridge_transfer NSString *)(serialNumber);
}

@end
