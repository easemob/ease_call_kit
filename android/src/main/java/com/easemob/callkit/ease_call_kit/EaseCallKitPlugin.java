package com.easemob.callkit.ease_call_kit;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Pair;

import com.hyphenate.EMValueCallBack;
import com.hyphenate.chat.EMClient;
import com.hyphenate.chat.EMOptions;
import com.hyphenate.chat.EMUserInfo;
import com.hyphenate.cloud.EMHttpClient;
import com.hyphenate.easecallkit.EaseCallKit;
import com.hyphenate.easecallkit.base.EaseCallEndReason;
import com.hyphenate.easecallkit.base.EaseCallKitConfig;
import com.hyphenate.easecallkit.base.EaseCallKitListener;
import com.hyphenate.easecallkit.base.EaseCallKitTokenCallback;
import com.hyphenate.easecallkit.base.EaseCallType;
import com.hyphenate.easecallkit.base.EaseCallUserInfo;
import com.hyphenate.easecallkit.base.EaseGetUserAccountCallback;
import com.hyphenate.easecallkit.base.EaseUserAccount;
import com.hyphenate.exceptions.HyphenateException;
import com.hyphenate.util.EMLog;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.JSONUtil;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;



import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;

/** EaseCallKitPlugin */
public class EaseCallKitPlugin implements FlutterPlugin, MethodCallHandler {

  private MethodChannel channel;
  private FlutterPluginBinding binding;
  private WeakReference<EaseCallKitTokenCallback> weakCallback;
  private Map<String, EaseCallKitTokenCallback> tokenCallbackMap;
  private Map<String, EaseGetUserAccountCallback> userAccountCallbackMap;

  private EaseCallKitListener callKitListener;

  static final Handler handler = new Handler(Looper.getMainLooper());

  public void post(Runnable runnable) {
    handler.post(runnable);
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    binding = flutterPluginBinding;
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ease_call_kit");
    channel.setMethodCallHandler(this);
    addCallKitListener();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    JSONObject param = null;
    if (call.arguments != null) {
      param = new JSONObject((Map) call.arguments);
    }
    try {
      if (call.method.equals("initCallKit")) {
        initWithConfig(param, result);
      } else if (call.method.equals("startSingleCall")) {
        startSingleCall(param, result);
      } else if (call.method.equals("startInviteUsers")) {
        startInviteUsers(param, result);
      } else if (call.method.equals("getEaseCallConfig")) {
        getEaseCallConfig(param, result);
      } else if (call.method.equals("setRTCToken")) {
        setRTCToken(param, result);
      } else if (call.method.equals("setUsersMapper")){
        setUsersMapper(param, result);
      } else if (call.method.equals("setUserInfoMapper")){
        setUserInfoMapper(param, result);
      } else if (call.method.equals("getTestUserToken")){
        if (EMClient.getInstance().getAccessToken().length() > 0) {
          result.success(EMClient.getInstance().getAccessToken());
        }else {
          result.success(null);
        }
      } else {
        result.notImplemented();
      }
    } catch (JSONException e) {
      result.notImplemented();
    }
  }

  private void initWithConfig(JSONObject map, final Result result) throws JSONException {
    EaseCallKit.getInstance().init(this.binding.getApplicationContext(), configFromJson(map));
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }


  private void startSingleCall(JSONObject map, final Result result) throws JSONException {
    EaseCallType callType = map.getInt("call_type") == 0 ? EaseCallType.SINGLE_VOICE_CALL : EaseCallType.SINGLE_VIDEO_CALL;
    String user = map.getString("em_id");
    Map<String,Object> ext = null;
    if (map.has("ext")){
      ext = JsonObjectToHashMap(map.getJSONObject("ext"));
    }
    EaseCallKit.getInstance().startSingleCall(callType, user, ext);
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }

  private void startInviteUsers(JSONObject map, final Result result) throws JSONException {
    JSONArray usersArray = map.getJSONArray("users");
    String[] users = new String[usersArray.length()];
    for (int i = 0; i < usersArray.length(); i++) {
      users[i] = (String) usersArray.get(i);
    }
    Map<String,Object> ext = null;
    if (map.has("ext")){
      ext = JsonObjectToHashMap(map.getJSONObject("ext"));
    }
    EaseCallKit.getInstance().startInviteMultipleCall(users, ext);
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }

  // TODO: 不能reset，获取感觉也没啥用是否需要提供?
  private void getEaseCallConfig(JSONObject map, Result result) {
      EaseCallKitConfig config = EaseCallKit.getInstance().getCallKitConfig();
  }

