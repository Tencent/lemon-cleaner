//
//  QMUnityRepo.m
//  LemonClener
//
//  Created by watermoon on 2024/8/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

// 扫描 Unity 仓库的临时目录

#import "QMUnityScan.h"
#import "QMFilterParse.h"
#import "QMResultItem.h"
#import <Foundation/Foundation.h>
#import <Python.h>
#import <QMCoreFunction/QMShellExcuteHelper.h>
#import <QMCoreFunction/McCoreFunction.h>
#import <QMCoreFunction/NSScreen+Extension.h>

@implementation QMUnityScan
@synthesize delegate;

-(NSString*)runPyCode:(NSString*) pyCodeString {
    if ([pyCodeString length] == 0)
        NSLog(@"Empty python code");
        return NULL;
    
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

-(NSString*)runPyScript:(NSString*) pyScript {
    FILE* file = fopen([pyScript UTF8String], "r");
    if (file == NULL) {
        NSLog(@"Failed to open python script=%@", pyScript);
        return NULL;
    }

    PyObject* pGlobals = PyDict_New();
    PyObject* pLocals = PyDict_New();

    PyObject* pResult = PyRun_File(file, [pyScript UTF8String], Py_file_input, pGlobals, pLocals);
    fclose(file);

    if (pResult == NULL) { // 检查执行是否成功
        PyErr_Print();
        NSLog(@"Python script=[%@] execution failed", pyScript);
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

        NSLog(@"fileName=%@", result);
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

        [self scanPath: path actionItem: actionItem];
    }
}

-(void)scanTestFramework:(QMActionItem*)actionItem {
    
}

-(void)scanPython:(QMActionItem*)actionItem {
    Py_Initialize();
    
    NSString *pyCode = @"print(\"Hello from Python\")\nreturn 'test'";
    NSString* result = [self runPyCode: pyCode];
    if (result != NULL)
        NSLog(@"python code=%@", result);
    
    NSString *entry = @"/Users/watermoon/Documents/work/2022.unity.cn/doc/jobs/#0.20xx.moon/lemon-cleaner/py_entry.py";
    result = [self runPyScript: entry];
    if (result != NULL) {
        // 返回结果格式:
        // 1. 以 \n 分割
        // 2. 每个记录格式为 key:value 格式, key 表示 title， value 则是 path
        NSArray *resultArray = [result componentsSeparatedByString:@"\n"];
        if ((resultArray == nil) || ([resultArray count] == 0)) {
            return;
        }
        
        for (int i = 0; i < [resultArray count]; i++) {
            NSString *entry = [resultArray objectAtIndex:i];
            if ([entry length] == 0)
                continue;
            
            NSArray *kv = [result componentsSeparatedByString:@":"];
            if ((kv == nil) || ([kv count] != 2)) { // 无效记录
                return;
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
    
    Py_Finalize();
}

@end
