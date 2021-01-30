package com.example.home_security_project_app

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
import com.example.alarm_notification.AlarmNotificationPlugin

class Application : FlutterApplication(), PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
        FlutterFirebaseMessagingService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin.registerWith(registry?.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"))
        io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin.registerWith(registry?.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"))
        AlarmNotificationPlugin.registerWith(registry?.registrarFor("com.example.alarm_notification.AlarmNotificationPlugin"))
    }
    
}