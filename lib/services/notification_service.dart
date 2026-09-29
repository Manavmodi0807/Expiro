import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/product_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const List<int> defaultReminderIntervals = [30, 15, 7];
  static const String channelId = 'warranty_expiry_reminders';
  static const String channelName = 'Warranty Expiry Reminders';
  static const String channelDescription =
      'Notifications reminding you before your product warranties expire.';

  static const int reminderHour = 9;
  static const int reminderMinute = 0;

  /// Initialize the local notification service and timezone database safely.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(
          tz.getLocation(tz.local.name.isNotEmpty ? tz.local.name : 'UTC'),
        );
      } catch (_) {
        // Default local location initialized by initializeTimeZones
      }

      // 2. Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Overall initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // 4. Create high-importance Android notification channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          const androidChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
          );
          await androidPlugin.createNotificationChannel(androidChannel);
        }
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization failed safely: $e');
    }
  }

  /// Request runtime notification permission on Android 13+ (API 33+).
  Future<bool> requestNotificationPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Deterministically compute a unique, positive 31-bit notification ID
  /// based on the [productId] and [daysBefore] reminder interval.
  static int generateNotificationId(String productId, int daysBefore) {
    var hash = 17;
    for (var i = 0; i < productId.length; i++) {
      hash = ((hash * 37) + productId.codeUnitAt(i)) & 0x3fffffff;
    }
    hash = ((hash * 37) + daysBefore) & 0x3fffffff;
    return hash;
  }

  /// Calculate the scheduled DateTime for a given reminder interval.
  static DateTime calculateReminderDateTime(
    DateTime expiryDate,
    int daysBefore, {
    int hour = reminderHour,
    int minute = reminderMinute,
  }) {
    final cleanExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final reminderDate = cleanExpiry.subtract(Duration(days: daysBefore));
    return DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );
  }

  /// Pure helper to decide whether a reminder should be scheduled.
  static bool shouldScheduleReminder({
    required DateTime reminderDateTime,
    required DateTime referenceNow,
    required DateTime expiryDate,
  }) {
    final cleanExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final cleanNow = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);

    // If warranty is already expired on or before today, do not schedule
    if (cleanExpiry.isBefore(cleanNow)) {
      return false;
    }

    // Schedule only if the reminder timestamp is strictly in the future
    return reminderDateTime.isAfter(referenceNow);
  }

  /// Schedule reminders for a product across specified intervals.
  Future<void> scheduleProductReminders(
    Product product, {
    List<int> reminderIntervals = defaultReminderIntervals,
    DateTime? referenceNow,
  }) async {
    if (product.id.isEmpty) return;

    final now = referenceNow ?? DateTime.now();

    for (final daysBefore in reminderIntervals) {
      final reminderTime = calculateReminderDateTime(
        product.warrantyExpiryDate,
        daysBefore,
      );

      if (shouldScheduleReminder(
        reminderDateTime: reminderTime,
        referenceNow: now,
        expiryDate: product.warrantyExpiryDate,
      )) {
        final notificationId = generateNotificationId(product.id, daysBefore);
        await _scheduleSingleNotification(
          id: notificationId,
          title: 'Warranty Expiring Soon',
          body: '${product.productName} warranty expires in $daysBefore days.',
          scheduledDate: reminderTime,
          payload: product.id,
        );
      }
    }
  }

  /// Helper to invoke zonedSchedule on platform safely.
  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint('Scheduled notification $id for $tzDateTime');
    } catch (e) {
      debugPrint('Error scheduling local notification $id: $e');
    }
  }

  /// Cancel all scheduled reminder notifications for a specific product.
  Future<void> cancelProductReminders(
    String productId, {
    List<int> reminderIntervals = defaultReminderIntervals,
  }) async {
    if (productId.isEmpty) return;

    for (final daysBefore in reminderIntervals) {
      final notificationId = generateNotificationId(productId, daysBefore);
      try {
        await _notificationsPlugin.cancel(id: notificationId);
        debugPrint('Cancelled notification $notificationId for product $productId');
      } catch (e) {
        debugPrint('Error cancelling notification $notificationId: $e');
      }
    }
  }

  /// Reschedule product reminders when warranty details change.
  Future<void> rescheduleProductReminders(
    Product product, {
    List<int> reminderIntervals = defaultReminderIntervals,
  }) async {
    await cancelProductReminders(product.id, reminderIntervals: reminderIntervals);
    await scheduleProductReminders(product, reminderIntervals: reminderIntervals);
  }
}
