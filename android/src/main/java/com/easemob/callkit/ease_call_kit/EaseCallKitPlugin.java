package com.easemob.callkit.ease_call_kit;

import android.content.Context;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.util.Pair;

import com.hyphenate.EMValueCallBack;
import com.hyphenate.chat.EMClient;
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
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** EaseCallKitPlugin */
public class EaseCallKitPlugin implements FlutterPlugin, MethodCallHandler {

  private MethodChannel channel;
  private boolean enableRTCTokenValidate = false;
  private FlutterPluginBinding binding;
  private Result result;
  private WeakReference<EaseCallKitTokenCallback> weakCallback;
  private EaseCallKitListener callKitListener;

  private String tokenUrl = "http://a1.easemob.com/token/rtcToken/v1";
  private String uIdUrl = "http://a1.easemob.com/channel/mapper";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    binding = flutterPluginBinding;
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ease_call_kit");
    channel.setMethodCallHandler(this);
    addCallKitListener();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    JSONObject param = new JSONObject((Map) call.arguments);
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
      } else {
        result.notImplemented();
      }
    } catch (JSONException e) {
      result.notImplemented();
    }
  }

  private void initWithConfig(JSONObject map, Result result) throws JSONException {

    EaseCallKit.getInstance().init(this.binding.getApplicationContext(), configFromJson(map));
    Map<String, Object> data = new HashMap<>();
    result.success(data);
  }

  private void startSingleCall(JSONObject map, Result result) throws JSONException {
    int callType = map.getInt("call_type");
    String user = map.getString("em_id");
    Map ext = JsonObjectToHashMap(map.getJSONObject("ext"));

    EaseCallKit.getInstance()
        .startSingleCall(callType == 0 ? EaseCallType.SINGLE_VOICE_CALL : EaseCallType.SINGLE_VIDEO_CALL, user, ext);
    this.result = result;
  }

  private void startInviteUsers(JSONObject map, Result result) throws JSONException {
    JSONArray usersArray = map.getJSONArray("users");
    String[] users = new String[usersArray.length()];
    for (int i = 0; i < usersArray.length(); i++) {
      users[i] = (String) usersArray.get(i);
    }
    Map ext = JsonObjectToHashMap(map.getJSONObject("ext"));
    EaseCallKit.getInstance().startInviteMultipleCall(users, ext);
    this.result = result;
  }

  private void getEaseCallConfig(JSONObject map, Result result) {

  }

  private void setRTCToken(JSONObject map, Result result) throws JSONException {
    String rtcToken = map.getString("rtc_token");
    String channelName = map.getString("channel_name");
    if (this.weakCallback.get() != null) {
      this.weakCallback.get().onSetToken(rtcToken,1);
    }
  }


  private void getRTCToken(JSONObject map, Result result) throws JSONException {
    String username = map.getString("username");
    String password = map.getString("password");
    String channelName = map.getString("channelName");
    String agoraUserId = map.getString("agoraUserId");
    String appkey = map.getString("appkey");
    Log.v("getRTCToken", "userName=" + username +"password"+password +"channelName"+channelName+"agoraUserId"+agoraUserId);
  }

  private void addCallKitListener() {
    callKitListener = new EaseCallKitListener() {
      @Override
      public void onInviteUsers(Context context, String userId[], JSONObject ext) {
        Map<String, Object> data = new HashMap<>();
        data.put("exclude_users", userId);
        data.put("ext", ext);
        channel.invokeMethod("multiCallDidInviting", data);
      }

      @Override
      public void onEndCallWithReason(EaseCallType callType, String channelName, EaseCallEndReason reason,
          long callTime) {
        Map<String, Object> data = new HashMap<>();
        data.put("channel_name", channelName);
        data.put("time", callTime);
        data.put("call_type", callTypeToInt(callType));
        data.put("reason", reasonToInt(reason));
        channel.invokeMethod("callDidEnd", data);
      }

      @Override
      public void onGenerateToken(String userId, String channelName, String appKey, EaseCallKitTokenCallback callback) {
//        weakCallback = new WeakReference<>(callback);
//        Map<String, Object> data = new HashMap<>();
//        data.put("app_id", appKey);
//        data.put("account", userId);
//        data.put("channel_name", channelName);
//        channel.invokeMethod("callDidRequestRTCToken", data);

        EMLog.d("onGenerateToken","onGenerateToken userId:" + userId + " channelName:" + channelName + " appKey:"+ appKey);
        String url = tokenUrl;
        url += "?";
        url += "userAccount=";
        url += userId;
        url += "&channelName=";
        url += channelName;
        url += "&appkey=";
        url +=  appKey;

        //获取声网Token
        getRtcToken(url, callback);

      }

      @Override
      public void onReceivedCall(EaseCallType callType, String fromUserId, JSONObject ext) {
        Map<String, Object> data = new HashMap<>();
        data.put("call_type", callTypeToInt(callType));
        data.put("inviter", fromUserId);
        if (ext != null && ext.length() > 0) {
          data.put("ext", ext);
        }
        //收到接听电话
        EMLog.d("onRecivedCall","onRecivedCall" + callType.name() + " fromUserId:" + fromUserId);

        channel.invokeMethod("callDidReceive", data);
      }

      @Override
      public void onCallError(EaseCallKit.EaseCallError type, int errorCode, String description) {
        Map<String, Object> data = new HashMap<>();
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
        channel.invokeMethod("callDidOccurError", data);
      }

      @Override
      public void onInViteCallMessageSent() {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
          @Override
          public void run() {
            if (result != null) {
              Map<String, Object> data = new HashMap<>();
              result.success(data);
              result = null;
            }
          }
        });
      }

      @Override
      public void onRemoteUserJoinChannel(String channelName, String userName, int uid, EaseGetUserAccountCallback callback) {
        if(userName == null || userName == ""){
          String url = uIdUrl;
          url += "?";
          url += "channelName=";
          url += channelName;
          url += "&userAccount=";
          url += EMClient.getInstance().getCurrentUser();
          url += "&appkey=";
          url +=  EMClient.getInstance().getOptions().getAppKey();
          getUserIdAgoraUid(uid,url,callback);
        }else{
          //设置用户昵称 头像
          setEaseCallKitUserInfo(userName);
          EaseUserAccount account = new EaseUserAccount(uid,userName);
          List<EaseUserAccount> accounts = new ArrayList<>();
          accounts.add(account);
          callback.onUserAccount(accounts);
        }
      }
    };
    EaseCallKit.getInstance().setCallKitListener(callKitListener);
  }



  /**
   * 获取声网Token
   *
   */
  private void getRtcToken(final String tokenUrl, final EaseCallKitTokenCallback callback){
    new AsyncTask<String, Void, Pair<Integer, String>>(){
      @Override
      protected Pair<Integer, String> doInBackground(String... str) {
        try {
          Pair<Integer, String> response = EMHttpClient.getInstance().sendRequestWithToken(tokenUrl, null,EMHttpClient.GET);
          return response;
        }catch (HyphenateException exception) {
          exception.printStackTrace();
        }
        return  null;
      }
      @Override
      protected void onPostExecute(Pair<Integer, String> response) {
        if(response != null) {
          try {
            int resCode = response.first;
            if(resCode == 200){
              String responseInfo = response.second;
              if(responseInfo != null && responseInfo.length() > 0){
                try {
                  JSONObject object = new JSONObject(responseInfo);
                  String token = object.getString("accessToken");
                  int uId = object.getInt("agoraUserId");

                  //设置自己头像昵称
                  setEaseCallKitUserInfo(EMClient.getInstance().getCurrentUser());
                  callback.onSetToken(token,uId);
                }catch (Exception e){
                  e.getStackTrace();
                }
              }else{
                callback.onGetTokenError(response.first,response.second);
              }
            }else{
              callback.onGetTokenError(response.first,response.second);
            }
          }catch (Exception e){
            e.printStackTrace();
          }
        }else{
          callback.onSetToken(null,0);
        }
      }
    }.execute(tokenUrl);
  }

  /**
   * 根据channelName和声网uId获取频道内所有人的UserId
   * @param uId
   * @param url
   * @param callback
   */
  private void getUserIdAgoraUid(final int uId, final String url, final EaseGetUserAccountCallback callback){
    new AsyncTask<String, Void, Pair<Integer, String>>(){
      @Override
      protected Pair<Integer, String> doInBackground(String... str) {
        try {
          Pair<Integer, String> response = EMHttpClient.getInstance().sendRequestWithToken(url, null,EMHttpClient.GET);
          return response;
        }catch (HyphenateException exception) {
          exception.printStackTrace();
        }
        return  null;
      }
      @Override
      protected void onPostExecute(Pair<Integer, String> response) {
        if(response != null) {
          try {
            int resCode = response.first;
            if(resCode == 200){
              String responseInfo = response.second;
              List<EaseUserAccount> userAccounts = new ArrayList<>();
              if(responseInfo != null && responseInfo.length() > 0){
                try {
                  JSONObject object = new JSONObject(responseInfo);
                  JSONObject resToken = object.getJSONObject("result");
                  Iterator it = resToken.keys();
                  while(it.hasNext()) {
                    String uIdStr = it.next().toString();
                    int uid = 0;
                    uid = Integer.valueOf(uIdStr).intValue();
                    String username = resToken.optString(uIdStr);
                    if(uid == uId){
                      //获取到当前用户的userName 设置头像昵称等信息
                      setEaseCallKitUserInfo(username);
                    }
                    userAccounts.add(new EaseUserAccount(uid, username));
                  }
                  callback.onUserAccount(userAccounts);
                }catch (Exception e){
                  e.getStackTrace();
                }
              }else{
                callback.onSetUserAccountError(response.first,response.second);
              }
            }else{
              callback.onSetUserAccountError(response.first,response.second);
            }
          }catch (Exception e){
            e.printStackTrace();
          }
        }else{
          callback.onSetUserAccountError(100,"response is null");
        }
      }
    }.execute(url);
  }


  /**
   * 设置callKit 用户头像昵称
   * @param userName
   */
  private void setEaseCallKitUserInfo(final String userName){
//    EaseUser user = getUserInfo(userName);
//    EaseCallUserInfo userInfo = new EaseCallUserInfo();
//    if(user != null){
//      userInfo.setNickName(user.getNickname());
//      userInfo.setHeadImage(user.getAvatar());
//    }
//    EaseCallKit.getInstance().getCallKitConfig().setUserInfo(userName,userInfo);

    EMValueCallBack<Map<String,EMUserInfo>> callBack = new EMValueCallBack<Map<String, EMUserInfo>>() {
      @Override
      public void onSuccess(Map<String, EMUserInfo> value) {
        EaseCallUserInfo userInfo = new EaseCallUserInfo();
        EMUserInfo cUserInfo = value.get(userName);
        if(cUserInfo != null){
          userInfo.setNickName(cUserInfo.getUserId());
          userInfo.setHeadImage(cUserInfo.getAvatarUrl());
        }
        EaseCallKit.getInstance().getCallKitConfig().setUserInfo(userName,userInfo);
      }

      @Override
      public void onError(int error, String errorMsg) {

      }
    };

    String[] userIds = new String[1];
    userIds[0] = userName;
    EMClient.getInstance().userInfoManager().fetchUserInfoByUserId(userIds,callBack);

  }

  private static HashMap<String, Object> JsonObjectToHashMap(JSONObject data) throws JSONException {
    HashMap<String, Object> map = new HashMap();
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
    String headImageStr = map.getString("default_head_image_url");
    if (headImageStr.length() > 0) {
      config.setDefaultHeadImage(headImageStr);
    }

    int callTimeOut = map.getInt("call_timeout");
    if (callTimeOut > 0) {
      config.setCallTimeOut(map.getInt("call_timeout"));
    }
    String ringURL = map.getString("ring_file_url");
    if (ringURL.length() > 0) {
      config.setRingFile(ringURL);
    }

    this.enableRTCTokenValidate = map.getBoolean("enable_rtc_token_validate");
    config.setEnableRTCToken(this.enableRTCTokenValidate);
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
    String name = map.getString("nickname");
    String headImage = null;
    if (map.get("avatar_url") != null) {
      headImage = map.getString("avatar_url");
    }

    EaseCallUserInfo userInfo = new EaseCallUserInfo(name, null);

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
    int intReason = 0;
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
