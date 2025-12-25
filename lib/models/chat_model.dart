import 'package:flutter/foundation.dart';

class Chat {
  final String id;
  final List<String> members;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
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
    
    final membersList = (json['members'] as List<dynamic>? ?? []).cast<String>();
    
    
    final unreadMap = <String, int>{};
    if (json['unreadCount'] != null && json['unreadCount'] is Map) {
      final map = json['unreadCount'] as Map<String, dynamic>;
      map.forEach((key, value) {
        unreadMap[key] = value is int ? value : 0;
      });
    }
    
    
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
