import 'package:flutter/material.dart';
import 'dart:io';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Map<String, dynamic> listing;

  @override
  Widget build(BuildContext context) {
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
                _imagesGallery(images)
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
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ownerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: hook messaging when ready
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj gönder')));
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Mesaj gönder'),
                  )
                ],
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

  Widget _imagesGallery(List<dynamic> images) {
    final List<String> paths = images.cast<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                return Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _placeholder(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final path = paths[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 100,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _placeholder(),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: paths.length,
          ),
        ),
      ],
    );
  }
}


