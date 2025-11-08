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
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _conversationId = _buildConversationId(_currentUserId, widget.otherUserId);
    _messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
    _ensureConversationExists();
  }

  String _buildConversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<void> _ensureConversationExists() async {
    if (_currentUserId.isEmpty) return;
    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(_conversationId);
    final snap = await convoRef.get();
    if (!snap.exists) {
      await convoRef.set({
        'members': [_currentUserId, widget.otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId.isEmpty) return;

    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(_conversationId);
    final messagesRef = convoRef.collection('messages');
    await messagesRef.add({
      'senderId': _currentUserId,
      'text': text,
      'createdAt': Timestamp.now(),
    });
    await convoRef.update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get(),
          builder: (context, snap) {
            String name = widget.otherUserName;
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data();
              final n = (data?['name'] as String?)?.trim();
              if (n != null && n.isNotEmpty) name = n;
            }
            return Text(name.isEmpty ? 'Sohbet' : name);
          },
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream,
              key: ValueKey(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Henüz mesaj yok.'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok.'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
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


