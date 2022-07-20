/*
 #
 # STPrivilegedTask - NSTask-like wrapper around AuthorizationExecuteWithPrivileges
 # Copyright (C) 2009-2011 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 #
 # BSD License
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #     * Redistributions of source code must retain the above copyright
 #       notice, this list of conditions and the following disclaimer.
 #     * Redistributions in binary form must reproduce the above copyright
 #       notice, this list of conditions and the following disclaimer in the
 #       documentation and/or other materials provided with the distribution.
 #     * Neither the name of Sveinbjorn Thordarson nor that of any other
 #       contributors may be used to endorse or promote products
 #       derived from this software without specific prior written permission.
 # 
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 # DISCLAIMED. IN NO EVENT SHALL  BE LIABLE FOR ANY
 # DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "STPrivilegedTask.h"
#import <stdio.h>
#import <unistd.h>
#import <dlfcn.h>

@implementation STPrivilegedTask

- (id)init
{
    if ((self = [super init])) 
    {
        launchPath = @"";
        cwd = [[NSString alloc] initWithString: [[NSFileManager defaultManager] currentDirectoryPath]];
        arguments = [[NSArray alloc] init];
        isRunning = NO;
        outputFileHandle = NULL;
        terminationStatus = 0;
    }
    return self;
}

-(id)initWithLaunchPath: (NSString *)path arguments: (NSArray *)args
{
    if ((self = [self initWithLaunchPath: path]))
    {
        [self setArguments: args];
    }
    return self;
}

-(id)initWithLaunchPath: (NSString *)path
{
    if ((self = [self init]))
    {
        [self setLaunchPath: path];
    }
    return self;
}

#pragma mark -

+(STPrivilegedTask *)launchedPrivilegedTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)args
{
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath: path arguments: args];
    int re = [task launch];
    if (re == 0)
    {
        [task waitUntilExit];
    }
    return task;
}

+(STPrivilegedTask *)launchedPrivilegedTaskWithLaunchPath:(NSString *)path
{
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath: path];
    int re = [task launch];
    if (re == 0)
    {
        [task waitUntilExit];
    }
    [task waitUntilExit];
    return task;
}

#pragma mark -

- (NSArray *)arguments
{
    return arguments;
}

- (NSString *)currentDirectoryPath;
{
    return cwd;
}

- (BOOL)isRunning
{
    return isRunning;
}

- (NSString *)launchPath
{
    return launchPath;
}

- (int)processIdentifier
{
    return pid;
}

- (int)terminationStatus
{
    return terminationStatus;
}

- (NSFileHandle *)outputFileHandle;
{
    return outputFileHandle;
}

#pragma mark -

-(void)setArguments:(NSArray *)args
{
    arguments = args;
}

-(void)setCurrentDirectoryPath:(NSString *)path
{
    cwd = path;
}

-(void)setLaunchPath:(NSString *)path
{
    launchPath = path;
}

# pragma mark -

+ (AuthorizationRef)sharedAuthorizationWithError:(OSStatus *)error;
{
    static AuthorizationRef        authorizationRef;
    if (authorizationRef == NULL)
    {
        *error = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
        if (*error != errAuthorizationSuccess)
        {
            if (authorizationRef != NULL)
            {
                AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
                authorizationRef = NULL;
            }
            return NULL;
        }
        
        AuthorizationItem       myItems = {kAuthorizationRightExecute, 0, NULL, 0};
        AuthorizationRights     myRights = {1, &myItems};
        AuthorizationFlags      flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
        *error = AuthorizationCopyRights(authorizationRef, &myRights, kAuthorizationEmptyEnvironment, flags, NULL);
        if (*error != errAuthorizationSuccess)
        {
            if (authorizationRef != NULL)
            {
                AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
                authorizationRef = NULL;
            }
            return NULL;
        }
    }
    *error = errAuthorizationSuccess;
    return authorizationRef;
}

// return 0 for success
-(int) launch
{
    unsigned long           argumentsCount = [arguments count];
    char                    *args[argumentsCount + 1];
    FILE                    *outputFile;
    
    // Create fn pointer to AuthorizationExecuteWithPrivileges in case it doesn't exist in this version of MacOS
    static OSStatus (*_AuthExecuteWithPrivsFn)(AuthorizationRef authorization,
                                               const char *pathToTool,
                                               AuthorizationFlags options,
                                               char * const *arguments,
                                               FILE **communicationsPipe) = NULL;
    if (!_AuthExecuteWithPrivsFn) {
        _AuthExecuteWithPrivsFn = dlsym(RTLD_DEFAULT, "AuthorizationExecuteWithPrivileges");
        if (!_AuthExecuteWithPrivsFn) {
            terminationStatus = STPrivilegedMethodDisabled;
            return STPrivilegedMethodDisabled;
        }
    }
    
    OSStatus error = noErr;
    AuthorizationRef authorizationRef = [self.class sharedAuthorizationWithError:&error];
    if (!authorizationRef || error != errAuthorizationSuccess)
    {
        terminationStatus = STPrivilegedAuthorizationError;
        return terminationStatus;
    }
    
    // first, construct an array of c strings from NSArray w. arguments
    for (short i = 0; i < argumentsCount; i++)
    {
        NSString *theString = [arguments objectAtIndex:i];
        const char *fileRep = [theString fileSystemRepresentation];
        size_t size = (strlen(fileRep)+1) * sizeof(char);
        
        args[i] = malloc(size);
        memset(args[i], 0, size);
        snprintf(args[i], size, "%s", fileRep);
    }
    args[argumentsCount] = NULL;
    
    // change to the current dir specified
    char *prevCwd = (char *)getcwd(nil, 0);
    chdir([cwd fileSystemRepresentation]);
    
    //use Authorization Reference to execute script with privileges
    OSStatus err = _AuthExecuteWithPrivsFn(authorizationRef, [launchPath fileSystemRepresentation], kAuthorizationFlagDefaults, args, &outputFile);
    
    // OK, now we're done executing, let's change back to old dir
    chdir(prevCwd);
    
    // free the malloc'd argument strings
    for (short i = 0; i < argumentsCount; i++)
        free(args[i]);
    
    // we return err if execution failed
    if (err != errAuthorizationSuccess) 
    {
        terminationStatus = STPrivilegedAuthorizationError;
        return terminationStatus;
    }
    
    isRunning = YES;
    // get file handle for the command output
    outputFileHandle = [[NSFileHandle alloc] initWithFileDescriptor: fileno(outputFile) closeOnDealloc: YES];
    pid = fcntl(fileno(outputFile), F_GETOWN, 0);
    
    // start monitoring task
    checkStatusTimer = [NSTimer scheduledTimerWithTimeInterval: 0.10 target: self selector:@selector(_checkTaskStatus) userInfo: nil repeats: YES];
        
    return terminationStatus;
}

- (void)terminate
{
    // This doesn't work without a PID, and we can't get one.  Stupid Security API
    /*    int ret = kill(pid, SIGKILL);
     
     if (ret != 0)
     NSLog(@"Error %d", errno);*/
}

