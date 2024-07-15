//
//  McGpuInfo.m
//  LemonStat
//
//

#import "McGpuInfo.h"

@implementation McGpuInfo

- (void)updateInfoType:(McGpuInfoType)type {
    
    switch (type) {
        case McGpuInfoTypeDefault:
            [self updateInfoIOService];
            break;
        case McGpuInfoTypeUsage:
            [self updateInfoIOService];
            break;
        default:
            break;
    }
    
}

#pragma mark - private

// 从IOKit返回的信息拆分为当前需要的信息
- (void)updateInfoIOService {
    NSMutableArray *mutableCores = [[NSMutableArray alloc] init];
    
    NSArray *coreList = [self getIOServiceForGpu];
    for (NSDictionary *dict in coreList) {
        NSDictionary *stats = dict[@"PerformanceStatistics"];
        if (![dict isKindOfClass:NSDictionary.class]) {
            NSLog(@"GPU:PerformanceStatistics not exist");
            return;
        }
        
        NSNumber *utilization = stats[@"Device Utilization %"];
        if (![utilization isKindOfClass:NSNumber.class]) {
            utilization = stats[@"GPU Activity(%)"];
        }
        if (![utilization isKindOfClass:NSNumber.class]) {
            continue;
        }
        
        // IOKit 框架定义的标识符属性
        NSNumber *IOVARendererID = dict[@"IOVARendererID"];
        NSInteger ID = 0;
        if ([IOVARendererID isKindOfClass:NSNumber.class]) {
            ID = [IOVARendererID longValue];
        }
        CGFloat usage = [utilization longValue] / 100.0;
        usage = fmaxf(0.0, fminf(usage, 1.0));
        
        McGpuCore *gpuCore = [[McGpuCore alloc] init];
        gpuCore.ID = ID;
        gpuCore.usage = usage;
        
        [mutableCores addObject:gpuCore];
    }
    self.cores = [mutableCores copy];
}

- (NSArray<NSDictionary *> *)getIOServiceForGpu {
    io_iterator_t iterator;
    io_registry_entry_t obj = 1;
    NSMutableArray<NSDictionary *> *list = [NSMutableArray array];
    
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOAcceleratorClassName), &iterator);
    if (result != kIOReturnSuccess) {
        NSString *errorMessage = [NSString stringWithCString:mach_error_string(result) encoding:NSASCIIStringEncoding];
        NSLog(@"GPU:Error IOServiceGetMatchingServices(): %@", errorMessage ?: @"unknown error");
        return nil;
    }
    
    while (obj != 0) {
        obj = IOIteratorNext(iterator);
        NSDictionary *props = [self getIOPropertiesForEntry:obj];
        if (props) {
            [list addObject:props];
        }
        IOObjectRelease(obj);
    }
    IOObjectRelease(iterator);
    
    return list.count > 0 ? [list copy] : nil;
}

- (NSDictionary *)getIOPropertiesForEntry:(io_registry_entry_t)entry {
    CFMutableDictionaryRef properties = NULL;
    kern_return_t result = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0);
    if (result != kIOReturnSuccess) {
        return nil;
    }
    
    NSDictionary *propertiesDictionary = CFBridgingRelease(properties);
    return propertiesDictionary;
}

@end

@implementation McGpuCore

- (id)copyWithZone:(NSZone *)zone {
    McGpuCore *copy = [[McGpuCore allocWithZone:zone] init];
    copy.ID = self.ID;
    copy.usage = self.usage;
    return copy;
}

@end
