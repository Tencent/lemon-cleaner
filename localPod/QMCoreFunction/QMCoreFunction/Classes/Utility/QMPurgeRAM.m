//
//  QMPurgeRAM.m
//  QMCoreFunction
//
//  
//  Copyright (c) 2014年 Tencent. All rights reserved.
//

#import "QMPurgeRAM.h"
#import <mach/mach.h>
#import "QMEnvironmentInfo.h"
#import "McCoreFunction.h"
#import <mach/mach.h>
#import <malloc/malloc.h>

@implementation QMPurgeRAM

int GetPhysMemoryInfo2(uint64_t mem_info[5]);
int purgeRamByAllocFree(void);
int purgeRamByCoreProfile(void);

int GetPhysMemoryInfo(uint64_t mem_info[4]);
// get physical memory information
// index from 0 - 3: free / inactive / active / wired
int GetPhysMemoryInfo(uint64_t mem_info[4])
{
    kern_return_t kr;
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t count = sizeof(vm_stat) / sizeof(natural_t);
    
    if (mem_info == NULL)
        return -1;
    
    // get page size
    kr = host_page_size(mach_host_self(), &pagesize);
    if (kr != KERN_SUCCESS)
    {
        NSLog(@"[%s] get page size fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    // get vm info
    kr = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &count);
    if (kr != KERN_SUCCESS)
    {
        NSLog(@"[%s] get host statics fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    mem_info[0] = vm_stat.free_count * pagesize;
    mem_info[1] = vm_stat.inactive_count * pagesize;
    mem_info[2] = vm_stat.active_count * pagesize;
    mem_info[3] = vm_stat.wire_count * pagesize;
    
    return 0;
}

+ (BOOL)purgeByLocal
{
    __block BOOL result = NO;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    //dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_group_async(dispatchGroup, dispatch_get_global_queue(0, 0), ^(){
        do
        {
            if (purgeRamByHugeMMAPFree() == 0) {
                result = YES;
                break;
            }
            if (purgeRamByHugeMallocFree() == 0) {
                result = YES;
                break;
            }
            if (purgeRamByZoneAlloc() == 0) {
                result = YES;
                break;
            }
// 分配之后占用更大了，先去掉
//            if (purgeRamByAllocFree() == 0) {
//                result = YES;
//                break;
//            }

// 10.12之后就废弃了，基本用不上
//            if (purgeRamBySyscall() == 0) {
//                result = YES;
//                break;
//            }
            
        } while (NO);
    });
    dispatch_group_wait(dispatchGroup, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    
    return result;
}

+ (BOOL)purgeBySystem
{
    if ([QMEnvironmentInfo systemVersion] >= QMSystemVersionMavericks)
    {
        return [[McCoreFunction shareCoreFuction] purgeMemory];
    }else
    {
        return (system("purge")==0);
    }
}

+ (uint64_t)purge
{
    //控制释放内存频率
    static NSTimeInterval interval = 0;
    NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
    if (currentInterval - interval < 10)
    {
        sleep(1);
        return 0;
    }
    interval = currentInterval;
    
    uint64_t meminfo[4] = {0};
    uint64_t totalFree1 = 0;
    uint64_t totalFree2 = 0;
    
    if (GetPhysMemoryInfo(meminfo) == 0)
    {
        totalFree1 = meminfo[0];
    }
    
    if (![self purgeByLocal])
    {
        [self purgeBySystem];
    }
    
    //延迟1秒,等待系统刷新内存状态
    sleep(1);
    
    if (GetPhysMemoryInfo(meminfo) == 0)
    {
        totalFree2 = meminfo[0];
        if (totalFree2 > totalFree1)
        {
            return totalFree2-totalFree1;
        }
    }
    
    return 0;
}



int GetPhysMemoryInfo2(uint64_t mem_info[5]) {
    kern_return_t kr;
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    mach_msg_type_number_t count = sizeof(vm_stat) / sizeof(natural_t);
    
    if (mem_info == NULL)
        return -1;
    
    // get page size
    kr = host_page_size(mach_host_self(), &pagesize);
    if (kr != KERN_SUCCESS)
    {
        NSLog(@"[%s] get page size fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    // get vm info
    kr = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vm_stat, &count);
    if (kr != KERN_SUCCESS)
    {
        NSLog(@"[%s] get host statics fail: %d", __FUNCTION__, kr);
        return -1;
    }
    
    mem_info[0] = vm_stat.free_count * pagesize;
    mem_info[1] = vm_stat.inactive_count * pagesize;
    mem_info[2] = vm_stat.active_count * pagesize;
    mem_info[3] = vm_stat.wire_count * pagesize;
    mem_info[4] = vm_stat.purgeable_count * pagesize;
    
    //natural_t pages = 8*1024*1024/4 - vm_stat.free_count - vm_stat.inactive_count - vm_stat.active_count - vm_stat.wire_count;
    return 0;
}

// 通过 mmap 强制占用物理内存
int purgeRamByHugeMMAPFree(void) {
    uint64_t before[5] = {0};
    if (GetPhysMemoryInfo2(before) != 0) {
        fprintf(stderr, "Failed to get memory stats\n");
        return -1;
    }

    const uint64_t alloc_size = before[0] + before[1] + before[4];
    if (alloc_size == 0) {
        NSLog(@"No reclaimable memory");
        return 0;
    }
    
    // 检查alloc_size是否超过size_t最大值
    if (alloc_size > SIZE_MAX) {
        NSLog(@"purgeRamByHugeMMAPFree: alloc_size exceeds SIZE_MAX");
        return -1;
    }

    // 通过 mmap 分配匿名内存（避免堆碎片）
    void *mem = mmap(NULL, alloc_size, PROT_READ | PROT_WRITE,
                    MAP_ANON | MAP_PRIVATE, -1, 0);
    if (mem == MAP_FAILED) {
        NSLog(@"mmap failed");
        return -1;
    }
    
    NSLog(@"purgeRamByHugeMMAPFree GetPhysMemoryInfo2 totalFree: %llu", alloc_size);

    // 强制占用物理内存：每 page_size 页写入首个字节
    const size_t page_size = getpagesize();
    for (uint64_t offset = 0; offset < alloc_size; offset += page_size) {
        ((volatile char*)mem)[offset] = 0xAA;
    }

    // 立即释放内存（触发内核回收）
    munmap(mem, alloc_size);
    
    malloc_zone_pressure_relief(malloc_default_zone(), 0);

    return 0;
}

// 大块内存立即分配释放
int purgeRamByHugeMallocFree(void) {
    uint64_t before[5] = {0};
    if (GetPhysMemoryInfo2(before) != 0) return -1;

    const uint64_t alloc_size = before[0] + before[1] + before[4];
    if (alloc_size == 0) {
        return 0;
    }
    
    // 检查alloc_size是否超过size_t最大值
    if (alloc_size > SIZE_MAX) {
        NSLog(@"purgeRamByHugeMallocFree: alloc_size exceeds SIZE_MAX");
        return -1;
    }

    // 使用稀疏写入模式
    void *mem = malloc(alloc_size);
    if (!mem) {
        return -1;
    }
    NSLog(@"purgeRamByHugeMallocFree GetPhysMemoryInfo2 totalFree: %llu", alloc_size);
    
    // 每page_size页写入首个字节（避免全量写入）
    const size_t page_size = getpagesize();
    for (uint64_t offset = 0; offset < alloc_size; offset += page_size) {
        ((volatile char*)mem)[offset]= 0xAA;
    }

    free(mem);
    
    // 建议内存回收
    malloc_zone_t *zone = malloc_default_zone();
    if (zone) {
        malloc_zone_pressure_relief(zone, 0);
    }
    return 0;
}

// 这个方法测试下来，释放后比释放前占用更多，和第一种方法类似，且效率低
// alloc huge memory and free
int purgeRamByAllocFree(void)
{
    uint64_t meminfo[5] = {0};
    int ret = GetPhysMemoryInfo2(meminfo);
    NSLog(@"GetPhysMemoryInfo ret: %d", ret);
    if (ret != 0) {
        NSLog(@"GetPhysMemoryInfo ret: %d,  %d  -1", ret, (ret != 0));
        return -1;
    }
    
    // free + inactive
    uint64_t totalFree = meminfo[0] + meminfo[1];// + meminfo[4];
    
    if (totalFree == 0)
        return 0;
    
    // malloc
//    unsigned int*p = malloc(totalFree);
    volatile unsigned int*p = malloc(totalFree);
    if (p == NULL)
        return -1;
    
    NSLog(@"GetPhysMemoryInfo totalFree: %llu", totalFree);
    for (int i = 0; i < totalFree/sizeof(int); i++)
    {
        //*((int *)p + i) = i;
        p[i] = rand();
    }
    
    // free
    free((void *)p);
    
    NSLog(@"GetPhysMemoryInfo end");
    return 0;
}

unsigned long long memory_to_eat = 1024 * 1024 * 16;
size_t eaten_memory = 0;
void *memory = NULL;

int eat_kilobyte() {
    if (memory == NULL)
        memory = malloc(1024);
    else
        memory = realloc(memory, (eaten_memory * 1024) + 1024);
    if (memory == NULL)
    {
        return 1;
    }
    else
    {
        //Force the kernel to map the containing memory page.
        ((char*)memory)[1024*eaten_memory] = 42;
        
        eaten_memory++;
        return 0;
    }
}

int purgeRamByZoneAlloc(void) {
    uint64_t meminfo[5] = {0};
    if (GetPhysMemoryInfo2(meminfo) != 0)
        return -1;
    
    // free + inactive
    uint64_t totalFree = meminfo[0];
    
    if (meminfo[1] <= meminfo[0])
    {
    }
    else if (meminfo[1] <= meminfo[0] * 2)
    {
        totalFree += meminfo[1] / 4;
    }
    else if (meminfo[1] < meminfo[0] * 4)
    {
        totalFree += meminfo[1] / 2;
    }
    else
    {
        totalFree += meminfo[1];
    }
    
    if (totalFree == 0)
        return 0;
    
    uint64_t procCount = [[NSProcessInfo processInfo] processorCount];
    
    malloc_zone_t *zone = malloc_create_zone(totalFree, 0);
    if (zone == NULL)
        return -1;
    
    // unitSize 设置为 0x1000 可以完全释放，但可能造成卡顿
    unsigned short unitSize = 0x1000;
    uint64_t allocSize = (totalFree / procCount) / unitSize;
    //allocSize -= 0x100;
    
    //NSLog(@"Start to purge: %llu", allocSize);
    
    NSOperationQueue *operation = [[NSOperationQueue alloc] init];
    for (int i = 0; i < procCount; i++)
    {
        [operation addOperationWithBlock:^{
            [NSThread setThreadPriority:1.0];
            unsigned int *pnew = malloc_zone_calloc(zone, allocSize, unitSize);
            //NSLog(@"Alloc finish");
            if (pnew != NULL)
            {
                for (uint64_t count = 0; count < allocSize; count++)
                {
                    *((uint8_t *)pnew + count * unitSize) = (uint8_t)count;
                }
                //memset(pnew, 0, allocSize * unitSize);
            }
            //NSLog(@"Alloc fill finish");
        }];
    }
    [operation waitUntilAllOperationsAreFinished];
    //NSLog(@"Alloc All finish");
    malloc_destroy_zone(zone);
    //NSLog(@"Destroy finish");
    return 0;
}

int purgeRamBySyscall() {
    // this is used for >= 10.9
    // must be called by root
    int ret = 0;
    ret = syscall(455);
    //printf("purgeRamBySyscall:%d err: %d\n", ret, errno);
    return ret;
}

@end
