import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/cities.dart';
import '../widgets/alert_subscription_dialog.dart';
import '../widgets/premium_alert_banner.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/api_service.dart'; // Added ApiService import

class DormitoryListScreen extends StatefulWidget {
  const DormitoryListScreen({super.key});

  @override
  State<DormitoryListScreen> createState() => _DormitoryListScreenState();
}

class _DormitoryListScreenState extends State<DormitoryListScreen> {
  Future<List<Map<String, dynamic>>>? _listingsFuture;

  String _selectedCity = 'Tümü';
  int _selectedTabIndex = 0; // 0: Oda Değişimi, 1: Yurt Değişimi

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() {
    final String currentType = _selectedTabIndex == 0 ? 'Oda Değişimi' : 'Yurt Değişimi';
    setState(() {
      _listingsFuture = ApiService.fetchListings(
        city: _selectedCity,
        category: 'dormitory',
      ).then((list) => list.where((item) => item['type'] == currentType).toList());
    });
  }

  void _addNewListing() {
    _showAddListingDialog();
  }

  Future<void> _openSubscriptionDialog() async {
    final String currentType = _selectedTabIndex == 0 ? 'Oda Değişimi' : 'Yurt Değişimi';
    final Map<String, dynamic> criteria = {
      'city': _selectedCity == 'Tümü' ? null : _selectedCity,
      'category': 'dormitory',
      'type': currentType,
    };
    final summary = <String, String>{
      'Şehir': _selectedCity,
      'Kategori': 'Yurt / Oda',
      'Tür': currentType,
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

  // Duplicate _pickImages removed from here.


  void _showAddListingDialog() {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String price = '';
    String location = '';
    String city = _selectedCity == 'Tümü' ? 'İstanbul' : _selectedCity;
    String type = _selectedTabIndex == 0 ? 'Oda Değişimi' : 'Yurt Değişimi';
    String imageUrl = '';
    bool petsAllowed = false;
    final List<String> images = [];
    String ownerName = '';
    String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Dormitory-specific
    String roomCapacity = '';
    String bedType = 'Baza';
    bool bathroomInRoom = false;
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
                    decoration: const InputDecoration(labelText: 'Konum'),
                    onSaved: (v) => location = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: city,
                    items: const [
                      DropdownMenuItem(value: 'İstanbul', child: Text('İstanbul')),
                      DropdownMenuItem(value: 'Ankara', child: Text('Ankara')),
                      DropdownMenuItem(value: 'İzmir', child: Text('İzmir')),
                    ],
                    onChanged: (v) => setDialogState(() => city = v ?? city),
                    decoration: const InputDecoration(labelText: 'Şehir'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'Oda Değişimi', child: Text('Oda Değişimi')),
                      DropdownMenuItem(value: 'Yurt Değişimi', child: Text('Yurt Değişimi')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v ?? type),
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 8),
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
                  // Dormitory features
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Oda kaç kişilik?'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => roomCapacity = v?.trim() ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: bedType,
                    items: const [
                      DropdownMenuItem(value: 'Baza', child: Text('Baza')),
                      DropdownMenuItem(value: 'Ranza', child: Text('Ranza')),
                    ],
                    onChanged: (v) => setDialogState(() => bedType = v ?? bedType),
                    decoration: const InputDecoration(labelText: 'Yatak tipi'),
                  ),
                  SwitchListTile(
                    value: bathroomInRoom,
                    onChanged: (v) => setDialogState(() => bathroomInRoom = v),
                    title: const Text('Tuvalet/Banyo oda içinde mi?'),
                    contentPadding: EdgeInsets.zero,
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
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
                  'location': location,
                  'city': city,
                  'imageUrl': imageUrl,
                  'type': type,
                  'petsAllowed': petsAllowed,
                  'images': images,
                  'ownerName': finalOwnerName.isNotEmpty ? finalOwnerName : ownerName,
                  'ownerId': ownerId,
                  'category': 'dormitory',
                  'roomCapacity': roomCapacity,
                  'bedType': bedType,
                  'bathroomInRoom': bathroomInRoom,
                  'addressDirections': addressDirections,
                  // timestamps added by backend
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

  // _listingsStream removed
  
  // ignore: unused_element
  // Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream() { ... } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text(
          'Yurt İlanları',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
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
              // Tabs: Oda Değişimi / Yurt Değişimi
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Oda Değişimi', 0),
                    _buildTabButton('Yurt Değişimi', 1),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // City filter dropdown
              Row(
                children: [
                   const Icon(Icons.location_city, color: Color(0xFF4CAF50)),
                   const SizedBox(width: 8),
                   Expanded(
                     child: DropdownButtonFormField<String>(
                       value: _selectedCity,
                       items: [
                         const DropdownMenuItem(value: 'Tümü', child: Text('Tüm Şehirler')),
                         ...trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                       ],
                       onChanged: (v) {
                         if (v == null) return;
                         setState(() => _selectedCity = v);
                         _loadListings();
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
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1), // Home active since accessed from Home
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
            color: const Color(0xFF4CAF50).withOpacity(0.1),
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
                        listing['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(listing['description'], style: TextStyle(fontSize: 14, color: const Color(0xFFCD853F))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFF4CAF50),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing['price'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              listing['type'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> listing) {
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
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.bed,
        size: 40,
        color: Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final bool selected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
            borderRadius: index == 0
                ? const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
                : const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? const Color(0xFF4CAF50) : const Color(0xFF8B4513),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
