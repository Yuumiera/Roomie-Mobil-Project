import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _loadConversations(background: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool background = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted && !background) setState(() => _loading = false);
      return;
    }
    try {
      final convs = await ApiService.fetchConversations(user.uid);
      if (mounted) {
        setState(() {
          _conversations = convs;
          if (!background) _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !background) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Lütfen giriş yapınız.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('Henüz konuşma yok.'))
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = _conversations[index];
                    final members = (data['members'] as List<dynamic>).cast<String>();
                    final otherUserId = members.firstWhere((m) => m != currentUserId, orElse: () => '');
                    final lastMessage = data['lastMessage'] as String? ?? '';
                    
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: ApiService.fetchUser(otherUserId),
                      builder: (context, userSnap) {
                        String displayName = otherUserId;
                        String? photoUrl;
                        if (userSnap.hasData && userSnap.data != null) {
                          final userData = userSnap.data!;
                          final n = (userData['name'] as String?)?.trim();
                          if (n != null && n.isNotEmpty) displayName = n;
                          photoUrl = userData['photoUrl'] as String?;
                        }
                        
                        Widget avatarChild;
                        if (photoUrl != null && photoUrl.startsWith('data:image')) {
                          avatarChild = ClipOval(
                            child: Image.memory(
                              base64Decode(photoUrl.split(',')[1]),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return const Icon(Icons.person);
                              },
                            ),
                          );
                        } else if (photoUrl != null && photoUrl.startsWith('http')) {
                          avatarChild = ClipOval(
                            child: Image.network(
                              photoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return const Icon(Icons.person);
                              },
                            ),
                          );
                        } else {
                          avatarChild = const Icon(Icons.person);
                        }
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: avatarChild,
                          ),
                          title: Text(displayName),
                          subtitle: Text(
                            lastMessage.isEmpty ? 'Yeni konuşma' : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: otherUserId,
                                  otherUserName: displayName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
}