  private void setRTCToken(JSONObject map, final Result result) throws JSONException {
    String rtcToken = map.getString("rtc_token");
    String channelName = map.getString("channel_name");
    Integer uid = map.getInt("uid");
    if (tokenCallbackMap.containsKey(channelName)) {
       EaseCallKitTokenCallback callback = tokenCallbackMap.get(channelName);
       callback.onSetToken(rtcToken, uid);
       tokenCallbackMap.remove(callback);
    }else{
        // ??
    }
    // 是否需要根据onSetToken/onGetTokenError分别返回？
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }


  private void setUsersMapper(JSONObject map, final Result result) throws JSONException {
    JSONObject userMap = map.getJSONObject("map");
    String channelName = map.getString("channel_name");
    if(userAccountCallbackMap.containsKey(channelName)) {
        EaseGetUserAccountCallback callback = userAccountCallbackMap.get(channelName);
        List<EaseUserAccount> list = new ArrayList<>();
      Iterator<String> it = userMap.keys();
      while(it.hasNext()){
        String key = it.next();
        int value = userMap.getInt(key);
        EaseUserAccount account = new EaseUserAccount(value, key);
        list.add(account);
      }
      callback.onUserAccount(list);
      userAccountCallbackMap.remove(callback);
    }else {
      // ??
    }
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }

  private void setUserInfoMapper(JSONObject map, final Result result) throws JSONException {
    JSONArray userInfoList = map.getJSONArray("userInfo_list");
    Map<String, EaseCallUserInfo> userMap = new HashMap<>();
    for (int i = 0; i < userInfoList.length(); i++) {
      JSONObject userJsonObj = userInfoList.getJSONObject(i);
      String username = userJsonObj.getString("key");
      JSONObject accountJsonObj = userJsonObj.getJSONObject("value");
      String avatarUrl = null;
      if (accountJsonObj.has("avatar_url")) {
        avatarUrl = accountJsonObj.getString("avatar_url");
      }
      String nickname = null;
      if (accountJsonObj.has("nickname")) {
        nickname = accountJsonObj.getString("nickname");
      }
      userMap.put(username, new EaseCallUserInfo(nickname, avatarUrl));
    }

    EaseCallKitConfig config = EaseCallKit.getInstance().getCallKitConfig();
    config.setUserInfoMap(userMap);
    post(new Runnable() {
      @Override
      public void run() {
        result.success(null);
      }
    });
  }

  private void addCallKitListener() {
    callKitListener = new EaseCallKitListener() {
      @Override
      public void onInviteUsers(Context context, String userId[], JSONObject ext) {
        Map<String, Object> data = new HashMap<>();
        List<String> users = new ArrayList<>();
        for (int i = 0; i < userId.length; i++) {
          users.add(userId[i]);
        }
        data.put("exclude_users", users);

        Map<String, Object> extMap = null;
          try{
            if (ext != null) {
              extMap = JsonObjectToHashMap(ext);
            }
          }catch(JSONException e) {
          }finally {
            if (extMap != null) {
              data.put("ext", extMap);
            }
            channel.invokeMethod("multiCallDidInviting", data);
          }
      }

      @Override
      public void onEndCallWithReason(EaseCallType callType, String channelName, EaseCallEndReason reason,
          long callTime) {
        final Map<String, Object> data = new HashMap<>();
        data.put("channel_name", channelName);
        data.put("time", callTime);
        data.put("call_type", callTypeToInt(callType));
        data.put("reason", reasonToInt(reason));
        post(new Runnable() {
          @Override
          public void run() {
            channel.invokeMethod("callDidEnd", data);
          }
        });
      }

      @Override
      public void onGenerateToken(String userId, String channelName, String agoraAppId, EaseCallKitTokenCallback callback) {

        if (tokenCallbackMap == null) {
          tokenCallbackMap = new HashMap<>();
        }
        tokenCallbackMap.put(channelName, callback);
        final Map<String, Object> data = new HashMap<>();
        data.put("app_id", agoraAppId);
        data.put("channel_name", channelName);
        data.put("account", userId);

        post(new Runnable() {
          @Override
          public void run() {
            channel.invokeMethod("callDidRequestRTCToken", data);
          }
        });
      }


      @Override
      public void onReceivedCall(EaseCallType callType, String fromUserId, JSONObject ext)  {
        final Map<String, Object> data = new HashMap<>();
        data.put("call_type", callTypeToInt(callType));
        data.put("inviter", fromUserId);

        if (ext != null && ext.length() > 0) {
          String  jsonString = ext.toString();
          data.put("ext", jsonString);
        }

        post(new Runnable() {
          @Override
          public void run() {
            channel.invokeMethod("callDidReceive", data);
          }
        });
      }

      @Override
      public void onCallError(EaseCallKit.EaseCallError type, int errorCode, String description) {

        final Map<String, Object> data = new HashMap<>();
        int intType = 0;
        if (type == EaseCallKit.EaseCallError.PROCESS_ERROR) {
          intType = 1;
        } else if (type == EaseCallKit.EaseCallError.RTC_ERROR) {
          intType = 2;
        } else {
          intType = 3;
        }
        data.put("err_type", intType);
        data.put("err_code", errorCode);
        data.put("err_desc", description);

        post(new Runnable() {
          @Override
          public void run() {
            channel.invokeMethod("callDidOccurError", data);
          }
        });
      }

      @Override
      public void onInViteCallMessageSent() {

      }

      @Override
      public void onRemoteUserJoinChannel(String channelName, String userName, int uid, EaseGetUserAccountCallback callback) {
        if (userAccountCallbackMap == null) {
          userAccountCallbackMap = new HashMap<>();
        }

        userAccountCallbackMap.put(channelName, callback);

        final Map<String, Object> data = new HashMap<>();
        data.put("channel_name", channelName);
        data.put("account", userName);
        data.put("agora_uid", uid);

        post(new Runnable() {
          @Override
          public void run() {
            channel.invokeMethod("remoteUserDidJoinChannel", data);
          }
        });
      }
    };

    EaseCallKit.getInstance().setCallKitListener(callKitListener);
  }



