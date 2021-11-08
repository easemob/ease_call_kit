#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <HyphenateChat/HyphenateChat.h>
#import <EaseCallKit/EaseCallUIKit.h>
#import <MBProgressHUD.h>

#define EASEMOB_APP_KEY @"easemob-demo#easeim"

#define ease_call_dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self initHypheanteSDK];
    
    NSString *userName = @"du001";
    NSString *password = @"1";

    [EMClient.sharedClient loginWithUsername:userName password:password];
    [GeneratedPluginRegistrant registerWithRegistry:self];


    return YES;
}


- (void)initHypheanteSDK {
    EMOptions *options = [EMOptions optionsWithAppkey:EASEMOB_APP_KEY];
    options.isAutoLogin = NO;
    options.enableConsoleLog = YES;
    // 为了方便演示，设置自动同意好友申请。
    options.isAutoAcceptFriendInvitation = YES;
    [EMClient.sharedClient initializeSDKWithOptions:options];
}


@end
