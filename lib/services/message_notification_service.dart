import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class MessageNotificationService {
  MessageNotificationService._internal();

  static final MessageNotificationService instance = MessageNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _lastKnownMessageTimes = {};

  StreamSubscription<User?>? _authSub;
  Timer? _pollingTimer;

  late final GlobalKey<NavigatorState> navigatorKey;

  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) return;
        navigatorKey.currentState?.pushNamed(
          '/messages',
          arguments: {'openChatWith': payload},
        );
      },
    );

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _pollingTimer?.cancel();
      _lastKnownMessageTimes.clear();
      if (user == null) return;
      _startPolling(user.uid);
    });
  }

  void _startPolling(String userId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConversations(userId);
    });
    
    _checkConversations(userId);
  }

  Future<void> _checkConversations(String userId) async {
    try {
      final conversations = await ApiService.fetchConversations(userId);
      for (final chat in conversations) {
        if (chat.id.isEmpty) continue;

        final lastMessageAt = chat.lastMessageTime;
        final known = _lastKnownMessageTimes[chat.id];

        if (known == null) {
          _lastKnownMessageTimes[chat.id] = lastMessageAt;
          continue;
        }

        if (lastMessageAt.isAfter(known)) {
          _lastKnownMessageTimes[chat.id] = lastMessageAt;
          
          
          if (chat.lastMessageSenderId.isNotEmpty && chat.lastMessageSenderId != userId) {
             await _showNotification(
              conversationId: chat.id,
              currentUserId: userId,
              message: chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Yeni mesaj',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Notification polling error: $e');
    }
  }

  Future<void> _showNotification({
    required String conversationId,
    required String currentUserId,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'message_alerts',
      'Mesaj Bildirimleri',
      channelDescription: 'Yeni mesaj geldiğinde bildirim gönderir',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    
    final parts = conversationId.split('__');
    String otherUserId = '';
    if (parts.length == 2) {
       otherUserId = (parts[0] == currentUserId) ? parts[1] : parts[0];
    }
    
    await _notifications.show(
      conversationId.hashCode,
      'Yeni mesaj',
      message,
      notificationDetails,
      payload: otherUserId,
    );
  }

  void dispose() {
    _authSub?.cancel();
    _pollingTimer?.cancel();
  }
}


