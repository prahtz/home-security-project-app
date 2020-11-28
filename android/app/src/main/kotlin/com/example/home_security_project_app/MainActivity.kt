package com.example.home_security_project_app

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.media.MediaPlayer
import android.media.AudioManager
import android.net.Uri

import android.view.WindowManager

import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterFragmentActivity() {  

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        //super.configureFlutterEngine(flutterEngine)
        //GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}