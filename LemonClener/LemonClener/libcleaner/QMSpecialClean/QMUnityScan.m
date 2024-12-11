//
//  QMUnityRepo.m
//  LemonClener
//
//  Created by watermoon on 2024/8/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

// 扫描 Unity 仓库的临时目录

#import "QMUnityScan.h"
#import "QMCleanUtils.h"
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import <Foundation/Foundation.h>
#import "Python.h"
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/NSScreen+Extension.h>

@implementation QMUnityScan
@synthesize delegate;

-(bool)initPythonEnv:(NSString*) scanResultFile paths:(NSString*) paths{
    NSString* pythonHome = [QMCleanUtils getPythonHome];

    if (pythonHome == nil || [pythonHome length] == 0) {
        NSLog(@"Python home NOT configured or empty.");
        return false;
    }
    NSString* pythonLib = [NSString stringWithFormat:@"%@/LIB", pythonHome];

    PyStatus status;
    
    PyConfig config;
    PyConfig_InitPythonConfig(&config);
    config.isolated = 1;
    config.module_search_paths_set = 1;
    do {
        // 设置 Python home & module search path
        status = PyConfig_SetBytesString(&config, &config.home, [pythonHome UTF8String]);
        if (PyStatus_Exception(status)) {
            break;
        }
        status = PyConfig_SetBytesString(&config, &config.pythonpath_env, [pythonLib UTF8String]); // 这一行不是必须的, 只是为了将 NSString 转成 wchar_t*
        if (PyStatus_Exception(status)) {
            break;
        }
        status = PyWideStringList_Append(&config.module_search_paths, config.pythonpath_env);
        if (PyStatus_Exception(status)) {
            break;
        }

        // 设置 argc 和 argv
        // 注意: python 脚本中 argv[0] 是在 __name__ 获取
        char *resultFilePath = (char*)[scanResultFile UTF8String];
        char *pathsStr = (char*)[paths UTF8String];
        char* argv[] = {
            "",
            resultFilePath,
            pathsStr,
        };

        status = PyConfig_SetBytesArgv(&config, 3, argv); // 3: argv 数组的长度, 对应 main(int argc, char** argv)
        if (PyStatus_Exception(status)) {
            break;
        }

        status = Py_InitializeFromConfig(&config);
        if (PyStatus_Exception(status)) {
            break;
        }
    } while (0);

    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        if (PyStatus_IsExit(status)) {
            NSLog(@"Python exits. err=%s", status.err_msg);
            return false;
        }
        // Display the error message and exit the process with non-zero exit code
        NSLog(@"Python exits with code=%d err_msg=%s", status.exitcode, status.err_msg);
        Py_ExitStatusException(status);
    }

    return true;
}

-(NSString*)runPyCode:(NSString*) pyCodeString {
    NSLog(@"python code=%@", pyCodeString);
    uint64_t size = [pyCodeString length];
    if (pyCodeString == nil || size == 0) {
        NSLog(@"Empty python code");
        return NULL;
    }
    
    PyObject* pGlobals = PyDict_New();
    PyObject* pLocals = PyDict_New();

    PyObject* pResult = PyRun_String([pyCodeString UTF8String], Py_file_input, pGlobals, pLocals);
    if (pResult == NULL) { // 检查执行是否成功
        PyErr_Print();
        NSLog(@"Python code=[%@] execution failed", pyCodeString);
        return NULL;
    }

    PyObject *pStr = PyObject_Str(pResult);
    const char* cStr = PyUnicode_AsUTF8(pStr);
    
    // 释放资源
    Py_XDECREF(pGlobals);
    Py_XDECREF(pLocals);
    Py_XDECREF(pResult);
    Py_XDECREF(pStr);
    
    return [NSString stringWithUTF8String:cStr];
}

-(wchar_t**)ConvertNSArrayToWchart:(NSArray*) strArray {
    wchar_t** wcharArray = malloc(strArray.count * sizeof(wchar_t*));
    
    for (NSUInteger i = 0; i < strArray.count; i++)
    {
        NSString *string = strArray[i];
        const wchar_t* wcharStr = (const wchar_t*)[string cStringUsingEncoding:NSUTF32StringEncoding];
        size_t len = wcslen(wcharStr);
        wcharArray[i] = malloc(len * sizeof(wchar_t));
        wcscpy(wcharArray[i], wcharStr);
    }
    
    return wcharArray;
}

-(void)freeWcharTArray:(wchar_t**) argv argc:(int) argc {
    if (argv != NULL && argc > 0)
    {
        for (NSUInteger i = 0; i < argc; i++)
        {
            free(argv[i]);
        }
        free(argv);
        argv = NULL;
        argc = 0;
    }
}

-(bool)runPyScript:(NSString*) pyScript {
    FILE* file = fopen([pyScript UTF8String], "r");
    if (file == NULL) {
        NSLog(@"Failed to open python script=%@", pyScript);
        return false;
    }

//    PySys_SetArgv(argc, argv);
    int ret = PyRun_SimpleFile(file, [pyScript UTF8String]);
    if (0 == ret) {
        NSLog(@"python 扫描完成...");
    } else {
        NSLog(@"python 扫描失败, 具体原因请查看日志");
    }
    
    fclose(file);
    return true;
}

-(void)scanArtifacts:(QMActionItem *)actionItem {
}

-(void)scanBuilds:(QMActionItem *)actionItem {
    
}

-(void)scanStevedore:(QMActionItem *)actionItem {
}

