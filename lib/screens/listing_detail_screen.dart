import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Map<String, dynamic> listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final String title = listing['title'] ?? '';
    final String description = listing['description'] ?? '';
    final String price = listing['price'] ?? '';
    final String location = listing['location'] ?? '';
    final String? imageUrl = listing['imageUrl'] as String?;
    final List<dynamic>? images = listing['images'] as List<dynamic>?; // List<String> of local paths
    final bool? petsAllowed = listing['petsAllowed'] as bool?;
    final String ownerName = (listing['ownerName'] as String?) ?? 'Kullanıcı';
    final String category = (listing['category'] as String?) ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: Text(
          title.isEmpty ? 'İlan Detayı' : title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images != null && images.isNotEmpty)
                _imagesGallery(images.cast<String>())
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _placeholder();
                            },
                          )
                        : _placeholder(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final String ownerId = (listing['ownerId'] as String?) ?? '';
                  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  // Enable message button if ownerId exists and is not the current user
                  final bool canMessage = ownerId.isNotEmpty && ownerId != currentUid;
                  return Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: ownerId.isEmpty
                              ? null
                              : FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                          builder: (context, snap) {
                            String displayName = ownerName;
                            if (snap.hasData && snap.data!.exists) {
                              final data = snap.data!.data();
                              final n = (data?['name'] as String?)?.trim();
                              if (n != null && n.isNotEmpty) displayName = n;
                            }
                            return Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
                          },
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (canMessage) {
                            final String finalOwnerName = ownerName;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: ownerId,
                                  otherUserName: finalOwnerName,
                                ),
                              ),
                            );
                          } else if (ownerId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bu ilan için sahip bilgisi bulunamadı.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else if (ownerId == currentUid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kendi ilanınıza mesaj gönderemezsiniz.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.message, color: canMessage ? null : Colors.grey),
                        label: Text(
                          'Mesaj gönder',
                          style: TextStyle(color: canMessage ? null : Colors.grey),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: canMessage ? null : Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF8B4513)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),
              if (petsAllowed != null)
                Row(
                  children: [
                    Icon(
                      petsAllowed ? Icons.pets : Icons.block,
                      size: 18,
                      color: petsAllowed ? const Color(0xFF4CAF50) : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      petsAllowed ? 'Evcil hayvan kabul edilir' : 'Evcil hayvan kabul edilmez',
                      style: TextStyle(
                        fontSize: 14,
                        color: petsAllowed ? const Color(0xFF4CAF50) : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              if (petsAllowed != null) const SizedBox(height: 16),
              const Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Color(0xFFCD853F)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Özellikler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF8B4513)),
              ),
              const SizedBox(height: 8),
              _buildFeatures(category, listing),
              const SizedBox(height: 16),
              const Text(
                'Adres Tarifi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF8B4513)),
              ),
              const SizedBox(height: 8),
              Text(
                (listing['addressDirections'] as String?) ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFFCD853F)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF4CAF50).withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.bed, size: 56, color: Color(0xFF4CAF50)),
      ),
    );
  }

  Widget _buildFeatures(String category, Map<String, dynamic> l) {
    List<Widget> rows = [];
    if (category == 'apartment' || category == 'house') {
      final items = <String, String?>{
        'Oda sayısı': l['roomCount'] as String?,
        'Balkon var mı': (l['hasBalcony'] == true) ? 'Evet' : 'Hayır',
        'Balkon sayısı': l['balconyCount'] as String?,
        'Bina kaç katlı': l['buildingFloors'] as String?,
        'Daire kaçıncı kat': l['apartmentFloor'] as String?,
        'Tuvalet/Banyo': l['bathrooms'] as String?,
        'Bina yaşı': l['buildingAge'] as String?,
        'm²': l['squareMeters'] as String?,
        'Isıtma': l['heating'] as String?,
        'Asansör': (l['hasElevator'] == true) ? 'Var' : 'Yok',
        'Site içinde': (l['inComplex'] == true) ? 'Evet' : 'Hayır',
        'Aidat': (l['hasDues'] == true) ? ((l['duesAmount'] as String?) ?? '-') : 'Yok',
      };
      rows = items.entries.map((e) => _featureRow(e.key, e.value ?? '-')).toList();
    } else if (category == 'dormitory') {
      final items = <String, String?>{
        'Oda kaç kişilik': l['roomCapacity'] as String?,
        'Yatak tipi': l['bedType'] as String?,
        'WC/Banyo oda içinde': (l['bathroomInRoom'] == true) ? 'Evet' : 'Hayır',
      };
      rows = items.entries.map((e) => _featureRow(e.key, e.value ?? '-')).toList();
    } else {
      return const Text('-');
    }
    return Column(children: rows);
  }

  Widget _featureRow(String label, String value) {
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

  bool _isNetworkUrl(String path) => path.startsWith('http://') || path.startsWith('https://');

  Widget _buildImageWidget(String path, {double? width, double? height}) {
    if (_isNetworkUrl(path)) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF4CAF50).withOpacity(0.08),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF4CAF50),
              ),
            ),
          );
        },
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }

  Widget _imagesGallery(List<String> paths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              itemCount: paths.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                final path = paths[index];
                return _buildImageWidget(path);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            itemBuilder: (context, i) {
              final bool isSelected = i == _currentImageIndex;
              final path = paths[i];
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentImageIndex = i);
                },
                child: Container(
                  margin: EdgeInsets.only(right: i == paths.length - 1 ? 0 : 8),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(path, width: 100, height: 72),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


