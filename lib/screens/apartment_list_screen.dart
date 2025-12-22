import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/cities.dart';
import '../widgets/alert_subscription_dialog.dart';
import '../widgets/premium_alert_banner.dart';
import '../services/api_service.dart';

class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({super.key});

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  String _selectedCity = 'Tümü';
  // We use a Future for the API call
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    setState(() {
      _listingsFuture = ApiService.fetchListings(city: _selectedCity);
    });
  }

  Future<void> _openSubscriptionDialog() async {
    final Map<String, dynamic> criteria = {
      'city': _selectedCity == 'Tümü' ? null : _selectedCity,
      'category': 'apartment',
    };
    final summary = <String, String>{
      'Şehir': _selectedCity,
      'Kategori': 'Apartman',
    };
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertSubscriptionDialog(
        criteria: criteria,
        summary: summary,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aboneliğiniz başlatıldı.')),
      );
    }
  }

  void _addNewListing() {
    _showListingDialog();
  }

  void _showListingDialog({Map<String, dynamic>? existingListing}) {
    final bool isEditing = existingListing != null;
    final String? listingId = existingListing?['id'] as String?;
    final formKey = GlobalKey<FormState>();
    String title = existingListing?['title'] as String? ?? '';
    String description = existingListing?['description'] as String? ?? '';
    String price = (existingListing?['price'] as String? ?? '').replaceAll('₺', '').trim();
    String location = existingListing?['location'] as String? ?? '';
    String city = existingListing?['city'] as String? ?? (_selectedCity == 'Tümü' ? 'İstanbul' : _selectedCity);
    String imageUrl = existingListing?['imageUrl'] as String? ?? '';
    bool petsAllowed = existingListing?['petsAllowed'] as bool? ?? false;
    final List<String> images = List<String>.from(existingListing?['images'] as List? ?? []);
    String ownerName = existingListing?['ownerName'] as String? ?? '';
    final String ownerId = existingListing?['ownerId'] as String? ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    // Apartment/House common features
    String roomCount = existingListing?['roomCount'] as String? ?? '';
    bool hasBalcony = existingListing?['hasBalcony'] as bool? ?? false;
    String balconyCount = existingListing?['balconyCount'] as String? ?? '';
    String buildingFloors = existingListing?['buildingFloors'] as String? ?? '';
    String apartmentFloor = existingListing?['apartmentFloor'] as String? ?? '';
    String bathrooms = existingListing?['bathrooms'] as String? ?? '';
    String buildingAge = existingListing?['buildingAge'] as String? ?? '';
    String squareMeters = existingListing?['squareMeters'] as String? ?? '';
    String heating = existingListing?['heating'] as String? ?? '';
    bool hasElevator = existingListing?['hasElevator'] as bool? ?? false;
    bool inComplex = existingListing?['inComplex'] as bool? ?? false;
    bool hasDues = existingListing?['hasDues'] as bool? ?? false;
    String duesAmount = existingListing?['duesAmount'] as String? ?? '';
    String addressDirections = existingListing?['addressDirections'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          title: Text(isEditing ? 'İlanı Düzenle' : 'Yeni İlan Ekle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    onSaved: (v) => title = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    initialValue: ownerName,
                    decoration: const InputDecoration(labelText: 'İlan Sahibi Adı'),
                    onSaved: (v) => ownerName = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    onSaved: (v) => description = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    initialValue: price,
                    decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                    onSaved: (v) => price = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Konum (örn. Beşiktaş, İstanbul)'),
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
                      children: images.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String path = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(path),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    images.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: petsAllowed,
                    onChanged: (v) => setDialogState(() => petsAllowed = v),
                    title: const Text('Evcil hayvan var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  // Apartment specific features
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Oda sayısı (örn. 2+1)'),
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
                    final userMap = await ApiService.fetchUser(uid);
                    if (userMap != null) {
                      finalOwnerName = (userMap['name'] as String?)?.trim().isNotEmpty == true
                          ? (userMap['name'] as String)
                          : finalOwnerName;
                    }
                  }
                } catch (_) {}

                final listingData = {
                  'title': title,
                  'description': description,
                  'price': '₺$price',
                  'location': location.isEmpty ? city : location,
                  'city': city,
                  'imageUrl': imageUrl,
                  'petsAllowed': petsAllowed,
                  'images': images, // local paths won't sync; keep optional
                  'ownerName': finalOwnerName.isNotEmpty ? finalOwnerName : ownerName,
                  'ownerId': ownerId,
                  'category': 'apartment',
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
                  // timestamps added by backend
                };

                if (isEditing && listingId != null) {
                  await ApiService.updateListing(listingId, listingData);
                } else {
                  await ApiService.createListing(listingData);
                }
                
                Navigator.pop(context);
                // Refresh the list through API
                _loadListings();
              },
              child: Text(isEditing ? 'Güncelle' : 'Ekle'),
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
          'Apartment Listings',
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
              const SizedBox(height: 16),
              Text(
                'Available Apartments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_city, color: Color(0xFF8B4513)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      items: [
                        const DropdownMenuItem(value: 'Tümü', child: Text('Tüm Şehirler')),
                        ...trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      ],
                      onChanged: (v) {
                        if (v != null && v != _selectedCity) {
                          setState(() => _selectedCity = v);
                          _loadListings();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Şehre göre filtrele',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _listingsFuture,
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
                              onPressed: _loadListings,
                              child: const Text('Yeniden Dene'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Sonuç bulunamadı'));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Sonuç bulunamadı'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _loadListings(),
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          return _buildListingCard(data);
                        },
                      ),
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
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final ownerId = listing['ownerId'] as String?;
    final isOwner = currentUserId != null && currentUserId == ownerId;
    final listingId = listing['id'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withOpacity(0.1),
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
                      Text(
                        listing['title'] ?? 'Başlıksız',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                            color: const Color(0xFF8B4513),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing['location'] ?? (listing['city'] ?? ''),
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
                        listing['price'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
                // Show edit/delete for owner, arrow for others
                if (isOwner && listingId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF8B4513), size: 20),
                        onPressed: () {
                          _showListingDialog(existingListing: listing);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          try {
                            await ApiService.deleteListing(listingId);
                            _loadListings(); // Refresh
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('İlan silindi')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: const Color(0xFF8B4513),
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
        color: const Color(0xFF8B4513).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.apartment,
        size: 40,
        color: Color(0xFF8B4513),
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
