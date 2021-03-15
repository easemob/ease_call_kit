# 环信ease call kit

`ease_call_kit`是针对环信`EaseCallKit`的封装。

> EaseCallKit是一套基于环信IM和声网音视频结合开发的音视频UI库，实现了1v1语音通话、视频通话，以及多人音视频通话的功能， EaseCallKit可以快速实现一些通用的音视频功能。

文章主要讲解环信`ease_call_kit`如何使用。

[环信官网](https://www.easemob.com/)

[环信iOS EaseCallKit集成文档](http://docs-im.easemob.com/im/ios/other/easecallkit)

[环信Android EaseCallKit集成文档](http://docs-im.easemob.com/im/android/other/easecallkit)


### 前期准备

在集成该库前，你需要满足以下条件：

* 你已分别创建了环信应用及声网应用；
* 已完成环信IM的基本功能，包括登录、好友、群组以及会话等的集成；
* 上线之前开通声网token验证时，用户需要实现自己的AppServer''，根据环信ID,生成Token，创建Token服务及使用AppServer生成Token的过程参见[声网文档](https://docs.agora.io/cn/live-streaming/token_server)


### 导入UI库

```
dependencies:
  im_flutter_sdk:  
    git:  
      url: https://github.com/dujiepeng/ease_call_kit.git 
      ref: main
```


### 导入头文件

```
import 'package:ease_call_kit/ease_call_kit.dart';
```

### 初始化

```
EaseCallKit.initWithConfig(EaseCallConfig(AgoraAppId));
```
__AgoraAppId__ 您声网的App ID,如果没有，需要您去注册声网并在[项目管理](https://console.agora.io/projects)中添加。
> 初始化前，需要您成功登陆环信，建议您把初始化ease call kit写在主页面。

### 呼叫

#### 1v1  

```
// callType: 呼叫类型，有`SingeAudio`和`SingeVideo`两种
EaseCallKit.startSingleCall('du002', callType: EaseCallType.SingeVideo);
```

#### 多人  

```
EaseCallKit.startInviteUsers(['du001', 'du002']);
```

### 监听事件

```
class _MyAppState extends State<MyApp> with EaseCallKitListener {
  @override
  void initState() {
    super.initState();
    var config = EaseCallKit.initWithConfig(EaseCallConfig(AgoraAppId));
    EaseCallKit.initWithConfig(config);
    EaseCallKit.listener = this;
  }
  
  ...
  
  @override
  void dispose() {
    EaseCallKit.dispose();
    super.dispose();
  }
} 


  @override
  /// 通话结束时触发该回调
  void callDidEnd(String channelName, EaseCallEndReason reason, int time, EaseCallType callType) {
  }

  @override
  /// 通话过程发生异常时
  void callDidOccurError(EaseCallError error) {
  }

  @override
  /// 被叫开始振铃时，触发该回调
  void callDidReceive(EaseCallType callType, String inviter, Map ext) {
  }

  @override
  /// 加入音视频通话频道前触发该回调，用户需要在触发该回调后，主动从AppServer获取声网token，然后调用setRTCToken:channelName:方法将token设置进来
  void callDidRequestRTCToken(String appId, String channelName, String account) {
  }

  @override
  /// 多人通话中，点击邀请按钮触发该回调
  void multiCallDidInviting(List<String> excludeUsers, Map ext) {
  }
```

## iOS需要配置

[环信iOS EaseCallKit集成文档](http://docs-im.easemob.com/im/ios/other/easecallkit)

iOS EaseCallKit 需要配置`use_frameworks!`，所以您项目中的`Podfile`文件中需要添加`use_frameworks!`


## Android需要配置

[环信Android EaseCallKit集成文档](http://docs-im.easemob.com/im/android/other/easecallkit)


### 添加权限

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.hyphenate.easeim">
    <!-- 悬浮窗权限 -->
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <!-- 访问网络权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- 麦克风权限 -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <!-- 相机权限 -->
    <uses-permission android:name="android.permission.CAMERA" />
    ...
</manifest>
```

### 添加CallkitActivity

```
<activity
    android:name="easemob.hyphenate.calluikit.ui.EaseVideoCallActivity"
    android:configChanges="orientation|keyboardHidden|screenSize"
    android:excludeFromRecents="true"
    android:launchMode="singleInstance"
    android:screenOrientation="portrait"/>
<activity
    android:name="easemob.hyphenate.calluikit.ui.EaseMultipleVideoActivity"
    android:configChanges="orientation|keyboardHidden|screenSize"
    android:excludeFromRecents="true"
    android:launchMode="singleInstance"
    android:screenOrientation="portrait"/>
```
> activity中没有默认theme，如果您的项目中没有配置默认theme，需要您为application添加默认theme

```android:theme="@style/AppTheme"```

```
<application
        android:name="io.flutter.app.FlutterApplication"
        android:label="ease_call_kit_example"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true" >
```

