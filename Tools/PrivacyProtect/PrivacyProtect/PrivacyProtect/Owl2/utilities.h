//
//  file: utilities.h
//  project: OverSight (shared)
//  description: various helper/utility functions (header)
//
//  created by Patrick Wardle
//  copyright (c) 2017 Objective-See. All rights reserved.
//

#ifndef Utilities_h
#define Utilities_h

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

/* FUNCTIONS */

//give path to app
// get full path to its binary
NSString* getAppBinary(NSString* appPath);

//given an app binary
// try get app's bundle
NSBundle* getAppBundle(NSString* binaryPath);

//get path to (main) app
// login item is in app bundle, so parse up to get main app
NSString* getMainAppPath(void);

//get app's version
// ->extracted from Info.plist
NSString* getAppVersion(void);

//get (true) parent
NSDictionary* getRealParent(pid_t pid);


//extract value from plist
// takes optional wait time...
id getValueFromPlist(NSString* plistFile, NSString* key, BOOL insensitive, float maxWait);

//find 'top-level' app of binary
// useful to determine if binary (or other app) is embedded in a 'parent' app bundle
NSString* topLevelApp(NSString* binaryPath);

//verify that an app bundle is
// a) signed
// b) signed with signing auth
OSStatus verifyApp(NSString* path, NSString* signingAuth);

//get name of logged in user
NSString* getConsoleUser(void);

//check if process is alive
BOOL isProcessAlive(pid_t processID);

//set dir's|file's group/owner
BOOL setFileOwner(NSString* path, NSNumber* groupID, NSNumber* ownerID, BOOL recursive);

//set permissions for file
BOOL setFilePermissions(NSString* file, int permissions, BOOL recursive);

//given a path to binary
// parse it back up to find app's bundle
NSBundle* findAppBundle(NSString* binaryPath);

//get process's path
NSString* getProcessPath(pid_t pid);

//get process name
// either via app bundle, or path
NSString* getProcessName(NSString* path);

//given a process path and user
// return array of all matching pids
NSMutableArray* getProcessIDs(NSString* processPath, int userID);

//given a pid, get its parent (ppid)
pid_t getParentID(int pid);

//figure out binary's name
// either via app bundle, or from path
NSString* getBinaryName(NSString* path);

//enable/disable a menu
void toggleMenu(NSMenu* menu, BOOL shouldEnable);

//toggle login item
// either add (install) or remove (uninstall)
BOOL toggleLoginItem(NSURL* loginItem, int toggleFlag);

//get an icon for a process
// for apps, this will be app's icon, otherwise just a standard system one
NSImage* getIconForProcess(NSString* path);

//wait until a window is non nil
// then make it modal
void makeModal(NSWindowController* windowController);

//find a process by name
pid_t findProcess(NSString* processName);

//hash a file (sha256)
NSMutableString* hashFile(NSString* filePath);

//exec a process with args
// if 'shouldWait' is set, wait and return stdout/in and termination status
NSMutableDictionary* execTask(NSString* binaryPath, NSArray* arguments, BOOL shouldWait, BOOL grabOutput);

//loads a framework
// note: assumes is in 'Framework' dir
NSBundle* loadFramework(NSString* name);

//in dark mode?
BOOL isDarkMode(void);

//check if a file is restricted (SIP)
BOOL isFileRestricted(NSString* file);

//check if something is nil
// if so, return a default ('unknown') value
NSString* valueForStringItem(NSString* item);

//determine if path is translocated
// thanks: http://lapcatsoftware.com/articles/detect-app-translocation.html
BOOL isTranslocated(NSString* path);

//running on M1?
BOOL AppleSilicon(void);

//show an alert
NSModalResponse showAlert(NSString* messageText, NSString* informativeText);

BOOL hasAdminPrivileges(void);

#endif
