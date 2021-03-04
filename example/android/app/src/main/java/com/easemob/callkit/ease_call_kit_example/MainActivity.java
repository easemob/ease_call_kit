package com.easemob.callkit.ease_call_kit_example;

import android.os.Bundle;

import androidx.annotation.Nullable;
import io.flutter.embedding.android.FlutterActivity;

import com.hyphenate.EMCallBack;
import com.hyphenate.chat.EMClient;
import com.hyphenate.chat.EMOptions;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EMOptions emOptions = new EMOptions();
        emOptions.setAppKey("easemob-demo#chatdemoui");
        EMClient.getInstance().init(this.getApplicationContext(), emOptions);
        EMClient.getInstance().login("du001", "1", new EMCallBack() {
            @Override
            public void onSuccess() {

            }

            @Override
            public void onError(int code, String error) {

            }

            @Override
            public void onProgress(int progress, String status) {

            }
        });
    }
}
