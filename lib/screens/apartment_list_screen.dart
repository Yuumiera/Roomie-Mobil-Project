import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/cities.dart';

class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({super.key});

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  // Sample apartment listings data
  final List<Map<String, dynamic>> _apartmentListings = [
    {
      'title': 'Modern 2+1 Apartment',
      'description': 'Furnished apartment with balcony',
      'price': '₺3500/month',
      'location': 'Beyoğlu, Istanbul',
      'image': 'assets/images/apartment1.jpg',
      'category': 'apartment',
    },
    {
      'title': 'Luxury Studio Apartment',
      'description': 'Fully furnished studio with city view',
      'price': '₺2800/month',
      'location': 'Kadıköy, Istanbul',
      'image': 'assets/images/apartment2.jpg',
      'category': 'apartment',
    },
    {
      'title': 'Cozy 1+1 Apartment',
      'description': 'Small apartment perfect for students',
      'price': '₺2000/month',
      'location': 'Beşiktaş, Istanbul',
      'image': 'assets/images/apartment3.jpg',
      'category': 'apartment',
    },
    {
      'title': 'Spacious 3+1 Apartment',
      'description': 'Large apartment with garden',
      'price': '₺4500/month',
      'location': 'Şişli, Istanbul',
      'image': 'assets/images/apartment4.jpg',
      'category': 'apartment',
    },
  ];

  String _selectedCity = 'Tümü';

  void _addNewListing() {
    _showAddListingDialog();
  }

  List<Map<String, dynamic>> get _filteredListings {
    return _apartmentListings.where((l) {
      final bool cityOk = _selectedCity == 'Tümü' || (l['location'] as String).contains(_selectedCity);
      return cityOk;
    }).toList();
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
    // Apartment/House common features
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
                    decoration: const InputDecoration(labelText: 'Konum (örn. Beşiktaş, İstanbul)'),
                    onSaved: (v) => location = v?.trim() ?? '',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: city,
                    items: trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => city = v ?? city,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await _pickImages();
                        if (picked != null) {
                          images
                            ..clear()
                            ..addAll(picked);
                          formKey.currentState?.validate();
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri’den görsel seç (min 4)'),
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
                    onChanged: (v) { petsAllowed = v; },
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
                    onChanged: (v) { hasBalcony = v; },
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
                    onChanged: (v) { hasElevator = v; },
                    title: const Text('Asansör var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: inComplex,
                    onChanged: (v) { inComplex = v; },
                    title: const Text('Site içerisinde mi?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: hasDues,
                    onChanged: (v) { hasDues = v; },
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
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                if (images.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('En az 4 görsel ekleyin.')),
                  );
                  return;
                }

                final bool exists = _apartmentListings.any((l) =>
                    (l['title'] as String).toLowerCase() == title.toLowerCase() &&
                    (l['location'] as String).contains(city));
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aynı ilan zaten mevcut.')),
                  );
                  return;
                }

                setState(() {
                  _apartmentListings.add({
                    'title': title,
                    'description': description,
                    'price': '₺$price',
                    'location': location.isEmpty ? city : location,
                    'image': 'assets/images/apartment1.jpg',
                    'imageUrl': imageUrl,
                    'petsAllowed': petsAllowed,
                    'images': images,
                    'ownerName': ownerName,
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
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
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
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      onChanged: (v) { if (v != null) setState(() => _selectedCity = v); },
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
                child: _filteredListings.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı'))
                    : ListView.builder(
                        itemCount: _filteredListings.length,
                        itemBuilder: (context, index) {
                          final listing = _filteredListings[index];
                          return _buildListingCard(listing);
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
                        listing['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B4513),
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
                            color: const Color(0xFF8B4513),
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
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
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
    } catch (_) {
      return null;
    }
  }
}