// hang until task is done
- (void)waitUntilExit
{
    pid_t wpid = waitpid([self processIdentifier], &terminationStatus, 0);
    isRunning = NO;
    NSLog(@"waitUntilExit: %d", wpid);
}

#pragma mark -

// check if privileged task is still running
- (void)_checkTaskStatus
{    
    // see if task has terminated
    int mypid = waitpid([self processIdentifier], &terminationStatus, WNOHANG);
    if (mypid != 0)
    {
        isRunning = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: STPrivilegedTaskDidTerminateNotification object:self];
        [checkStatusTimer invalidate];
    }
}

#pragma mark -

- (NSString *)description
{
    NSArray *args = [self arguments];
    NSString *cmd = [self launchPath];
    int i;
    for (i = 0; i < [args count]; i++)
        cmd = [cmd stringByAppendingFormat: @" %@", [args objectAtIndex: i]];
    
    return [[super description] stringByAppendingFormat: @" %@", cmd];
}

@end

/*
 *
 * Add the Standard err Pipe and Pid support to AuthorizationExecuteWithPrivileges()
 * method
 *
 * @Author: Miklós Fazekas
 * Modified Aug 10 2010 by Sveinbjorn Thordarson
 *
 */


/*static OSStatus AuthorizationExecuteWithPrivilegesStdErrAndPid (
                                                                AuthorizationRef authorization,
                                                                const char *pathToTool,
                                                                AuthorizationFlags options,
                                                                char * const *arguments,
                                                                FILE **communicationsPipe,
                                                                FILE **errPipe,
                                                                pid_t* processid
                                                                )
{
    // get the Apple-approved secure temp directory
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent: TMP_STDERR_TEMPLATE];
    
    // copy it into a C string
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *stderrpath = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(stderrpath, tempFileTemplateCString);
    
    printf("%s\n", stderrpath);
    
    // this is the command, it echoes pid and directs stderr output to pipe before running the tool w. args
    const char *commandtemplate = "echo $$; \"$@\" 2>%s";
    
    if (communicationsPipe == errPipe)
        commandtemplate = "echo $$; \"$@\" 2>1";
    else if (errPipe == 0)
        commandtemplate = "echo $$; \"$@\"";
    
    char        command[1024];
    char        **args;
    OSStatus    result;
    int            argcount = 0;
    int            i;
    int            stderrfd = 0;
    FILE        *commPipe = 0;
    
    // First, create temporary file for stderr
    if (errPipe) 
    {
        // create temp file
        stderrfd = mkstemp(stderrpath);
        
        // close and remove it
        close(stderrfd); 
        unlink(stderrpath);
                
        // create a pipe on the path of the temp file
        if (mkfifo(stderrpath,S_IRWXU | S_IRWXG) != 0)
        {
            fprintf(stderr,"Error mkfifo:%d\n", errno);
            return errAuthorizationInternal;
        }
        
        if (stderrfd < 0)
            return errAuthorizationInternal;
    }
    
    // Create command to be executed
    for (argcount = 0; arguments[argcount] != 0; ++argcount) {}
    args = (char**)malloc (sizeof(char*)*(argcount + 5));
    args[0] = "-c";
    snprintf (command, sizeof (command), commandtemplate, stderrpath);
    args[1] = command;
    args[2] = "";
    args[3] = (char*)pathToTool;
    for (i = 0; i < argcount; ++i) {
        args[i+4] = arguments[i];
    }
    args[argcount+4] = 0;
    
    // for debugging: log the executed command
    printf ("Exec:\n%s", "/bin/sh"); for (i = 0; args[i] != 0; ++i) { printf (" \"%s\"", args[i]); } printf ("\n");
    
    // Execute command
    result = AuthorizationExecuteWithPrivileges(authorization, "/bin/sh",  options, args, &commPipe );
    if (result != noErr) 
    {
        unlink (stderrpath);
        return result;
    }
    
    // Read the first line of stdout => it's the pid
    {
        int stdoutfd = fileno (commPipe);
        char pidnum[1024];
        pid_t pid = 0;
        int i = 0;
        char ch = 0;
        
        while ((read(stdoutfd, &ch, sizeof(ch)) == 1) && (ch != '\n') && (i < sizeof(pidnum))) 
        {
            pidnum[i++] = ch;
        }
        pidnum[i] = 0;
        
        if (ch != '\n') 
        {
            // we shouldn't get there
            unlink (stderrpath);
            return errAuthorizationInternal;
        }
        sscanf(pidnum, "%d", &pid);
        if (processid) 
        {
            *processid = pid;
        }
        NSLog(@"Have PID %d", pid);
    }
    
    // 
    if (errPipe) {
        stderrfd = open(stderrpath, O_RDONLY, 0);
        // *errPipe = fdopen(stderrfd, "r");
         //Now it's safe to unlink the stderr file, as the opened handle will be still valid
        unlink (stderrpath);
    } else {
        unlink(stderrpath);
    }
    
    if (communicationsPipe) 
        *communicationsPipe = commPipe;
    else
        fclose (commPipe);
    
    NSLog(@"AuthExecNew function over");
    
    return noErr;
}*/