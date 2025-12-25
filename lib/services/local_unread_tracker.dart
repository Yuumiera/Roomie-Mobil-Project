import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUnreadTracker {
  LocalUnreadTracker._internal();
  static final LocalUnreadTracker instance = LocalUnreadTracker._internal();
  
  static const String _prefix = 'last_seen_';
  
  
  Future<void> markConversationAsSeen(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('$_prefix$conversationId', now);
  }
  
  
  Future<DateTime?> getLastSeenTime(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_prefix$conversationId');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  
  Future<bool> hasUnread(String conversationId, DateTime lastMessageTime, String lastMessageSenderId, String currentUserId) async {
    
    if (lastMessageSenderId == currentUserId || lastMessageSenderId.isEmpty) {
      // debugPrint('🚫 Sender is current user or empty. Sender: $lastMessageSenderId, Me: $currentUserId');
      return false;
    }
    
    final lastSeen = await getLastSeenTime(conversationId);
    
    
    if (lastSeen == null) return true;
    
    return lastMessageTime.isAfter(lastSeen);
  }
  
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
