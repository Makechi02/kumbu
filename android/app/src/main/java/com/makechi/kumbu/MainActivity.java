package com.makechi.kumbu;

import android.os.Bundle;
import android.view.WindowManager;

import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Hides the app in the recent-apps screen. This also blocks screenshots
        // and screen recording. Remove this line to allow them.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
        super.onCreate(savedInstanceState);
    }
}