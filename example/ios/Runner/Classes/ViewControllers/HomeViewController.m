//
//  HomeViewController.m
//  EaseCallDemo
//
//  Created by 杜洁鹏 on 2021/2/19.
//

#import "HomeViewController.h"
#import <EaseCallKit/EaseCallUIKit.h>
#import <HyphenateChat/HyphenateChat.h>

#define AGORA_APP_ID @"15cb0d28b87b425ea613fc46f7c9f974"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self setupCallKitWithUid:EMClient.sharedClient.currentUsername];
}

- (void)setupCallKitWithUid:(NSString *)aUId{
    EaseCallUser* callUser = [[EaseCallUser alloc] init];
    callUser.nickName = @"du001的昵称";
    EaseCallConfig* config = [[EaseCallConfig alloc] init];
    config.users = [NSMutableDictionary dictionaryWithObject:callUser forKey:aUId];
    config.agoraAppId = AGORA_APP_ID;
    config.enableRTCTokenValidate = YES;
    //config.encoderConfiguration = [[AgoraVideoEncoderConfiguration alloc] initWithSize:AgoraVideoDimension1280x720 frameRate:AgoraVideoFrameRateFps24 bitrate:AgoraVideoBitrateStandard orientationMode:AgoraVideoOutputOrientationModeAdaptative];
    [[EaseCallManager sharedManager] initWithConfig:config delegate:self];
}


- (void)callDidEnd:(NSString * _Nonnull)aChannelName
            reason:(EaseCallEndReason)aReason
              time:(int)aTm
              type:(EaseCallType)aType {
    
}

- (void)callDidOccurError:(EaseCallError * _Nonnull)aError {
    
}

- (void)callDidReceive:(EaseCallType)aType
               inviter:(NSString * _Nonnull)user
                   ext:(NSDictionary * _Nullable)aExt {
    
}

- (void)callDidRequestRTCTokenForAppId:(NSString * _Nonnull)aAppId
                           channelName:(NSString * _Nonnull)aChannelName
                               account:(NSString * _Nonnull)aUserAccount uid:(NSInteger)aAgoraUid
{
    
    NSLog(@"%s  \naAppId:%@ \naChannelName:%@ \naUserAccount:%@  \naAgoraUid:%@",__func__,aAppId,aChannelName,aUserAccount,@(aAgoraUid));

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSString *accessUserToken = [EMClient sharedClient].accessUserToken;
    NSLog(@"accessUserToken:%@",accessUserToken);
    
    
//    NSString* strUrl = [NSString stringWithFormat:@"http://a1.easemob.com/token/rtcToken/v1?userAccount=%@&channelName=%@&appkey=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey];
    

    NSString* strUrl = [NSString stringWithFormat:@"http://a1-hsb.easemob.com/token/rtcToken/v1?userAccount=%@&channelName=%@&appkey=%@&agoraUserId=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey,aAppId];
//    NSString* strUrl = [NSString stringWithFormat:@"http://a1-hsb.easemob.com/token/rtcToken?username=%@&channelName=%@&appkey=%@&agoraUserId=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey,aAppId];

    
    NSString*utf8Url = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:utf8Url];
    NSMutableURLRequest* urlReq = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlReq setValue:[NSString stringWithFormat:@"Bearer %@",[EMClient sharedClient].accessUserToken ] forHTTPHeaderField:@"Authorization"];
  
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"%s  response:%@",__func__,response);
        
        if(data) {
            NSDictionary* body = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"%@",body);
            if(body) {
                NSString* resCode = [body objectForKey:@"code"];
                if([resCode isEqualToString:@"RES_0K"]) {
                    NSString* rtcToken = [body objectForKey:@"accessToken"];
                    NSNumber* uid = [body objectForKey:@"agoraUserId"];
                    [[EaseCallManager sharedManager] setRTCToken:rtcToken channelName:aChannelName uid:[uid integerValue]];
                }
            }
        }
        
        
    }];

    [task resume];
    
}

- (void)multiCallDidInvitingWithCurVC:(UIViewController * _Nonnull)vc
                         excludeUsers:(NSArray<NSString *> * _Nullable)users
                                  ext:(NSDictionary * _Nullable)aExt {
    
}

