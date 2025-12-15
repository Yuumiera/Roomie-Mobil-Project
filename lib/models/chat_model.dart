import 'package:flutter/foundation.dart';

class Chat {
  final String id;
  final List<String> members;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime; // Optional: to sort by time
  final Map<String, int> unreadCount;

  Chat({
    required this.id,
    required this.members,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Parse members
    final membersList = (json['members'] as List<dynamic>? ?? []).cast<String>();
    
    // Parse unreadCount (kept for future backend support, currently unused)
    final unreadMap = <String, int>{};
    
    // Parse lastMessageTime
    DateTime time = DateTime.now();
    var timeRaw = json['lastMessageAt'] ?? json['updatedAt'];
    if (timeRaw != null) {
      if (timeRaw is String) {
        time = DateTime.tryParse(timeRaw) ?? DateTime.now();
      } else if (timeRaw is int) {
        time = DateTime.fromMillisecondsSinceEpoch(timeRaw);
      } else if (timeRaw is Map && timeRaw['_seconds'] != null) {
         final int seconds = timeRaw['_seconds'];
         final int nanoseconds = timeRaw['_nanoseconds'] ?? 0;
         time = DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
      }
    }

    return Chat(
      id: json['_id'] ?? json['id'] ?? '',
      members: membersList,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: time,
      unreadCount: unreadMap,
      lastMessageSenderId: json['lastMessageSenderId'] as String? ?? '',
    );
  }
}
