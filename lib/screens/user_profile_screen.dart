import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userMap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.userId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await ApiService.fetchUser(widget.userId);
      setState(() {
        _userMap = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı profili yüklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'Kullanıcı Profili',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildBioCard(),
                    const SizedBox(height: 16),
                    _buildListingsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final data = _userMap ?? {};
    final String name = (data['name'] as String?) ?? '-';
    final String email = (data['email'] as String?) ?? '-';
    final String? photoUrl = data['photoUrl'] as String?;

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? const Icon(Icons.person, size: 36) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 14, color: Color(0xFFCD853F))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final data = _userMap ?? {};
    final String city = (data['city'] as String?) ?? '-';
    final String department = (data['department'] as String?) ?? '-';
    final String classYear = (data['classYear'] as String?) ?? '-';
    final String gender = (data['gender'] as String?) ?? '-';
    final String hasPet = (data['hasPet'] == true) ? 'Evet' : (data['hasPet'] == false) ? 'Hayır' : '-';
    final String phone = (data['phone'] as String?) ?? '-';

    return _card(
      title: 'Bilgiler',
      child: Column(
        children: [
          _infoRow('Telefon', phone),
          _infoRow('Şehir', city),
          _infoRow('Bölüm', department),
          _infoRow('Sınıf', classYear),
          _infoRow('Cinsiyet', gender),
          _infoRow('Evcil hayvan', hasPet),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    final data = _userMap ?? {};
    final String bio = (data['bio'] as String?) ?? 'Açıklama eklenmemiş';
    return _card(
      title: 'Açıklama',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          bio,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8B4513)),
        ),
      ),
    );
  }

  Widget _buildListingsCard() {
    return _card(
      title: 'İlanları',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: (widget.userId.isEmpty) ? Future.value([]) : ApiService.fetchListings(ownerId: widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: Text('Henüz ilan yok', style: TextStyle(color: Color(0xFFCD853F))),
            );
          }
           return ListView.separated(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: docs.length,
             separatorBuilder: (_, __) => const Divider(height: 1),
             itemBuilder: (context, index) {
               final data = docs[index];
               return ListTile(
                 title: Text((data['title'] as String?) ?? '-'),
                 subtitle: Text((data['price'] as String?) ?? ''),
                 trailing: const Icon(Icons.chevron_right),
                 onTap: () {
                   Navigator.pushNamed(context, '/listing-detail', arguments: { 'listing': data });
                 },
               );
             },
           );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child, Widget? action}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: Color(0xFF4CAF50))),
        ],
      ),
    );
  }
}
