import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _conversationId = _buildConversationId(_currentUserId, widget.otherUserId);
    
    // Mark as read
    if (_currentUserId.isNotEmpty) {
      _markAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _buildConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<void> _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .update({
        'unreadCount.$_currentUserId': 0,
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId.isEmpty) return;

    _messageController.clear();

    try {
      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId);

      // Create conversation if doesn't exist
      await conversationRef.set({
        'members': [_currentUserId, widget.otherUserId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          _currentUserId: 0,
          widget.otherUserId: 1,
        },
      }, SetOptions(merge: true));

      // Add message
      await conversationRef.collection('messages').add({
        'senderId': _currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update conversation
      await conversationRef.update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$widget.otherUserId': FieldValue.increment(1),
      });

      // Mark as read for current user
      await _markAsRead();
    } catch (e) {
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
        title: Text(
          widget.otherUserName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF4CAF50),
            height: 2.0,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDF6E3),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(_conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
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
