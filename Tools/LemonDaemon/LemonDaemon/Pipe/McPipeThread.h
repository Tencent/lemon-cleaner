//
//  McPipeThread.h
//  McDaemon
//
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <semaphore.h>
#import "McPipeStruct.h"

@interface McPipeThread : NSOperation 
{
    NSString    *path_read;
    NSString    *path_write;
    
    int         fd_read;
    void        *map_read;
    sem_t       *sem_read;
    
    int         fd_write;
    void        *map_write;
    sem_t       *sem_write;
}

- (id)init:(NSString *)path;
@end
