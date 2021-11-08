#import "EaseCallKitPlugin.h"
#import <HyphenateChat/HyphenateChat.h>

#define ease_call_dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}


@interface EaseCallKitPlugin()<EaseCallDelegate>
@property (nonatomic, strong) FlutterMethodChannel* channel;
@end

@implementation EaseCallKitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"ease_call_kit"
                                     binaryMessenger:[registrar messenger]];
    EaseCallKitPlugin* instance = [[EaseCallKitPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"initCallKit" isEqualToString:call.method]) {
        [self initCallKit:call.arguments result:result];
    } else if ([@"startSingleCall" isEqualToString:call.method]) {
        [self startSingleCall:call.arguments result:result];
    } else if ([@"startInviteUsers" isEqualToString:call.method]) {
        [self startInviteUsers:call.arguments result:result];
    } else if ([@"getEaseCallConfig" isEqualToString:call.method]) {
        [self getEaseCallConfig:call.arguments result:result];
    } else if ([@"setRTCToken" isEqualToString:call.method]) {
        [self setRTCToken:call.arguments result:result];
    }else if ([@"setUsersMapper" isEqualToString:call.method]){
        [self setUsersMapper:call.arguments result:result];
    }else if ([@"setUserInfoMapper" isEqualToString:call.method]){
        [self setUsersMapper:call.arguments result:result];
    }else if ([@"getTestUserToken" isEqualToString:call.method]){
        if (EMClient.sharedClient.accessUserToken.length > 0) {
            result(EMClient.sharedClient.accessUserToken);
        }else {
            result(nil);
        }
    }else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)initCallKit:(NSDictionary *)dict result:(FlutterResult)result{
    EaseCallConfig *config = [EaseCallConfig fromJson:dict];
    [[EaseCallManager sharedManager] initWithConfig:config delegate:self];
    result(nil);
}

- (void)startSingleCall:(NSDictionary *)dict result:(FlutterResult)result{
    
    EaseCallType type = [dict[@"call_type"] intValue] == 0 ? EaseCallType1v1Audio : EaseCallType1v1Video;
    NSString *emId = dict[@"em_id"];
    NSDictionary *ext = dict[@"ext"];
    
    [[EaseCallManager sharedManager] startSingleCallWithUId:emId
                                                       type:type
                                                        ext:ext
                                                 completion:^(NSString * _Nonnull callId, EaseCallError * error)
     {
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        if (error) {
            ret[@"error"] = [error toJson];
        }
        ret[@"call_id"] = callId;
        ease_call_dispatch_main_async_safe(^(){
            result(ret);
        });
    }];
}

- (void)startInviteUsers:(NSDictionary *)dict result:(FlutterResult)result{
    NSArray *users = dict[@"users"];
    NSDictionary *ext = dict[@"ext"];
    [EaseCallManager.sharedManager startInviteUsers:users
                                                ext:ext
                                         completion:^(NSString * _Nullable callId, EaseCallError * _Nullable aError)
     {
        NSMutableDictionary *ret = [NSMutableDictionary dictionary];
        if (aError) {
            ret[@"error"] = [aError toJson];
        }
        ease_call_dispatch_main_async_safe(^(){
            result(ret);
        });
    }];
}

- (void)getEaseCallConfig:(NSDictionary *)dict result:(FlutterResult)result{
    EaseCallConfig *config = EaseCallManager.sharedManager.getEaseCallConfig;
    ease_call_dispatch_main_async_safe(^(){
        result([config toJson]);
    });
}

- (void)setRTCToken:(NSDictionary *)dict result:(FlutterResult)result {
    NSString *rtcToken = dict[@"rtc_token"];
    NSString *channelName = dict[@"channel_name"];
    NSInteger uid = [dict[@"uid"] intValue];
    [EaseCallManager.sharedManager setRTCToken:rtcToken channelName:channelName uid:uid];
    ease_call_dispatch_main_async_safe(^(){
        result(nil);
    });
}


