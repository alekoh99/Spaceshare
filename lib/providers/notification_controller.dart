import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/notification_service.dart';
import '../models/supporting_models.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  late NotificationService _notificationService;

  NotificationService get notificationService => _notificationService;

  @override
  void onInit() {
    super.onInit();
    try {
      _notificationService = Get.find<NotificationService>();
      authController = Get.find<AuthController>();
    } catch (e) {
      debugPrint('Failed to resolve NotificationController services: $e');
      rethrow;
    }
  }

  // State
  final notifications = RxList<Notification>([]);
  final unreadCount = 0.obs;
  final isLoadingNotifications = false.obs;
  final error = Rx<String?>(null);
  final isSubscribedToMatches = false.obs;
  final isSubscribedToMessages = false.obs;
  final isSubscribedToPayments = false.obs;

  late AuthController authController;
  late Stream<List<Notification>>? notificationStream;

  Future<void> loadNotifications({int limit = 50}) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingNotifications.value = true;
      final result = await _notificationService.getNotifications(
        authController.currentUserId.value!,
        limit: limit,
      );
      
      if (result.isSuccess()) {
        final notifs = (result.getOrNull() as List<dynamic>?)?.cast<Notification>() ?? <Notification>[];
        notifications.value = notifs;
      } else {
        notifications.value = [];
      }

      // Subscribe to real-time updates
      notificationStream = _notificationService.getNotificationStream(
        authController.currentUserId.value!,
      );

      await updateUnreadCount();
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  void listenToNotifications() {
    try {
      if (authController.currentUserId.value == null) return;

      notificationStream = _notificationService.getNotificationStream(
        authController.currentUserId.value!,
      );

      notificationStream!.listen(
        (notifs) {
          notifications.value = notifs;
          calculateUnreadCount();
        },
        onError: (e) {
          error.value = e.toString();
        },
      );
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> updateUnreadCount() async {
    try {
      if (authController.currentUserId.value == null) return;

      final countResult = await _notificationService.getUnreadCount(
        authController.currentUserId.value!,
      );
      if (countResult.isSuccess()) {
        unreadCount.value = (countResult.getOrNull() as int?) ?? 0;
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remove from local list
      notifications.removeWhere((n) => n.id == notificationId);
      notifications.refresh();
      await updateUnreadCount();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await updateUnreadCount();

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifications.refresh();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      await _notificationService.markAllAsRead(authController.currentUserId.value!);

      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      notifications.refresh();

      unreadCount.value = 0;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> subscribeToDefaultTopics() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      await _notificationService.subscribeToTopic('matches');
      isSubscribedToMatches.value = true;

      await _notificationService.subscribeToTopic('messages');
      isSubscribedToMessages.value = true;

      await _notificationService.subscribeToTopic('payments');
      isSubscribedToPayments.value = true;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      await _notificationService.subscribeToTopic(topic);

      if (topic == 'matches') isSubscribedToMatches.value = true;
      if (topic == 'messages') isSubscribedToMessages.value = true;
      if (topic == 'payments') isSubscribedToPayments.value = true;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      await _notificationService.unsubscribeFromTopic(
        topic,
      );

      if (topic == 'matches') isSubscribedToMatches.value = false;
      if (topic == 'messages') isSubscribedToMessages.value = false;
      if (topic == 'payments') isSubscribedToPayments.value = false;
    } catch (e) {
      error.value = e.toString();
    }
  }

  void calculateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  @override
  void onClose() {
    AppLogger.info('NotificationController', 'Disposing controller resources');
    notifications.clear();
    notificationStream = null;
    super.onClose();
  }
}

// Extension for copyWith pattern
extension NotificationExt on Notification {
  Notification copyWith({
    String? notificationId,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? actionUrl,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}
