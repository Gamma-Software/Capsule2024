import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // dynamic list of notifications
  List<String> _notifications = [];

  factory NotificationService() {
    return _notificationService;
  }

  Future selectNotification(String? payload) async {
    //Handle notification tapped logic here
    print("Notification");
  }

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: null, macOS: null);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future showNotification(String title, String? body) async {
    // If the notification is not in the list add it
    if (!_notifications.contains(title)) {
      _notifications.add(title);
    }

    // Get the notification index
    int index = _notifications.indexOf(title);

    await flutterLocalNotificationsPlugin.show(
        index,
        title + index.toString(),
        body,
        const NotificationDetails(
            android: AndroidNotificationDetails("0", "applicationName",
                channelDescription: 'notification')),
        payload: 'data');
  }

  NotificationService._internal();
}
