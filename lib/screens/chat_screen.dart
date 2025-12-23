import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUserId, required this.otherUserName});

  final String otherUserId;
  final String otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final String _currentUserId;
  late final String _conversationId;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _conversationId = _buildConversationId(_currentUserId, widget.otherUserId);
    _loadMessages();
    
    // Mark conversation as read
    if (_currentUserId.isNotEmpty) {
      ApiService.markConversationAsRead(_conversationId, _currentUserId).catchError((e) {
        debugPrint('Error marking as read: $e');
      });
    }
    
    // Poll every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(background: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  String _buildConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<void> _loadMessages({bool background = false}) async {
    if (_currentUserId.isEmpty) return;
    try {
      final msgs = await ApiService.fetchMessages(_conversationId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          if (!background) _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !background) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId.isEmpty) return;

    // Optimistically add message to UI immediately
    final optimisticMessage = {
      'senderId': _currentUserId,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    setState(() {
      _messages.insert(0, optimisticMessage); // Add to front (newest)
    });
    
    _messageController.clear();

    try {
      await ApiService.sendMessage(
        _conversationId,
        _currentUserId,
        text,
        [_currentUserId, widget.otherUserId]
      );
      // Reload messages from backend to sync
      await _loadMessages(background: true);
    } catch (e) {
      // Remove optimistic message on error
      setState(() {
        _messages.removeWhere((m) => 
          m['senderId'] == _currentUserId && 
          m['text'] == text &&
          m['createdAt'] == optimisticMessage['createdAt']
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/user-profile',
              arguments: {'userId': widget.otherUserId},
            );
          },
          child: FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.fetchUser(widget.otherUserId),
            builder: (context, snap) {
              String name = widget.otherUserName;
              if (snap.hasData && snap.data != null) {
                final n = (snap.data!['name'] as String?)?.trim();
                if (n != null && n.isNotEmpty) name = n;
              }
              return Column(
                children: [
                  Text(name.isEmpty ? 'Sohbet' : name),
                  const Text(
                    'Profili Gör',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFDF6E3),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Henüz mesaj yok.'))
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          // Messages are fetched latest first in API (descending).
                          // ListView is reverse: true, so index 0 is at bottom.
                          // If API returns desc (newest first), then index 0 is newest.
                          // So it matches reverse: true.
                          final data = _messages[index];
                          final isMine = data['senderId'] == _currentUserId;
                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMine ? const Color(0xFF4CAF50) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: TextStyle(
                                  color: isMine ? Colors.white : const Color(0xFF8B4513),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


