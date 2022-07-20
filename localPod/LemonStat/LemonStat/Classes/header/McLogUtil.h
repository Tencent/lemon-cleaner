//
//  McLogUtil.h
//  TestFunction
//
//  Created by developer on 11-1-11.
//  Copyright 2011 Magican Software Ltd. All rights reserved.
//

#define MCLOG_ERR       0
#define MCLOG_WARN      1
#define MCLOG_INFO      2
#define MCLOG_MAX       3

// macro control
#define MCLOG_LEVEL     MCLOG_MAX
// enable log
#define MCLOG_ENABLE
// use NSLog or write to file
#define MCLOG_USENSLOG

#ifdef MCLOG_ENABLE

void McLog(uint logLevel, NSString *format, ...);

#else

#define McLog(...)

#endif // MCLOG_ENABLE
