import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:chat_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
//! check the permissions of the notification service
  void requestNotificationPermission() async {
    NotificationSettings notificationSettings =
        await firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print("User authorization");
      }
    } else {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  }

//! get devices token
  Future<String> getDeviceToken() async {
    String? token = await firebaseMessaging.getToken();
    return token!;
  }

//! refresh token
  void isRefreshToken() {
    firebaseMessaging.onTokenRefresh.listen((event) {
      event.toString();
    });
  }

//! initialize the android and ios settings and icon
  void initLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    var android = const AndroidInitializationSettings("@mipmap/ic_launcher");
    var ios = const DarwinInitializationSettings();

    final initializations = InitializationSettings(android: android, iOS: ios);
    await localNotificationsPlugin.initialize(
      initializations,
      onDidReceiveNotificationResponse: (payload) {
        handleMessage(context, message);
      },
    );
  }

//! listen the notification
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(message.notification!.title);
        print(message.notification!.body);
      }
      if (Platform.isAndroid) {
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });
  }

//! showNotification
  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      "High Importance Notifications",
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channel.id.toString(),
      channel.name.toString(),
      importance: Importance.high,
      priority: Priority.high,
      ticker: "ticker",
    );

    DarwinNotificationDetails darwinNotificationDetails =
        const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      localNotificationsPlugin.show(
        1,
        message.notification!.title.toString(),
        message.notification!.body.toString(),
        notificationDetails,
      );
    });
  }

  Future<void> setUpInteractMessage(BuildContext context) async {
    //! when app is terminated
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      handleMessage(context, message);
    }

    //! when app is background

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == "chats") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chats(
                    id: message.data['id'],
                  )));
    }
  }
}
