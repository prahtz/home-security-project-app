package com.example.alarm_notification;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import java.io.IOException;

public class NotificationBroadcastReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == "NOTIFICATION_DISMISSED") {
            AlarmNotificationPlugin.stopPlayer();
        }
    }
}