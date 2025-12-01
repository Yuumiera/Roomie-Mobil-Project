import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/chat_screen.dart';

class MessageNotificationService {
  MessageNotificationService._internal();

  static final MessageNotificationService instance = MessageNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, Timestamp?> _lastKnownMessageTimes = {};

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conversationsSub;

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
      _conversationsSub?.cancel();
      _lastKnownMessageTimes.clear();
      if (user == null) return;
      _listenForConversations(user.uid);
    });
  }

  void _listenForConversations(String userId) {
    _conversationsSub = FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? lastMessageAt = data['lastMessageAt'] as Timestamp?;
        final String? lastMessageSenderId = data['lastMessageSenderId'] as String?;
        if (lastMessageAt == null || lastMessageSenderId == null) continue;
        final known = _lastKnownMessageTimes[doc.id];
        if (known == null || lastMessageAt.compareTo(known) > 0) {
          _lastKnownMessageTimes[doc.id] = lastMessageAt;
          if (lastMessageSenderId != userId) {
            _showNotification(
              conversationId: doc.id,
              currentUserId: userId,
              message: data['lastMessage'] as String? ?? 'Yeni bir mesajınız var',
            );
          }
        }
      }
    });
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
    final otherUserId = conversationId.split('__').firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
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
    _conversationsSub?.cancel();
  }
}

