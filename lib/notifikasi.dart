
// ignore: unused_import
import 'edit_buku_admin.dart';
// ignore: unused_import
import 'package:firebase_messaging/firebase_messaging.dart';

void requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan.');
  } else {
    print('Izin notifikasi ditolak.');
  }
}


