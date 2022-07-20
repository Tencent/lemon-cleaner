//
//  McPipeThread.m
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import "McPipeThread.h"
#import "CmcProcess.h"
#import "CmcProcInfo.h"
#import "Cmcfsmonitor.h"
#import "CmcNetSocket.h"
#import "McUninstall.h"
#import "CmcFileAction.h"
#import "CmcFan.h"
#import "McRemoveTrojan.h"
#import "OwlManageDaemon.h"
#import "McKextMgr.h"
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/errno.h>
#import <sys/types.h>
#import <sys/mman.h>
#import "LMXPCFunction.h"

int g_mapsize = 1024*1024*2;

@implementation McPipeThread

- (id)init:(NSString *)path
{
    fd_read = -1;
    fd_write = -1;
    
    
    if (self = [super init])
    {
        // try create directory
        if (mkdir(MCPIPE_DIR, S_IRWXU|S_IRWXG|S_IRWXO) != 0) {
            NSLog(@"[ERR] init mkdir fail: %d", errno);
        }
        if (chmod(MCPIPE_DIR, 0777) != 0) {
            NSLog(@"[ERR] init chmod MCPIPE_DIR fail: %d", errno);
        }
        
        // remove lock directory
        NSString *path_lock = [path stringByAppendingString:MCLOCK_POSTFIX];
        rmdir([path_lock UTF8String]);
        
        path_read = [path stringByAppendingString:MCREAD_POSTFIX];
        path_write = [path stringByAppendingString:MCWRITE_POSTFIX];
        
        // try to remove at first
        if (remove([path_read UTF8String]) != 0) {
            NSLog(@"[ERR] init remove path_read fail: %d", errno);
        }
        if (remove([path_write UTF8String]) != 0) {
            NSLog(@"[ERR] init remove path_write fail: %d", errno);
        }
        
        // create named semaphores
        NSString *semReadPath = [[path_read lastPathComponent] stringByAppendingString:MCSEM_POSTFIX];
        NSString *semWritePath = [[path_write lastPathComponent] stringByAppendingString:MCSEM_POSTFIX];
        sem_read = sem_open([semReadPath UTF8String], O_CREAT, 0666, 0);
        sem_write = sem_open([semWritePath UTF8String], O_CREAT, 0666, 0);
        if (sem_read == (void *)-1 || sem_write == (void *)-1)
        {
            NSLog(@"[ERR] create semaphores fail: %d", errno);
        }
        else
        {
            // create file and map it
            fd_read = open([path_read UTF8String], O_CREAT|O_TRUNC|O_RDWR, 0666);
            if (fd_read == -1)
            {
                NSLog(@"[ERR] open file: %@ fail: %d", path_read, errno);
            }
            else
            {
                ftruncate(fd_read, g_mapsize);
                if (chmod([path_read UTF8String], 0777) != 0) {
                    NSLog(@"[ERR] init chmod path_read fail: %d", errno);
                }
                map_read = mmap(NULL, g_mapsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd_read, 0);
                if (map_read == MAP_FAILED)
                {
                    NSLog(@"[ERR] map read file fail: %d", errno);
                    close(fd_read);
                    fd_read = -1;
                }
                else
                {
                    fd_write = open([path_write UTF8String], O_CREAT|O_TRUNC|O_RDWR, 0666);
                    if (fd_write == -1)
                    {
                        NSLog(@"[ERR] open file: %@ fail: %d", path_write, errno);
                        munmap(map_read, g_mapsize);
                        map_read = MAP_FAILED;
                        close(fd_read);
                        fd_read = -1;
                    }
                    else
                    {
                        ftruncate(fd_write, g_mapsize);
                        if (chmod([path_write UTF8String], 0777) != 0) {
                            NSLog(@"[ERR] init chmod path_write fail: %d", errno);
                        }
                        map_write = mmap(NULL, g_mapsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd_write, 0);
                        if (map_write == MAP_FAILED)
                        {
                            NSLog(@"[ERR] map write file fail: %d", errno);
                            munmap(map_read, g_mapsize);
                            map_read = MAP_FAILED;
                            close(fd_read);
                            fd_read = -1;
                            close(fd_write);
                            fd_write = -1;
                        }
                    }
                    
                }
            }
        }
    }
    return self;
}

- (void)dealloc
{
    // close
    if (fd_read != -1)
        close(fd_read);
    if (fd_write != -1)
        close(fd_write);
    if (map_read != MAP_FAILED)
        munmap(map_read, g_mapsize);
    if (map_write != MAP_FAILED)
        munmap(map_write, g_mapsize);
    
    // delete
    if (remove([path_read UTF8String]) != 0) {
        NSLog(@"[ERR] dealloc remove path_read fail: %d", errno);
    }
    if (remove([path_write UTF8String]) != 0) {
        NSLog(@"[ERR] dealloc remove path_write fail: %d", errno);
    }
    
    // close
    sem_close(sem_read);
    sem_close(sem_write);
}

- (void)main
{
    if (fd_read == -1 || fd_write == -1)
        return;
    
    NSLog(@"main service running");
    
    *(int *)map_read = 0;
    *(int *)map_write = 0;
    
    mc_pipe_cmd *pcmd;
    mc_pipe_result *presult;
    //while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    while (YES)
    {
        @autoreleasepool 
        {
            // waiting for a command !!!
            sem_wait(sem_read);
            
            if (*(int *)map_read != MCARRIVE_CMD)
            {
                NSLog(@"[ERR] Check CMD Magic fail");
                continue;
            }
            
            // remove command
            *(int *)map_read = 0;
            
            // read one command, do it here
            pcmd = (mc_pipe_cmd *)((char *)map_read + sizeof(int));
			
			BytePtr pAddr = (BytePtr)pcmd;
			int size = pcmd->size - sizeof(mc_pipe_cmd);
			for(int i = sizeof(mc_pipe_cmd); i < size; ++i){
				pAddr[i] = ((pAddr[i]-3)^0x7E)^0x41;
			}
			
            [LMXPCFunction cmdDispather:pcmd result:&presult];
            
            if (presult != NULL)
            {
                if (presult->size > g_mapsize - 10)
                {
                    NSLog(@"[ERR] result size to big: %d - %d", presult->cmd_magic, presult->size);
                    presult->size = g_mapsize - 10;
                }
                //            NSLog(@"to send [%d]: %d %d %d", 
                //                  presult->cmd_magic, 
                //                  *(int *)presult, *((int *)presult+1), *((int *)presult+2));
                
                memcpy((char *)map_write + sizeof(int), presult, presult->size);
                *(int *)map_write = MCARRIVE_RESULT;
                free(presult);
            } else {
                NSLog(@"[ERR] presult is NULL");
            }
            
            // notify result
            sem_post(sem_write);
        }
    }
}

@end
