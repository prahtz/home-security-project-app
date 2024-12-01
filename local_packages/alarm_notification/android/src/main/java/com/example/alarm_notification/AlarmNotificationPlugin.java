package com.example.alarm_notification;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.content.pm.PackageManager;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import androidx.annotation.NonNull;

import java.io.IOException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import android.content.BroadcastReceiver;

/** AlarmNotificationPlugin */
public class AlarmNotificationPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private static final String CHANNEL = "alarm_notification";
  private MethodChannel channel;
  private Context appContext;
  private Activity myActivity = null;
  private Intent myIntent = null;
  public static MediaPlayer mp = null;
  private String CHANNEL_ID = "ALARM";

  public static void stopPlayer() {
    if (mp != null) {
        mp.stop();
        mp.reset();
        mp.release();
        mp = null;
    }
  }

  public static void startPlayer(Context context) {
    stopPlayer();
    mp = new MediaPlayer();
    mp.setAudioAttributes(new AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build());
    mp.setLooping(true);
    try {
    mp.setDataSource(context, Uri.parse("android.resource://com.example.home_security_project_app/"+"raw/alarm"));
    mp.prepare();
    } catch (IOException e) {
        e.printStackTrace();
    }
    mp.start();
  }

  public static void registerWith(Registrar registrar) {
    AlarmNotificationPlugin plugin = new AlarmNotificationPlugin();
    plugin.setActivity(registrar.activity());
    registrar.addNewIntentListener(plugin);
    plugin.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  private void setActivity(Activity activity) {
    this.myActivity = activity;
    if(activity != null) {
      myIntent = activity.getIntent();
    }
  }

  private void onAttachedToEngine(Context context, BinaryMessenger binaryMessenger) {
    this.appContext = context;
    this.channel = new MethodChannel(binaryMessenger, CHANNEL);
    this.channel.setMethodCallHandler(this);
  }
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    onAttachedToEngine(flutterPluginBinding.getApplicationContext(), flutterPluginBinding.getBinaryMessenger());
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

      String name = "Allarme";
      String description = "Alarm notifications";
      int importance = NotificationManager.IMPORTANCE_HIGH;
      NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
      channel.setDescription(description);
      channel.setSound(null, null);
      NotificationManager notificationManager = appContext.getSystemService(NotificationManager.class);
      notificationManager.createNotificationChannel(channel);
    }
  }

  private void showNotification() {
    String packageName = appContext.getPackageName();
    PackageManager packageManager = appContext.getPackageManager();
    Intent intent = packageManager.getLaunchIntentForPackage(packageName);
    intent.setAction("SELECT_NOTIFICATION");
    PendingIntent pendingIntent = PendingIntent.getActivity(appContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);

    // Intent for dismissing the notification
    Intent dismissIntent = new Intent(appContext, NotificationBroadcastReceiver.class);
    dismissIntent.setAction("NOTIFICATION_DISMISSED");

    PendingIntent dismissPendingIntent = PendingIntent.getBroadcast(
            appContext,
            0,
            dismissIntent,
            PendingIntent.FLAG_CANCEL_CURRENT
    );
    NotificationCompat.Builder builder = new NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setContentTitle("ALLARME ATTIVO")
            .setContentText("Intrusione rilevata!")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setSmallIcon(appContext.getApplicationInfo().icon)
            //.setFullScreenIntent(pendingIntent, true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDeleteIntent(dismissPendingIntent);
    NotificationManagerCompat notificationManager = NotificationManagerCompat.from(appContext);

    int notificationId = 1;
    notificationManager.notify(notificationId, builder.build());
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("play")) {
      startPlayer(appContext);
      result.success(0);
    }
    else if(call.method.equals("stop")) {
      stopPlayer();
      result.success(0);
    }
    else if(call.method.equals("init")) {
      createNotificationChannel();
      result.success(0);
    }
    else if(call.method.equals("show")) {
      showNotification();
      result.success(0);
    }
    else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    //channel.setMethodCallHandler(null);
  }

  private static String getResourceFromContext(@NonNull Context context, String resName) {
    final int stringRes = context.getResources().getIdentifier(resName, "string", context.getPackageName());
    if (stringRes == 0) {
      throw new IllegalArgumentException(String.format("The 'R.string.%s' value it's not defined in your project's resources file.", resName));
    }
    return context.getString(stringRes);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    binding.addOnNewIntentListener(this);
    myActivity = binding.getActivity();
    myIntent = myActivity.getIntent();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    myActivity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    binding.addOnNewIntentListener(this);
    myActivity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    myActivity = null;
  }

  @Override
  public boolean onNewIntent(Intent intent) {
    if (intent.getAction().equals("SELECT_NOTIFICATION")){
        stopPlayer();
    }
    
    if (myActivity != null) {
      myActivity.setIntent(intent);
      return true;
    }
    return false;
  }
}
