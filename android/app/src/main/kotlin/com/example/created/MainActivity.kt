package com.example.created

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
         // Disable screenshots and screen recording
       // window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        // Allow screenshots and screen recording: ensure FLAG_SECURE is not set
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