- (void)setUsersMapper:(NSDictionary *)dict result:(FlutterResult)result {
    NSDictionary *userMap = dict[@"map"];
    NSString *channelName = dict[@"channel_name"];
    [EaseCallManager.sharedManager setUsers:userMap channelName:channelName];
    ease_call_dispatch_main_async_safe(^(){
        result(nil);
    });
}

- (void)setUserInfoMapper:(NSDictionary *)dict result:(FlutterResult)result {
    EaseCallConfig *config =  EaseCallManager.sharedManager.getEaseCallConfig;
    if(config != nil) {
        NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
        NSArray *usersList = dict[@"user_map"];
        for (NSDictionary *userDict in usersList) {
            NSString *key = userDict[@"key"];
            NSDictionary *value = userDict[@"value"];
            usersDict[key] = [EaseCallUser fromJson:value];
        }
        config.users = usersDict;
    }
    ease_call_dispatch_main_async_safe(^(){
        result(nil);
    });
}

#pragma mark - EaseCallDelegate
- (void)callDidEnd:(NSString * _Nonnull)aChannelName
            reason:(EaseCallEndReason)aReason
              time:(int)aTm
              type:(EaseCallType)aType
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"channel_name"] = aChannelName;
    dict[@"time"] = @(aTm);
    dict[@"call_type"] = @([self callTypeToInt:aType]);
    dict[@"reason"] = @([self reasonToInt:aReason]);
    [self.channel invokeMethod:@"callDidEnd" arguments:dict];
}

- (void)callDidOccurError:(EaseCallError * _Nonnull)aError
{
    [self.channel invokeMethod:@"callDidOccurError" arguments:[self errorToDict:aError]];
}

- (void)callDidReceive:(EaseCallType)aType
               inviter:(NSString * _Nonnull)user
                   ext:(NSDictionary * _Nullable)aExt
{
    NSMutableDictionary *arg = [NSMutableDictionary dictionary];
    arg[@"call_type"] = @([self callTypeToInt:aType]);
    arg[@"inviter"] = user;
    arg[@"ext"] = aExt;
    
    [self.channel invokeMethod:@"callDidReceive" arguments:arg];
}


- (void)multiCallDidInvitingWithCurVC:(UIViewController * _Nonnull)vc
                         excludeUsers:(NSArray<NSString *> * _Nullable)users
                                  ext:(NSDictionary * _Nullable)aExt
{
    NSMutableDictionary *arg = [NSMutableDictionary dictionary];
    arg[@"exclude_users"] = users;
    arg[@"ext"] = aExt;
    [self.channel invokeMethod:@"multiCallDidInviting" arguments:arg];
}

- (void)callDidRequestRTCTokenForAppId:(NSString * _Nonnull)aAppId
                           channelName:(NSString * _Nonnull)aChannelName
                               account:(NSString * _Nonnull)aUserAccount
                                   uid:(NSInteger)aAgoraUid {
    NSMutableDictionary *arg = [NSMutableDictionary dictionary];
    arg[@"app_id"] = aAppId;
    arg[@"channel_name"] = aChannelName;
    arg[@"account"] = aUserAccount;
    arg[@"agora_uid"] = @(aAgoraUid);
    
    [self.channel invokeMethod:@"callDidRequestRTCToken" arguments:arg];
}

- (void)remoteUserDidJoinChannel:(NSString *)aChannelName uid:(NSInteger)aAgoraUid username:(NSString *)aUserName {
    NSMutableDictionary *arg = [NSMutableDictionary dictionary];
    arg[@"channel_name"] = aChannelName;
    arg[@"account"] = aUserName;
    arg[@"agora_uid"] = @(aAgoraUid);
    
    [self.channel invokeMethod:@"remoteUserDidJoinChannel" arguments:arg];
}

