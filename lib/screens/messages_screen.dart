import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('members', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz konuşma yok.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final members = (data['members'] as List<dynamic>).cast<String>();
              final otherUserId = members.firstWhere((m) => m != currentUserId, orElse: () => '');
              final lastMessage = data['lastMessage'] as String? ?? '';
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  String displayName = otherUserId;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final data = userSnap.data!.data();
                    final n = (data?['name'] as String?)?.trim();
                    if (n != null && n.isNotEmpty) displayName = n;
                  }
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
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
          );
        },
      ),
    );
  }
}


