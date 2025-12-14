import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Map<String, dynamic>? _userMap;
  bool _loading = true;
  bool _uploading = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _uid = user.uid;
    try {
      final data = await ApiService.fetchUser(_uid!);
      setState(() {
        _userMap = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Profil yüklenemedi: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${_uid}_profile.jpg');
      
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await ApiService.updateUser(_uid!, {'photoUrl': url});
      await _loadUser();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
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

                    const SizedBox(height: 16),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Çıkış Yap'),
                    ),
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
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: CircleAvatar(
            radius: 36,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: _uploading
                ? const CircularProgressIndicator()
                : (photoUrl == null ? const Icon(Icons.person, size: 36) : null),
          ),
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
    final String phone = (data['phone'] as String?) ?? '-';
    final String city = (data['city'] as String?) ?? '-';
    final String department = (data['department'] as String?) ?? '-';
    final String classYear = (data['classYear'] as String?) ?? '-';
    final String gender = (data['gender'] as String?) ?? '-';
    final String hasPet = (data['hasPet'] == true) ? 'Evet' : (data['hasPet'] == false) ? 'Hayır' : '-';
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
      title: 'İlanlarım',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: (_uid == null) ? Future.value([]) : ApiService.fetchListings(ownerId: _uid),
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


