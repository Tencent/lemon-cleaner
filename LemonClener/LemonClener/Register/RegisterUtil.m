//
//  RegisterUtil.m
//  Lemon
//

//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "RegisterUtil.h"
#import <QMCoreFunction/QMEnvironmentInfo.h>
#import <QMCoreFunction/CCMBase64.h>
#import <QMCoreFunction/CCMKeyLoader.h>
#import <QMCoreFunction/CCMCryptor.h>
#import <QMCoreFunction/LMKeychain.h>

NSString* KEY_REGISTER_TOKEN = @"key_register_token";

@implementation RegisterUtil


+ (NSString *)getRegisterTokenAtLocal{
    
//    LMGenericKeychainItem *keychainItem = [LMGenericKeychainItem genericKeychainItemForService:@"lemon.store.com" withUsername:@"lemon_register"];
//    if (keychainItem) {
//        NSString *psd = [keychainItem password];
//    }
    
//    注册相关信息使用 UserDefault 去管理的, 内容保存在~/Library/Preferences/com.tencent.Lemon.plist. 系统会启动一个进程 读取这个文件的信息并缓存在内存中.
//    只是删除plist文件不会立即重置内存中的数据. 所以读取数据时即使plist文件被删除了,有可能仍然可以拿到数据.
//    过一段时间   或者   重启机器   或者  利用命令 killall cfprefsd 重启下cfprefsd, UserDefault就会重新读取数据.
    
    
    
    
    // fix bug: 卸载Lemon后(会顺带删除plist文件),立刻重新安装后NSUserDefaults 可以读取到数据,然后一段时间后再运行发现不能读取数据了, 造成激活失败的问题.
//    NSString *plistPath =  [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.tencent.Lemon.plist"];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    BOOL isExist = [fileManager fileExistsAtPath:plistPath];
//    if(!isExist){
//        NSLog(@"getRegisterTokenAtLocal : com.tencent.Lemon.plist not exist");
//        return nil;
//    }
    
    // 判断plist 文件不保险.
    // 1. xcode直接运行工程(release模式) 发现com.tencent.Lemon.plist文件并未生成.(数据存在其他地方了)
    // 2. 线上环境 在卸载完再立即重装的情况下, 如果在调用这个接口前有用NSUserDefaults 存储数据的操作, 那么plist会整个还原回来.(相当于cfprefsd进程将内存cache整个还原回去)
    
    
    [[NSUserDefaults standardUserDefaults] synchronize]; //synchronize 无效
    NSString* token = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_REGISTER_TOKEN];
    return token;
}

+ (void)storeRegisteTokenAtLocal:(NSString *)token{
//       [LMGenericKeychainItem addGenericKeychainItemForService:@"lemon.store.com" withUsername:@"lemon_register" password:output];
    [[NSUserDefaults standardUserDefaults]setObject:token forKey:KEY_REGISTER_TOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)cryptoNetworkToken:(NSString *)token{
    if(!token){
        NSLog(@"cryptoNetworkToken token is nil");
        return nil;
    }
    
    NSString *publicKey = @"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDZ3TspJBCA1TsQgvlpu5NVa0UJ\nV/E1zdoBtu6MeEUf1Y0zkPkW08dyIjqo2GXlTM+hv34riz+qpc0b8tiSCWm1fxkx\n0eFh/UFtZsUPENLJFtHEmW4q1gwnW4GeZRlGMx3CmJRqG8+n+dz1L0gksGBnxVMw\njBbBqeG53nhf2rTxMwIDAQAB\n-----END PUBLIC KEY-----";
    NSData *inputData = [CCMBase64 dataFromBase64String:token];
    if (inputData == nil) {
        NSLog(@"cryptoNetworkToken inputData is nil");
        return nil;
    }
    CCMKeyLoader *keyLoader = [[CCMKeyLoader alloc] init];
    CCMPublicKey *key = [keyLoader loadX509PEMPublicKey:publicKey];
    if (key == nil) {
        NSLog(@"cryptoNetworkToken key is nil");
        return nil;
    }
    NSError *cryptError;
    CCMCryptor *cryptor = [[CCMCryptor alloc] init];
    NSData *decryptedData = [cryptor decryptData:inputData
                                   withPublicKey:key
                                           error:&cryptError];
    return [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
}


+(BOOL)equalToOrigin:(NSString *)cryptoToken{
    NSString *originMd5 = [[[QMEnvironmentInfo machineModel] stringByAppendingString:@"|"] stringByAppendingString:[QMEnvironmentInfo deviceSerialNumberMD5]];
    if(cryptoToken && [cryptoToken isEqualToString: originMd5]){
        return YES;
    }
    
    return FALSE;
}
@end
