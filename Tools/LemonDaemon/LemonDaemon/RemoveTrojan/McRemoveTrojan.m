/*
 *  CmcFanSpeed.c
 *  TestFunction
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

#include <stdint.h>
#include "McRemoveTrojan.h"
#include "McPipeStruct.h"

// for remove trojans
BOOL fixPlistFile(const char *szPath, const char *szKeyToRemove)
{
    NSString *plistPath = [NSString stringWithUTF8String:szPath];
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    if (infoDic == nil)
        return FALSE;
    
    [infoDic removeObjectForKey:[NSString stringWithUTF8String:szKeyToRemove]];
    
    if (![infoDic writeToFile:plistPath atomically:YES])
    {
        NSLog(@"[ERR] fix Info.plist error - %@", plistPath);
        return FALSE;
    }
    
    return TRUE;
}

int systemCommand(const char *szCmd)
{
    return system(szCmd);
}

BOOL writePlistFile(const char *szPath, 
                    const char *szKeyName,
                    int action_type,
                    int plist_type,
                    int obj_type,
                    unsigned char *obj_data,
                    int obj_size)
{
    id toSetObj = nil;
    if (obj_size > 0)
    {
        NSData *objData = [NSData dataWithBytes:obj_data length:obj_size];
        toSetObj = [NSKeyedUnarchiver unarchiveObjectWithData:objData];
        if (toSetObj == nil)
            return FALSE;
        
        
        // check convert type
        switch (obj_type)
        {
            case MCCMD_TYPE_NSSTRING:
                if (![toSetObj isKindOfClass:[NSString class]])
                    return FALSE;
                break;
                
            case MCCMD_TYPE_NSNUMBER:
                if (![toSetObj isKindOfClass:[NSNumber class]])
                    return FALSE;
                break;
            case MCCMD_TYPE_NSDICTIONARY:
                if (![toSetObj isKindOfClass:[NSDictionary class]])
                    return FALSE;
                break;
                
            default:
                return FALSE;
        }
    }
    else
    {
        if (action_type != MCCMD_WRITEPLIST_DELETE)
            return FALSE;
    }
    
    if (plist_type == MCCMD_PLIST_SYSTEM)
    {
        CFPreferencesSetValue((__bridge CFStringRef)([NSString stringWithUTF8String:szKeyName]),
                              ((action_type == MCCMD_WRITEPLIST_MODIFY) ?  (__bridge CFPropertyListRef)(toSetObj): nil),
                              (__bridge CFStringRef)([NSString stringWithUTF8String:szPath]),
                              kCFPreferencesAnyUser,
                              kCFPreferencesCurrentHost);
        return CFPreferencesSynchronize((__bridge CFStringRef)([NSString stringWithUTF8String:szPath]),
                                 kCFPreferencesAnyUser,
                                 kCFPreferencesCurrentHost);
    }
    else if (plist_type == MCCMD_PLIST_DEFAULT)
    {
        NSString *plistPath = [NSString stringWithUTF8String:szPath];
        NSMutableDictionary *infoDic = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
        if (infoDic == nil)
            return FALSE;
        
        // how to modify plist
        switch (action_type)
        {
            case MCCMD_WRITEPLIST_MODIFY:
                [infoDic setObject:toSetObj forKey:[NSString stringWithUTF8String:szKeyName]];
                break;
                
            case MCCMD_WRITEPLIST_DELETE:
                [infoDic removeObjectForKey:[NSString stringWithUTF8String:szKeyName]];
                break;
                
            default:
                return FALSE;
        }
        
        if (![infoDic writeToFile:plistPath atomically:YES])
        {
            NSLog(@"[ERR] write plist error - %@", plistPath);
            return FALSE;
        }
    }
    
    return TRUE;
}
