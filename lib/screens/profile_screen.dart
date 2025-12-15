import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';
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
    if (_uid == null) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Lower quality to reduce size
      maxWidth: 400,    // Limit dimensions
      maxHeight: 400,
    );
    if (image == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) throw Exception('Seçilen görsel boş/okunamadı.');

      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      // Check size (Firestore has 1MB document limit)
      if (base64Image.length > 500000) {
        throw Exception('Görsel çok büyük. Lütfen daha küçük bir görsel seçin.');
      }

      debugPrint('Base64 image size: ${base64Image.length} bytes');

      await ApiService.updateUser(_uid!, {'photoUrl': base64Image});
      await _loadUser();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
      );
    } catch (e) {
      debugPrint('Upload error details: $e');
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
        title: Text(
          AppLocalizations.of(LanguageController.instance.languageCode).profile,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                      child: Text(AppLocalizations.of(LanguageController.instance.languageCode).logout),
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

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photoUrl != null && photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl)
                    : null,
                child: _uploading
                    ? const CircularProgressIndicator()
                    : (photoUrl == null || !photoUrl.startsWith('data:image'))
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : ClipOval(
                            child: Image.memory(
                              base64Decode(photoUrl.split(',')[1]),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return const Icon(Icons.person, size: 50, color: Colors.grey);
                              },
                            ),
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B4513),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _pickAndUploadImage,
          child: const Text(
            'Profil Fotoğrafını Değiştir',
            style: TextStyle(color: Color(0xFF8B4513)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFCD853F),
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
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    final String hasPet = (data['hasPet'] == true) ? (loc.languageCode == 'tr' ? 'Evet' : 'Yes') : (data['hasPet'] == false) ? (loc.languageCode == 'tr' ? 'Hayır' : 'No') : '-';
    return _card(
      title: 'Information',
      child: Column(
        children: [
          _infoRow(loc.phone, phone),
          _infoRow(loc.city, city),
          _infoRow(loc.department, department),
          _infoRow(loc.classYear, classYear),
          _infoRow(loc.gender, gender),
          _infoRow(loc.hasPet, hasPet),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    final data = _userMap ?? {};
    final String bio = (data['bio'] as String?) ?? (loc.languageCode == 'tr' ? 'Açıklama eklenmemiş' : 'No bio added');
    return _card(
      title: loc.bio,
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
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    return _card(
      title: loc.myListings,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: (_uid == null) ? Future.value([]) : ApiService.fetchListings(ownerId: _uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           final docs = snapshot.data ?? [];
           if (docs.isEmpty) {
             return Align(
               alignment: Alignment.centerLeft,
               child: Text(loc.languageCode == 'tr' ? 'Henüz ilan yok' : 'No listings yet', style: const TextStyle(color: Color(0xFFCD853F))),
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