-(void)remoteUserDidJoinChannel:( NSString*_Nonnull)aChannelName uid:(NSInteger)aUid username:(NSString*_Nullable)aUserName
{
    // 这里设置映射表，设置头像，昵称
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];

    NSString* strUrl = [NSString stringWithFormat:@"http://a1-hsb.easemob.com/channel/mapper?userAccount=%@&channelName=%@&appkey=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey];
    NSString*utf8Url = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:utf8Url];
    NSMutableURLRequest* urlReq = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlReq setValue:[NSString stringWithFormat:@"Bearer %@",[EMClient sharedClient].accessUserToken ] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data) {
            NSDictionary* body = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"mapperBody:%@",body);
            if(body) {
                NSString* resCode = [body objectForKey:@"code"];
                if([resCode isEqualToString:@"RES_0K"]) {
                    NSString* channelName = [body objectForKey:@"channelName"];
                    NSDictionary* result = [body objectForKey:@"result"];
                    NSMutableDictionary<NSNumber*,NSString*>* users = [NSMutableDictionary dictionary];
                    for (NSString* strId in result) {
                        NSString* username = [result objectForKey:strId];
                        NSNumber* uId = [NSNumber numberWithInteger:[strId integerValue]];
                        [users setObject:username forKey:uId];
                    }
                    [[EaseCallManager sharedManager] setUsers:users channelName:channelName];
                    EaseCallUser* user = [[EaseCallUser alloc] init];
                    user.nickName = @"我的昵称";
                    user.headImage = [NSURL URLWithString:@"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image1.png"];
                    [[[EaseCallManager sharedManager] getEaseCallConfig] setUser:@"lxm" info:user];
                    EaseCallUser* user2 = [[EaseCallUser alloc] init];
                    user2.nickName = @"lxm9的昵称";
                    user2.headImage = [NSURL URLWithString:@"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image2.png"];
                    [[[EaseCallManager sharedManager] getEaseCallConfig] setUser:@"lxm9" info:user2];
                }
            }
        }
    }];

    [task resume];
}

- (void)callDidJoinChannel:(NSString*_Nonnull)aChannelName uid:(NSUInteger)aUid
{
    // 这里设置映射表，设置头像，昵称
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];

    NSString* strUrl = [NSString stringWithFormat:@"http://a1-hsb.easemob.com/channel/mapper?userAccount=%@&channelName=%@&appkey=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey];
    NSString*utf8Url = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL* url = [NSURL URLWithString:utf8Url];
    NSMutableURLRequest* urlReq = [[NSMutableURLRequest alloc] initWithURL:url];
    [urlReq setValue:[NSString stringWithFormat:@"Bearer %@",[EMClient sharedClient].accessUserToken ] forHTTPHeaderField:@"Authorization"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data) {
            NSDictionary* body = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"mapperBody:%@",body);
            if(body) {
                NSString* resCode = [body objectForKey:@"code"];
                if([resCode isEqualToString:@"RES_0K"]) {
                    NSString* channelName = [body objectForKey:@"channelName"];
                    NSDictionary* result = [body objectForKey:@"result"];
                    NSMutableDictionary<NSNumber*,NSString*>* users = [NSMutableDictionary dictionary];
                    for (NSString* strId in result) {
                        NSString* username = [result objectForKey:strId];
                        NSNumber* uId = [NSNumber numberWithInteger:[strId integerValue]];
                        [users setObject:username forKey:uId];
                    }
                    [[EaseCallManager sharedManager] setUsers:users channelName:channelName];
                    EaseCallUser* user = [[EaseCallUser alloc] init];
                    user.nickName = @"我的昵称";
                    user.headImage = [NSURL URLWithString:@"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image1.png"];
                    [[[EaseCallManager sharedManager] getEaseCallConfig] setUser:@"lxm" info:user];
                    EaseCallUser* user2 = [[EaseCallUser alloc] init];
                    user2.nickName = @"lxm9的昵称";
                    user2.headImage = [NSURL URLWithString:@"https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image2.png"];
                    [[[EaseCallManager sharedManager] getEaseCallConfig] setUser:@"lxm9" info:user2];
                }
            }
        }
    }];

    [task resume];
}

@end
