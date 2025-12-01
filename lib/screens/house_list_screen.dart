import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/cities.dart';
import '../widgets/alert_subscription_dialog.dart';
import '../widgets/premium_alert_banner.dart';

class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  // Firestore-backed; remove demo data

  String _selectedCity = 'Tümü';
  bool _isSubscribed = false;

  void _addNewListing() {
    _showAddListingDialog();
  }

  Future<void> _openSubscriptionDialog() async {
    final Map<String, dynamic> criteria = {
      'city': _selectedCity == 'Tümü' ? null : _selectedCity,
      'category': 'house',
    };
    final summary = <String, String>{
      'Şehir': _selectedCity,
      'Kategori': 'Müstakil Ev',
    };
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertSubscriptionDialog(
        criteria: criteria,
        summary: summary,
      ),
    );
    if (result == true && mounted) {
      setState(() {
        _isSubscribed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aboneliğiniz başlatıldı. Premium aktif!')),
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream() {
    final query = FirebaseFirestore.instance
        .collection('listings')
        .where('category', isEqualTo: 'house');
    if (_selectedCity == 'Tümü') return query.snapshots();
    return query.where('city', isEqualTo: _selectedCity).snapshots();
  }

  void _showAddListingDialog() {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String price = '';
    String location = '';
    String city = _selectedCity == 'Tümü' ? 'İstanbul' : _selectedCity;
    String imageUrl = '';
    bool petsAllowed = false;
    final List<String> images = [];
    String ownerName = '';
    final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // House/Apartment common features
    String roomCount = '';
    bool hasBalcony = false;
    String balconyCount = '';
    String buildingFloors = '';
    String apartmentFloor = '';
    String bathrooms = '';
    String buildingAge = '';
    String squareMeters = '';
    String heating = '';
    bool hasElevator = false;
    bool inComplex = false;
    bool hasDues = false;
    String duesAmount = '';
    String addressDirections = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          title: const Text('Yeni İlan Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    onSaved: (v) => title = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'İlan Sahibi Adı'),
                    onSaved: (v) => ownerName = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    onSaved: (v) => description = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                    onSaved: (v) => price = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Konum (örn. Üsküdar, İstanbul)'),
                    onSaved: (v) => location = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: city,
                    items: trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDialogState(() => city = v ?? city),
                    decoration: const InputDecoration(labelText: 'Şehir'),
                  ),
                  const SizedBox(height: 8),
                  // ownerId artık otomatik atanıyor; kullanıcıdan alınmıyor
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await _pickImages();
                        if (picked != null && picked.isNotEmpty) {
                          images
                            ..clear()
                            ..addAll(picked);
                          setDialogState(() {});
                          formKey.currentState?.validate();
                          if (picked.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('En az 4 görsel seçmelisiniz. Şu anda ${picked.length} görsel seçtiniz.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Görsel seçilemedi. Lütfen tekrar deneyin.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri\'den görsel seç (min 4)'),
                    ),
                  ),
                  if (images.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: images
                          .map((p) => ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  File(p),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: petsAllowed,
                    onChanged: (v) => setDialogState(() => petsAllowed = v),
                    title: const Text('Evcil hayvan var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  // House features (same as apartment)
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Oda sayısı (örn. 3+1)'),
                    onSaved: (v) => roomCount = v?.trim() ?? '',
                  ),
                  SwitchListTile(
                    value: hasBalcony,
                    onChanged: (v) => setDialogState(() => hasBalcony = v),
                    title: const Text('Balkon var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Balkon sayısı'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => balconyCount = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Bina kaç katlı?'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => buildingFloors = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Daire kaçıncı katta?'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => apartmentFloor = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Kaç tuvalet/banyo?'),
                    onSaved: (v) => bathrooms = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Bina yaşı'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => buildingAge = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'm²'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => squareMeters = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Isıtma'),
                    onSaved: (v) => heating = v?.trim() ?? '',
                  ),
                  SwitchListTile(
                    value: hasElevator,
                    onChanged: (v) => setDialogState(() => hasElevator = v),
                    title: const Text('Asansör var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: inComplex,
                    onChanged: (v) => setDialogState(() => inComplex = v),
                    title: const Text('Site içerisinde mi?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: hasDues,
                    onChanged: (v) => setDialogState(() => hasDues = v),
                    title: const Text('Aidat var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Aidat (TL)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => duesAmount = v?.trim() ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Adres tarifi'),
                    onSaved: (v) => addressDirections = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                if (images.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('En az 4 görsel ekleyin.')),
                  );
                  return;
                }

                String finalOwnerName = ownerName;
                try {
                  final uid = ownerId;
                  if (uid.isNotEmpty) {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                    if (userDoc.exists) {
                      finalOwnerName = (userDoc.data()?['name'] as String?)?.trim().isNotEmpty == true
                          ? (userDoc.data()?['name'] as String)
                          : finalOwnerName;
                    }
                  }
                } catch (_) {}

                await FirebaseFirestore.instance.collection('listings').add({
                  'title': title,
                  'description': description,
                  'price': '₺$price',
                  'location': location.isEmpty ? city : location,
                  'city': city,
                  'imageUrl': imageUrl,
                  'petsAllowed': petsAllowed,
                  'images': images,
                  'ownerName': finalOwnerName.isNotEmpty ? finalOwnerName : ownerName,
                  'ownerId': ownerId,
                  'category': 'house',
                  'roomCount': roomCount,
                  'hasBalcony': hasBalcony,
                  'balconyCount': balconyCount,
                  'buildingFloors': buildingFloors,
                  'apartmentFloor': apartmentFloor,
                  'bathrooms': bathrooms,
                  'buildingAge': buildingAge,
                  'squareMeters': squareMeters,
                  'heating': heating,
                  'hasElevator': hasElevator,
                  'inComplex': inComplex,
                  'hasDues': hasDues,
                  'duesAmount': duesAmount,
                  'addressDirections': addressDirections,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'House Listings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumAlertBanner(onSubscribe: _openSubscriptionDialog),
              if (_isSubscribed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                      SizedBox(width: 4),
                      Text('Premium Abonelik Aktif', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Available Houses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      items: [
                        const DropdownMenuItem(value: 'Tümü', child: Text('Tüm Şehirler')),
                        ...trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      ],
                      onChanged: (v) { if (v != null) setState(() => _selectedCity = v); },
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.location_city, color: Color(0xFFD4AF37)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _listingsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Sonuç bulunamadı'));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        return _buildListingCard(data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewListing,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/listing-detail',
              arguments: { 'listing': listing },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image placeholder
                _buildImage(listing),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final ownerId = listing['ownerId'] as String?;
                          if (ownerId != null && ownerId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              '/user-profile',
                              arguments: {'userId': ownerId},
                            );
                          }
                        },
                        child: Text(
                          listing['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B4513),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFCD853F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing['location'],
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF8B4513),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing['price'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> listing) {
    final List<dynamic>? localImages = listing['images'] as List<dynamic>?;
    if (localImages != null && localImages.isNotEmpty) {
      final String firstPath = localImages.first as String;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(firstPath),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return _imagePlaceholder();
          },
        ),
      );
    }
    final String? imageUrl = listing['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return _imagePlaceholder();
          },
        ),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.home,
        size: 40,
        color: Color(0xFFD4AF37),
      ),
    );
  }

  Future<List<String>?> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage(imageQuality: 90);
      if (files.isEmpty) return null;
      return files.map((f) => f.path).toList();
    } catch (e) {
      debugPrint('Görsel seçme hatası: $e');
      return null;
    }
  }
}
