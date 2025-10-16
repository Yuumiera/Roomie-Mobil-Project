import 'package:flutter/material.dart';
import '../utils/cities.dart';

class DormitoryListScreen extends StatefulWidget {
  const DormitoryListScreen({super.key});

  @override
  State<DormitoryListScreen> createState() => _DormitoryListScreenState();
}

class _DormitoryListScreenState extends State<DormitoryListScreen> {
  // Sample dormitory listings data
  final List<Map<String, dynamic>> _dormitoryListings = [
    {
      'title': 'University Dormitory - Room 205',
      'description': 'Single room with shared bathroom',
      'price': '₺800/month',
      'location': 'Near University Campus',
      'image': 'assets/images/dormitory1.jpg',
      'city': 'İstanbul',
      'type': 'Oda Değişimi',
      'category': 'dormitory',
    },
    {
      'title': 'Student Housing Complex',
      'description': 'Double room with private bathroom',
      'price': '₺1200/month',
      'location': 'Downtown Area',
      'image': 'assets/images/dormitory2.jpg',
      'city': 'Ankara',
      'type': 'Yurt Değişimi',
      'category': 'dormitory',
    },
    {
      'title': 'Modern Dormitory Building',
      'description': 'Triple room with common area',
      'price': '₺600/month',
      'location': 'City Center',
      'image': 'assets/images/dormitory3.jpg',
      'city': 'İzmir',
      'type': 'Oda Değişimi',
      'category': 'dormitory',
    },
  ];

  String _selectedCity = 'Tümü';
  int _selectedTabIndex = 0; // 0: Oda Değişimi, 1: Yurt Değişimi

  void _addNewListing() {
    _showAddListingDialog();
  }

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
    // Dormitory-specific
    String roomCapacity = '';
    String bedType = 'Baza';
    bool bathroomInRoom = false;
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
                    onChanged: (v) => city = v ?? city,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'Oda Değişimi', child: Text('Oda Değişimi')),
                      DropdownMenuItem(value: 'Yurt Değişimi', child: Text('Yurt Değişimi')),
                    ],
                    onChanged: (v) => type = v ?? type,
                    decoration: const InputDecoration(labelText: 'Kategori'),
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
                  Builder(
                    builder: (context) {
                      return Visibility(
                        visible: true,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: images
                              .map((p) => SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Image.asset(
                                      p,
                                      fit: BoxFit.cover,
                                    ),
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: petsAllowed,
                    onChanged: (v) { petsAllowed = v; },
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
                    onChanged: (v) => bedType = v ?? bedType,
                    decoration: const InputDecoration(labelText: 'Yatak tipi'),
                  ),
                  SwitchListTile(
                    value: bathroomInRoom,
                    onChanged: (v) { bathroomInRoom = v; },
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
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();
                if (images.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('En az 4 görsel ekleyin.')),
                  );
                  return;
                }

                // Duplicate prevention: same title + city + type only once
                final bool exists = _dormitoryListings.any((l) =>
                    (l['title'] as String).toLowerCase() == title.toLowerCase() &&
                    (l['city'] as String?) == city &&
                    (l['type'] as String?) == type);
                if (exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aynı ilan zaten mevcut.')),
                  );
                  return;
                }

                setState(() {
                  _dormitoryListings.add({
                    'title': title,
                    'description': description,
                    'price': '₺$price',
                    'location': location,
                    'image': 'assets/images/dormitory1.jpg',
                    'imageUrl': imageUrl,
                    'city': city,
                    'type': type,
                    'petsAllowed': petsAllowed,
                    'images': images,
                    'ownerName': ownerName,
                    'category': 'dormitory',
                    'roomCapacity': roomCapacity,
                    'bedType': bedType,
                    'bathroomInRoom': bathroomInRoom,
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

  Future<List<String>?> _pickImages() async {
    try {
      // Deferred import to avoid adding import at top if not used
      // ignore: unnecessary_import
      // Using image_picker
      // Keep it simple: dynamic import here avoided; add at top when needed.
      // We will import and use ImagePicker here directly.
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> get _filteredListings {
    final String currentType = _selectedTabIndex == 0 ? 'Oda Değişimi' : 'Yurt Değişimi';
    return _dormitoryListings.where((l) {
      final bool typeOk = (l['type'] == currentType);
      final bool cityOk = _selectedCity == 'Tümü' || (l['city'] == _selectedCity);
      return typeOk && cityOk;
    }).toList();
  }

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
                child: _filteredListings.isEmpty
                    ? const Center(
                        child: Text('Sonuç bulunamadı'),
                      )
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
        backgroundColor: const Color(0xFF4CAF50),
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