- (void)callDidJoinChannel:(NSString * _Nonnull)aChannelName uid:(NSUInteger)aAgoraUid {
    NSMutableDictionary *arg = [NSMutableDictionary dictionary];
    arg[@"channel_name"] = aChannelName;
    arg[@"agora_uid"] = @(aAgoraUid);
    [self.channel invokeMethod:@"callDidJoinChannel" arguments:arg];
}



//
//
//- (void)setUserWithUserName:(NSString *)userName completion:(void (^)(void))completion {
//    [[EMClient sharedClient].userInfoManager fetchUserInfoById:@[userName] completion:^(NSDictionary *aUserDatas, EMError *aError) {
//        EMUserInfo* info = aUserDatas[userName];
//        if(info) {
//            EaseCallUser* user = [EaseCallUser userWithNickName:info.nickName image:[NSURL URLWithString:info.avatarUrl]];
//
//            ease_call_dispatch_main_async_safe(^(){
//                [[[EaseCallManager sharedManager] getEaseCallConfig] setUser:userName info:user];
//                if (completion) {
//                    completion();
//                }
//            });
//
//        }
//    }];
//}
//
//- (void)fetchUserMapsFromServerWithChannelName:(NSString*)aChannelName
//{
//    // 这里设置映射表，设置头像，昵称
//    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
//                                                          delegate:nil
//                                                     delegateQueue:[NSOperationQueue mainQueue]];
//
//    NSString* strUrl = [NSString stringWithFormat:@"http://a1.easemob.com/channel/mapper?userAccount=%@&channelName=%@&appkey=%@",[EMClient sharedClient].currentUsername,aChannelName,[EMClient sharedClient].options.appkey];
//    NSString*utf8Url = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
//    NSURL* url = [NSURL URLWithString:utf8Url];
//    NSMutableURLRequest* urlReq = [[NSMutableURLRequest alloc] initWithURL:url];
//    [urlReq setValue:[NSString stringWithFormat:@"Bearer %@",[EMClient sharedClient].accessUserToken ] forHTTPHeaderField:@"Authorization"];
//    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if(data) {
//            NSDictionary* body = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
//            NSLog(@"%s mapperBody:%@",__func__,body);
//
//            if(body) {
//                NSString* resCode = [body objectForKey:@"code"];
//                if([resCode isEqualToString:@"RES_0K"]) {
//                    NSString* channelName = [body objectForKey:@"channelName"];
//                    NSDictionary* result = [body objectForKey:@"result"];
//                    NSMutableDictionary<NSNumber*,NSString*>* users = [NSMutableDictionary dictionary];
//                    for (NSString* strId in result) {
//                        NSString* username = [result objectForKey:strId];
//                        NSNumber* uId = [NSNumber numberWithInteger:[strId integerValue]];
//                        [users setObject:username forKey:uId];
//                        [self setUserWithUserName:username completion:nil];
//                    }
//                    [[EaseCallManager sharedManager] setUsers:users channelName:channelName];
//                }
//            }
//        }
//    }];
//
//    [task resume];
//}


#pragma mark private method

- (int)callTypeToInt:(EaseCallType)aType {
    int type = 0;
    switch (aType) {
        case EaseCallType1v1Audio:
            type = 1;
            break;
        case EaseCallType1v1Video:
            type = 1;
            break;
        case EaseCallTypeMulti:
            type = 1;
            break;
        default:
            break;
    }
    return type;
}

- (int)reasonToInt:(EaseCallEndReason)aReason{
    int reason = 0;
    switch (aReason) {
        case EaseCallEndReasonHangup:
            reason = 1;
            break;
            
        case EaseCallEndReasonCancel:
            reason = 2;
            break;
            
        case EaseCallEndReasonRemoteCancel:
            reason = 3;
            break;
            
        case EaseCallEndReasonRefuse:
            reason = 4;
            break;
            
        case EaseCallEndReasonBusy:
            reason = 5;
            break;
            
        case EaseCallEndReasonNoResponse:
            reason = 6;
            break;
            
        case EaseCallEndReasonRemoteNoResponse:
            reason = 7;
            break;
            
        case EaseCallEndReasonHandleOnOtherDevice:
            reason = 8;
            break;
            
        default:
            break;
    }
    
    return reason;
}

