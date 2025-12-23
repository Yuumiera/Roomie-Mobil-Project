import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../utils/cities.dart';
import '../widgets/alert_subscription_dialog.dart';
import '../widgets/premium_alert_banner.dart';
import '../widgets/app_bottom_nav.dart';

class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  String _selectedCity = 'Tümü';
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    setState(() {
      _listingsFuture = ApiService.fetchListings(
        category: 'house',
        city: _selectedCity,
      );
    });
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aboneliğiniz başlatıldı.')),
      );
    }
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
    String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    String roomCount = '';
    bool hasGarden = false;
    bool hasGarage = false;
    String heating = 'Kombi';
    String squareMeters = '';
    String addressDirections = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Müstakil Ev İlanı'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Başlık'),
                          onSaved: (v) => title = v?.trim() ?? '',
                          validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Açıklama'),
                          onSaved: (v) => description = v?.trim() ?? '',
                          maxLines: 3,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Fiyat (TL)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => price = v?.trim() ?? '',
                          validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                        ),
                         DropdownButtonFormField<String>(
                          value: city,
                          items: trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setDialogState(() => city = v!),
                          decoration: const InputDecoration(labelText: 'Şehir'),
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'İlçe / Mahalle'),
                          onSaved: (v) => location = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Oda Sayısı (örn: 3+1)'),
                          onSaved: (v) => roomCount = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Metrekare (m2)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => squareMeters = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Isıtma'),
                          initialValue: heating,
                          onSaved: (v) => heating = v?.trim() ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Adres Tarifi'),
                          onSaved: (v) => addressDirections = v?.trim() ?? '',
                        ),
                        SwitchListTile(
                          value: petsAllowed,
                          onChanged: (v) => setDialogState(() => petsAllowed = v),
                          title: const Text('Evcil Hayvan İzinli mi?'),
                        ),
                        SwitchListTile(
                          value: hasGarden,
                          onChanged: (v) => setDialogState(() => hasGarden = v),
                          title: const Text('Bahçeli mi?'),
                        ),
                        SwitchListTile(
                          value: hasGarage,
                          onChanged: (v) => setDialogState(() => hasGarage = v),
                          title: const Text('Garajı var mı?'),
                        ),
                         const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                             final picked = await _pickImages();
                             if (picked != null) {
                               setDialogState(() {
                                 images.addAll(picked);
                               });
                             }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: Text('Görsel Seç (${images.length})'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
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

                    await ApiService.createListing({
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
                       'hasGarden': hasGarden,
                       'hasGarage': hasGarage,
                       'heating': heating,
                       'squareMeters': squareMeters,
                       'addressDirections': addressDirections,
                       
                    });
                    if (mounted) Navigator.pop(context);
                    _loadListings();
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

  Future<List<String>?> _pickImages() async {
     try {
       final ImagePicker picker = ImagePicker();
       final List<XFile> files = await picker.pickMultiImage(imageQuality: 90);
       if (files.isEmpty) return null;
       return files.map((f) => f.path).toList();
     } catch (e) {
       return null;
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'Müstakil Ev',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF8B4513),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF4CAF50),
            height: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumAlertBanner(onSubscribe: _openSubscriptionDialog),
              const SizedBox(height: 16),
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
                         if (v != null) {
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
                       return Center(child: Text('Hata: ${snapshot.error}'));
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('Sonuç bulunamadı'));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                         final data = docs[index];
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
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
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
                _buildImage(listing),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      Text(
                        listing['location'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        listing['price'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8B4513)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> listing) {
    
    String? path;
    if (listing['images'] != null && (listing['images'] as List).isNotEmpty) {
       path = (listing['images'] as List)[0];
    } else if (listing['imageUrl'] != null && (listing['imageUrl'] as String).isNotEmpty) {
       path = listing['imageUrl'];
    }

    if (path != null) {
      
      if (path.startsWith('http')) {
         return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(path, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => _imagePlaceholder()),
         ); 
      } else {
         return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => _imagePlaceholder()),
         ); 
      }
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
      child: const Icon(Icons.home, color: Color(0xFF8B4513)),
    );
  }
}