  private static HashMap<String, Object> JsonObjectToHashMap(JSONObject data) throws JSONException {
    HashMap<String, Object> map = new HashMap<String,Object>();
    Iterator iterator = data.keys();
    while (iterator.hasNext()) {
      String key = iterator.next().toString();
      Object result = data.get(key);
      if (result.getClass().getSimpleName().equals("Integer")) {
        map.put(key, (Integer) result);
      } else if (result.getClass().getSimpleName().equals("Boolean")) {
        map.put(key, (Boolean) result);
      } else if (result.getClass().getSimpleName().equals("Long")) {
        map.put(key, (Long) result);
      } else if (result.getClass().getSimpleName().equals("JSONObject")) {
        map.put(key, (JSONObject) result);
      } else if (result.getClass().getSimpleName().equals("JSONArray")) {
        map.put(key, (JSONArray) result);
      } else {
        map.put(key, data.getString(key));
      }
    }
    return map;
  }

  private EaseCallKitConfig configFromJson(JSONObject map) throws JSONException {
    EaseCallKitConfig config = new EaseCallKitConfig();
    config.setAgoraAppId(map.getString("agora_app_id"));

    if (map.has("default_head_image_url")) {
      config.setDefaultHeadImage(map.getString("default_head_image_url"));
    }

    if (map.has("call_timeout")) {
      config.setCallTimeOut(map.getInt("call_timeout") * 1000);
    }

    if (map.has("ring_file_url")) {
      config.setRingFile(map.getString("ring_file_url"));
    }

    config.setEnableRTCToken(map.has("enable_rtc_token_validate") ? map.getBoolean("enable_rtc_token_validate") : true);
    Map<String, EaseCallUserInfo> userMap = new HashMap<>();
    if (map.has("user_map")) {
      JSONArray usersList = map.getJSONArray("user_map");
      for (int i = 0; i < usersList.length(); i++) {
        JSONObject userObject = (JSONObject) usersList.get(i);
        EaseCallUserInfo userInfo = userInfoFromJson(userObject.getJSONObject("value"));
        userMap.put(userObject.getString("key"), userInfo);
      }
      config.setUserInfoMap(userMap);
    }

    return config;
  }

  private EaseCallUserInfo userInfoFromJson(JSONObject map) throws JSONException {

    String name = null;
    if(map.has("nickname")) {
      name = map.getString("nickname");
    }

    String headImage = null;
    if (map.has("avatar_url")) {
      headImage = map.getString("avatar_url");
    }

    EaseCallUserInfo userInfo = new EaseCallUserInfo(name, headImage);

    return userInfo;
  }

  private int callTypeToInt(EaseCallType type) {
    int intType = 1;
    if (type == EaseCallType.SINGLE_VOICE_CALL) {
      intType = 1;
    } else if (type == EaseCallType.SINGLE_VIDEO_CALL) {
      intType = 2;
    } else {
      intType = 3;
    }
    return intType;
  }

  private int reasonToInt(EaseCallEndReason reason) {
    int intReason = 1;
    switch (reason) {
    case EaseCallEndReasonHangup:
      intReason = 1;
      break;
    case EaseCallEndReasonCancel:
      intReason = 2;
      break;
    case EaseCallEndReasonRemoteCancel:
      intReason = 3;
      break;
    case EaseCallEndReasonRefuse:
      intReason = 4;
      break;
    case EaseCallEndReasonBusy:
      intReason = 5;
      break;
    case EaseCallEndReasonNoResponse:
      intReason = 6;
      break;
    case EaseCallEndReasonRemoteNoResponse:
      intReason = 7;
      break;
    case EaseCallEndReasonHandleOnOtherDevice:
      intReason = 8;
      break;
    default:
      break;
    }
    return intReason;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
