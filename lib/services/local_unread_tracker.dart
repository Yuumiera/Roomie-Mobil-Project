import 'package:shared_preferences/shared_preferences.dart';

class LocalUnreadTracker {
  LocalUnreadTracker._internal();
  static final LocalUnreadTracker instance = LocalUnreadTracker._internal();
  
  static const String _prefix = 'last_seen_';
  
  /// Mark a conversation as seen at the current time
  Future<void> markConversationAsSeen(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('$_prefix$conversationId', now);
  }
  
  /// Get the last time this conversation was seen
  Future<DateTime?> getLastSeenTime(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_prefix$conversationId');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  /// Check if a conversation has unread messages
  /// Returns true if lastMessageTime is after lastSeenTime
  Future<bool> hasUnread(String conversationId, DateTime lastMessageTime, String lastMessageSenderId, String currentUserId) async {
    // If I sent the last message, it's not unread for me
    if (lastMessageSenderId == currentUserId || lastMessageSenderId.isEmpty) {
      return false;
    }
    
    final lastSeen = await getLastSeenTime(conversationId);
    
    // If never seen, consider it unread
    if (lastSeen == null) return true;
    
    // If last message is after last seen time, it's unread
    return lastMessageTime.isAfter(lastSeen);
  }
  
  /// Clear all tracking data (for logout, etc.)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
