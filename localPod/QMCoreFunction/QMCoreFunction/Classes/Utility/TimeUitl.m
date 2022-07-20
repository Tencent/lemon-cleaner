//
//  TimeUitl.m
//  QMCoreFunction
//
//  
//

#import "TimeUitl.h"
#include <stdio.h>
#include <utmpx.h>

@implementation TimeUitl

+(CFTimeInterval) getSystemUptime{
    
    enum { NANOSECONDS_IN_SEC = 1000 * 1000 * 1000 };
    static double multiply = 0;
    if (multiply == 0)
    {
        mach_timebase_info_data_t s_timebase_info;
        kern_return_t result = mach_timebase_info(&s_timebase_info);
        assert(result == noErr);
        // multiply to get value in the nano seconds
        multiply = (double)s_timebase_info.numer / (double)s_timebase_info.denom;
        // multiply to get value in the seconds
        multiply /= NANOSECONDS_IN_SEC;
    }
    if (@available(macOS 10.12, *)) {
        return mach_continuous_time() * multiply;
    } else {
        return mach_absolute_time() * multiply;
    }
}

// https://stackoverflow.com/questions/14341230/objective-c-users-login-and-logout-time

//don't know if there are any special Cocoa function to get user login/logout time.

//But you can read the login/logout history directly, using getutxent_wtmp(). This is what the "last" command line tool does, as can be seen in the source code: // http://www.opensource.apple.com/source/adv_cmds/adv_cmds-149/last/last.c
//测试了下,并不是按顺序输出 login logout 的时间,并且日志也不太对.(没有输出最近的)
+(void) getSystemLoginOrLogoutTime{
    
    struct utmpx *bp;
    char *ct;
    
    setutxent_wtmp(0); // 0 = reverse chronological order
    while ((bp = getutxent_wtmp()) != NULL) {
        switch (bp->ut_type) {
            case USER_PROCESS:
                ct = ctime(&bp->ut_tv.tv_sec);
                printf("%s login %s", bp->ut_user, ct);
                break;
            case DEAD_PROCESS:
                ct = ctime(&bp->ut_tv.tv_sec);
                printf("%s logout %s", bp->ut_user, ct);
                break;
                
            default:
                break;
        }
    };
    endutxent_wtmp();
    
}

@end