- (NSDictionary *)errorToDict:(EaseCallError *)aError{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if (aError.aErrorType == EaseCallErrorTypeProcess) {
        ret[@"err_type"] = @(1);
    }else if (aError.aErrorType == EaseCallErrorTypeRTC) {
        ret[@"err_type"] = @(2);
    }else {
        ret[@"err_type"] = @(3);
    }
    
    ret[@"err_code"] = @(aError.errCode);
    ret[@"err_desc"] = aError.errDescription;
    
    return ret;
}


@end

@implementation EaseCallError (Flutter)
- (NSDictionary *)toJson {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"err_code"] = @(self.errCode);
    ret[@"err_desc"] = self.errDescription;
    ret[@"err_type"] = ({
        int type = 0;
        if (self.aErrorType == EaseCallErrorTypeProcess) {
            type = 1;
        }else if(self.aErrorType == EaseCallErrorTypeRTC){
            type = 2;
        }else if(self.aErrorType == EaseCallErrorTypeIM){
            type = 3;
        }
        @(type);
    });
    return ret;
}
@end


@implementation EaseCallConfig (Flutter)

+ (EaseCallConfig *)fromJson:(NSDictionary *)dict {
    EaseCallConfig *config = [[EaseCallConfig alloc] init];
    config.agoraAppId = dict[@"agora_app_id"];
    config.defaultHeadImage = dict[@"default_head_image_url"];
    if ([dict[@"call_timeout"] intValue] > 0) {
        config.callTimeOut = [dict[@"call_timeout"] intValue];
    }
    
    NSString *ringFileURL = dict[@"ring_file_url"];
    if (ringFileURL.length > 0) {
        config.ringFileUrl = [NSURL URLWithString:ringFileURL];
    }
    
    config.enableRTCTokenValidate = [dict[@"enable_rtc_token_validate"] boolValue];
    
    NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
    NSArray *usersList = dict[@"user_map"];
    for (NSDictionary *userDict in usersList) {
        NSString *key = userDict[@"key"];
        NSDictionary *value = userDict[@"value"];
        usersDict[key] = [EaseCallUser fromJson:value];
    }
    config.users = usersDict;
    return config;
}

- (NSDictionary *)toJson {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"agora_app_id"] = self.agoraAppId;
    ret[@"default_head_image_url"] = self.defaultHeadImage;
    ret[@"call_timeout"] = @(self.callTimeOut);
    ret[@"ring_file_url"] = self.ringFileUrl;
    ret[@"enable_rtc_token_validate"] = @(self.enableRTCTokenValidate);
    NSMutableDictionary *usersDict = [NSMutableDictionary dictionary];
    for (NSString *key in self.users.allKeys) {
        EaseCallUser *user = usersDict[key];
        usersDict[key] = [user toJson];
    }
    ret[@"user_map"] = usersDict;
    return ret;
}
@end

@implementation EaseCallUser (Flutter)

+ (EaseCallUser *)fromJson:(NSDictionary *)dict {
    EaseCallUser *user = [[EaseCallUser alloc] init];
    NSString *avatarStr = dict[@"avatar_url"];
    if (avatarStr) {
        user.headImage = [NSURL URLWithString:avatarStr];
    }
    NSString *nickname = dict[@"nickname"];
    if (nickname) {
        user.nickName = nickname;
    }
    
    return user;
}

- (NSDictionary *)toJson {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"avatar_url"] = self.headImage.absoluteString;
    ret[@"nickname"] = self.nickName;
    return ret;
}

@end

