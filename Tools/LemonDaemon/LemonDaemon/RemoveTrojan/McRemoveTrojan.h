/*
 *  McRemoveTrojan.h
 *  TestFunction
 *
 *  
 *  Copyright 2011 Magican Software Ltd. All rights reserved.
 *
 */

// for remove trojans
BOOL fixPlistFile(const char *szPath, const char *szKeyToRemove);

int systemCommand(const char *szCmd);

BOOL writePlistFile(const char *szPath,
                    const char *szKeyName,
                    int action_type,
                    int plist_type,
                    int obj_type,
                    unsigned char *obj_data,
                    int obj_size);
