import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/chat_model.dart';
import 'local_unread_tracker.dart';

class UnreadService extends ChangeNotifier {
  UnreadService._internal();
  
  static final UnreadService instance = UnreadService._internal();
  
  int _totalUnread = 0;
  Timer? _pollingTimer;
  StreamSubscription<User?>? _authSub;
  
  int get totalUnread => _totalUnread;
  
  void refresh() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _checkUnreadCount(user.uid);
    }
  }

  void initialize() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _pollingTimer?.cancel();
      _totalUnread = 0;
      notifyListeners();
      
      if (user == null) return;
      _startPolling(user.uid);
    });
  }
  
  void _startPolling(String userId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkUnreadCount(userId);
    });
    _checkUnreadCount(userId);
  }
  
  Future<void> _checkUnreadCount(String userId) async {
    try {
      final conversations = await ApiService.fetchConversations(userId);
      int total = 0;
      
      for (final chat in conversations) {
        // Use LocalUnreadTracker to determine if this conversation has unread messages
        final hasUnread = await LocalUnreadTracker.instance.hasUnread(
          chat.id,
          chat.lastMessageTime,
          chat.lastMessageSenderId,
          userId,
        );
        
        if (hasUnread) {
          total += 1;  // Count as 1 unread conversation
        }
      }
      
      if (_totalUnread != total) {
        _totalUnread = total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking unread count: $e');
    }
  }
  
  void dispose() {
    _authSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