-(void)scanPath:(NSString *) path actionItem:(QMActionItem *)actionItem {
    NSString *shellString = [NSString stringWithFormat:@"mdfind -onlyin %@ kind:folders | egrep \"/Logs$|/Library$\|/obj$|/build$|/Build$\"", path];
    NSString *retString = [QMShellExcuteHelper excuteCmd:shellString];
    if (retString == nil || [retString isEqual:@""])
        return;

    NSArray *pathItemArray = [retString componentsSeparatedByString:@"\n"];
    if ((pathItemArray == nil) || ([pathItemArray count] == 0)) {
        return;
    }

    uint64_t size = [path length];
    NSString *projFolder = [path lastPathComponent];
    for (int i = 0; i < [pathItemArray count]; i++) {
        NSString *result = [pathItemArray objectAtIndex:i];
        if ([result length] == 0)
            continue;

        NSRange range = [result rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.location == NSNotFound)
            continue;
        if (range.location != size)
            continue;

//        NSLog(@"fileName=%@", result);
        QMResultItem *resultItem = [[QMResultItem alloc] initWithPath: result];
        NSString *foler = [result lastPathComponent];
        resultItem.title = [NSString stringWithFormat:@"%@/%@", projFolder, foler];
        resultItem.cleanType = actionItem.cleanType;

        // 添加结果
        if (resultItem)
            [resultItem addResultWithPath:result];
        if ([resultItem resultFileSize] == 0) {
            // NSLOG
            resultItem = nil;
        }
        if ([delegate scanProgressInfo:(i+1.0) / [pathItemArray count] scanPath: result resultItem:resultItem])
            break;
    }
}

-(void)scanProj:(QMActionItem *)actionItem {
    NSLog(@"scanning unity project...\n");
    QMFilterParse * filterParse = [[QMFilterParse alloc] initFilterDict:[delegate xmlFilterDict]];
    NSArray * pathArray = [filterParse enumeratorAtFilePath:actionItem];//通过扫描规则和过滤规则，返回所有路径

    for (int i = 0; i < [pathArray count]; i++) {
        NSString *path = [pathArray objectAtIndex:i];

        //NSLog(@"scanning index=%d path=%@\n", i, path);
        [self scanPath: path actionItem: actionItem];
    }
}

-(void)scanTestFramework:(QMActionItem*)actionItem {
    
}

-(NSString*)PathItem2NSString:(QMActionPathItem*)pathItem {
    if (pathItem == NULL)
        return NULL;
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    if (pathItem.filename != NULL)
        [result addObject:pathItem.filename];
    else
        [result addObject:@""];
    [result addObject: [NSString stringWithFormat:@"%d", pathItem.level]];
    if (pathItem.type != NULL)
        [result addObject:pathItem.type];
    else
        [result addObject:@""];
    if (pathItem.value != NULL)
        [result addObject:pathItem.value];
    else
        [result addObject:@""];
    if (pathItem.value1 != NULL)
        [result addObject:pathItem.value1];
    else
        [result addObject:@""];
    if (pathItem.scanFilters != NULL)
        [result addObject:pathItem.scanFilters];
    else
        [result addObject:@""];
    
    return [result componentsJoinedByString:@"|"];
}

-(NSMutableArray<NSString *> *)getPathArray:(QMActionItem*)actionItem {
    NSMutableArray<NSString *> *stringArray = [NSMutableArray array];
    
    NSArray* pathArray = actionItem.pathItemArray;
    if (pathArray == NULL)
        return stringArray;

    for (int i = 0; i < [pathArray count]; i++) {
        QMActionPathItem *pathItem = [pathArray objectAtIndex:i];
        NSString* path = [self PathItem2NSString: pathItem];
        if (path != NULL)
            [stringArray addObject:path];
    }
    
    return stringArray;
}

-(void)scanPython:(QMActionItem*)actionItem {
    NSString* scanResultFile = [QMCleanUtils getScanResultFile];
    NSMutableArray<NSString*>* pathArray = [self getPathArray: actionItem];
    if (![self initPythonEnv: scanResultFile paths:[pathArray componentsJoinedByString:@","]]) {
        NSLog(@"Python entry NOT configured or empty.");
        return;
    }
    
    NSString *entry = [QMCleanUtils getPythonScriptEntry];
    if (entry == nil || [entry length] == 0) {
        NSLog(@"Python entry NOT configured or empty.");
        Py_Finalize();
        return;
    }


    bool succ = [self runPyScript: entry];
    Py_Finalize();

    if (succ) {
        NSError *error = nil;
        NSString *fileContents = [NSString stringWithContentsOfFile:scanResultFile
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
        if (error) {
            NSLog(@"Error reading file at %@: %@", scanResultFile, error.localizedDescription);
            return;
        }

        // 返回结果格式:
        // 1. 以 \n 分割
        // 2. 每个记录格式为 key:value 格式, key 表示 title， value 则是 path
        NSArray *resultArray = [fileContents componentsSeparatedByString:@"\n"];
        if ((resultArray == nil) || ([resultArray count] == 0)) {
            return;
        }
        
        for (int i = 0; i < [resultArray count]; i++) {
            NSString *entry = [resultArray objectAtIndex:i];
            if ([entry length] == 0)
                continue;
            
            NSArray *kv = [entry componentsSeparatedByString:@":"];
            if ((kv == nil) || ([kv count] != 2)) { // 无效记录
                continue;
            }

            NSString *path = [kv objectAtIndex:1];
            QMResultItem *resultItem = [[QMResultItem alloc] initWithPath: path];
            resultItem.title = [kv objectAtIndex:0];
            resultItem.cleanType = actionItem.cleanType;

            // 添加结果
            if (resultItem)
                [resultItem addResultWithPath:path];
            if ([resultItem resultFileSize] == 0) {
                // NSLOG
                resultItem = nil;
            }
            if ([delegate scanProgressInfo:(i+1.0) / [resultArray count] scanPath: path resultItem:resultItem])
                break;
        }
    }
}

@end
