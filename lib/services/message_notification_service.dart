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
    // Check immediately
    _checkConversations(userId);
  }

  Future<void> _checkConversations(String userId) async {
    try {
      final conversations = await ApiService.fetchConversations(userId);
      for (final data in conversations) {
        final String? lastMessageSenderId = data['lastMessageSenderId'] as String?;
        final conversationId = data['id'] as String?;
        if (conversationId == null) continue;

        dynamic lastMessageAtRaw = data['lastMessageAt'];
        DateTime? lastMessageAt;
        
        if (lastMessageAtRaw is String) {
           lastMessageAt = DateTime.tryParse(lastMessageAtRaw);
        } else if (lastMessageAtRaw != null && lastMessageAtRaw is Map && lastMessageAtRaw['_seconds'] != null) {
           // Firestore timestamp object structure in JSON
           final int seconds = lastMessageAtRaw['_seconds'];
           final int nanoseconds = lastMessageAtRaw['_nanoseconds'] ?? 0;
           lastMessageAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        }

        if (lastMessageAt == null || lastMessageSenderId == null) continue;

        final known = _lastKnownMessageTimes[conversationId];
        // If we have a new message (time is after known time, or we didn't know this convo but it has messages)
        // Note: For new installs/refreshes, we might get notifications for old messages if we don't persist state.
        // A simple fix: If known is null, set it to current but don't notify? 
        // Or if we want to be persistent, we'd need shared_preferences.
        // For this migration, satisfying the existing logic (which was memory-only map) is enough.
        // If `known` is null, we set it. We only notify if `known != null` and `new > known`? 
        // The original code: `if (known == null || lastMessageAt.compareTo(known) > 0)` 
        // It meant it notified even on first load? That seems spammy on restart.
        // Usually you want to load initial state without notifying.
        
        // Let's improve: if known is null, just set it and continue.
        // Unless logic specifically wanted to notify on missed messages? 
        // Original logic: `if (known == null || lastMessageAt.compareTo(known) > 0)` -> Notify.
        // This implies every app restart triggers notifications for the last message of every conversation.
        // That seems like a bug or poor design in original, but I will stick to it or improve slightly to avoid spam.
        // I'll stick to original logic to minimize behavioral change risks, but maybe filter by "recent" (e.g. last 5 mins) if known is null to avoid old junk.
        // But let's just replicate original logic:
        
        if (known == null || lastMessageAt.isAfter(known)) {
          _lastKnownMessageTimes[conversationId] = lastMessageAt;
          
          // Only notify if sender is not me
          if (lastMessageSenderId != userId) {
            // Also, to avoid spam on initial load (if known was null), we typically check if message is actually recent?
            // But if I strictly follow migration, I keep it.
             _showNotification(
              conversationId: conversationId,
              currentUserId: userId,
              message: data['lastMessage'] as String? ?? 'Yeni bir mesajınız var',
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
    
    // Extract other user from convo ID
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


