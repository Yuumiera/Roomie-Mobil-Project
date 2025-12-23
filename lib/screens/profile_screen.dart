import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roomie_mobil_project/services/premium_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/alert_subscription_service.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_controller.dart';
import '../widgets/premium_badge.dart';
import '../widgets/upgrade_premium_banner.dart';
import '../widgets/app_bottom_nav.dart';

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
  bool _isPremium = false;
  int _listingsRefreshKey = 0;
  int _notificationCount = 0;

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
        _isPremium = data?['isPremium'] == true;
        _loading = false;
      });
      
      If (_isPremium) {
        _loadNotificationCount();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Profil yüklenemedi: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_uid == null) return;
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _uid)
          .where('isRead', isEqualTo: false)
          .get();
      
      if (mounted) {
        setState(() {
          _notificationCount = notifications.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Bildirim sayısı yüklenemedi: $e');
    }
  }

  Future<void> _cancelPremium() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abonelik İptali'),
        content: const Text('Premium üyeliğinizi iptal etmek istediğinize emin misiniz? Tüm avantajlarınızı kaybedeceksiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _loading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final success = await PremiumService.cancelSubscription(user.uid);
        if (success) {
           await _loadUser();
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Aboneliğiniz iptal edildi.')),
             );
           }
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('İptal işlemi başarısız.')),
             );
           }
        }
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_uid == null) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, 
      maxWidth: 400,    
      maxHeight: 400,
    );
    if (image == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) throw Exception('Seçilen görsel boş/okunamadı.');

      
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      
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

  Future<void> _deleteListing(String listingId, String title) async {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);

    debugPrint('🗑️ Attempting to delete listing: $listingId');
    
    try {
      await ApiService.deleteListing(listingId);
      debugPrint('✅ Delete successful for: $listingId');
      
      if (!mounted) return;
      
      setState(() {
        _listingsRefreshKey++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.listingDeleted)),
      );
    } catch (e) {
      debugPrint('❌ Delete error for $listingId: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _showEditListingDialog(Map<String, dynamic> listing) {
    final formKey = GlobalKey<FormState>();
    final listingId = listing['id'] as String;
    
    
    String title = listing['title'] as String? ?? '';
    String description = listing['description'] as String? ?? '';
    String price = (listing['price'] as String? ?? '').replaceAll('₺', '').trim();
    String location = listing['location'] as String? ?? '';
    String ownerName = listing['ownerName'] as String? ?? '';
    bool petsAllowed = listing['petsAllowed'] as bool? ?? false;
    
    
    String roomCount = listing['roomCount'] as String? ?? '';
    bool hasBalcony = listing['hasBalcony'] as bool? ?? false;
    String balconyCount = listing['balconyCount'] as String? ?? '';
    String buildingFloors = listing['buildingFloors'] as String? ?? '';
    String apartmentFloor = listing['apartmentFloor'] as String? ?? '';
    String bathrooms = listing['bathrooms'] as String? ?? '';
    String buildingAge = listing['buildingAge'] as String? ?? '';
    String squareMeters = listing['squareMeters'] as String? ?? '';
    String heating = listing['heating'] as String? ?? '';
    bool hasElevator = listing['hasElevator'] as bool? ?? false;
    bool inComplex = listing['inComplex'] as bool? ?? false;
    bool hasDues = listing['hasDues'] as bool? ?? false;
    String duesAmount = listing['duesAmount'] as String? ?? '';
    String addressDirections = listing['addressDirections'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('İlanı Düzenle'),
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
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    maxLines: 3,
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
                    initialValue: location,
                    decoration: const InputDecoration(labelText: 'Konum'),
                    onSaved: (v) => location = v?.trim() ?? '',
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: petsAllowed,
                    onChanged: (v) => setDialogState(() => petsAllowed = v),
                    title: const Text('Evcil hayvan var mı?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextFormField(
                    initialValue: roomCount,
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
                    initialValue: balconyCount,
                    decoration: const InputDecoration(labelText: 'Balkon sayısı'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => balconyCount = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: buildingFloors,
                    decoration: const InputDecoration(labelText: 'Bina kaç katlı?'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => buildingFloors = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: apartmentFloor,
                    decoration: const InputDecoration(labelText: 'Daire kaçıncı katta?'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => apartmentFloor = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: bathrooms,
                    decoration: const InputDecoration(labelText: 'Kaç tuvalet/banyo?'),
                    onSaved: (v) => bathrooms = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: buildingAge,
                    decoration: const InputDecoration(labelText: 'Bina yaşı'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => buildingAge = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: squareMeters,
                    decoration: const InputDecoration(labelText: 'm²'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => squareMeters = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: heating,
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
                    initialValue: duesAmount,
                    decoration: const InputDecoration(labelText: 'Aidat (TL)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => duesAmount = v?.trim() ?? '',
                  ),
                  TextFormField(
                    initialValue: addressDirections,
                    decoration: const InputDecoration(labelText: 'Adres tarifi'),
                    maxLines: 2,
                    onSaved: (v) => addressDirections = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(LanguageController.instance.languageCode).cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();

                try {
                  await ApiService.updateListing(listingId, {
                    'title': title,
                    'description': description,
                    'price': '₺$price',
                    'location': location,
                    'ownerName': ownerName,
                    'petsAllowed': petsAllowed,
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
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  setState(() {
                    _listingsRefreshKey++;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(LanguageController.instance.languageCode).listingUpdated)),
                  );
                } catch (e) {
                  debugPrint('Update error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              },
              child: Text(AppLocalizations.of(LanguageController.instance.languageCode).update),
            ),
          ],
        ),
      ),
    );
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
          if (_isPremium && _notificationCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    _showNotificationsDialog();
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _notificationCount > 0 
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF4CAF50),
            height: 2.0,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isPremium && !_loading) 
                      UpgradePremiumBanner(
                        onUpgraded: () async {
                           await _loadUser();
                           
                        },
                      ),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildBioCard(),
                    const SizedBox(height: 16),
                    _buildListingsCard(),
                    const SizedBox(height: 16),
                    if (_isPremium) _buildMyAlertsCard(),
                    if (_isPremium) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _cancelPremium,
                          child: const Text(
                            'Premium Aboneliği İptal Et',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],

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
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  void _showNotificationsDialog() {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.notifications),
              if (_notificationCount > 0)
                TextButton(
                  onPressed: () async {
                    
                    try {
                      final batch = FirebaseFirestore.instance.batch();
                      final snapshot = await FirebaseFirestore.instance
                          .collection('notifications')
                          .where('userId', isEqualTo: _uid)
                          .where('isRead', isEqualTo: false)
                          .get();
                      
                      for (var doc in snapshot.docs) {
                        batch.update(doc.reference, {'isRead': true});
                      }
                      
                      await batch.commit();
                      
                      if (mounted) {
                        setState(() {
                          _notificationCount = 0;
                        });
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('Clear all error: $e');
                    }
                  },
                  child: Text(
                    loc.languageCode == 'tr' ? 'Temizle' : 'Clear',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: _uid)
                  .where('isRead', isEqualTo: false)
                  .limit(20)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 100,
                    child: Center(child: Text('Hata: ${snapshot.error}')),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(loc.noActiveAlerts),
                    ),
                  );
                }

                
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final notif = doc.data() as Map<String, dynamic>;
                    final listingData = notif['listingData'] as Map<String, dynamic>?;
                    
                    return ListTile(
                      leading: const Icon(Icons.fiber_new, color: Colors.orange),
                      title: Text(
                        listingData?['title'] ?? (loc.languageCode == 'tr' ? 'Yeni İlan' : 'New Listing'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${listingData?['city'] ?? ''} - ${listingData?['price'] ?? ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check, size: 20, color: Colors.green),
                        onPressed: () async {
                          await doc.reference.update({'isRead': true});
                          if (mounted) {
                            setState(() {
                              _notificationCount = _notificationCount > 0 ? _notificationCount - 1 : 0;
                            });
                            Navigator.pop(context);
                            _showNotificationsDialog();
                          }
                        },
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final listingId = notif['listingId'] as String?;
                        if (listingId != null) {
                          try {
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) => const Center(child: CircularProgressIndicator()),
                            );

                            final docSnapshot = await FirebaseFirestore.instance
                                .collection('listings')
                                .doc(listingId)
                                .get();
                            
                            Navigator.of(context, rootNavigator: true).pop();

                            if (docSnapshot.exists && docSnapshot.data() != null) {
                               final listingData = docSnapshot.data()!;
                               final fullListing = Map<String, dynamic>.from(listingData);
                               fullListing['id'] = listingId;
                               
                               Navigator.pushNamed(
                                 context, 
                                 '/listing-detail', 
                                 arguments: { 'listing': fullListing }
                               );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bu ilan artık mevcut değil.')),
                              );
                            }
                          } catch (e) {
                             if (Navigator.of(context).canPop()) {
                               Navigator.of(context, rootNavigator: true).pop();
                             }
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Bir hata oluştu.')),
                             );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
          ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            if (_isPremium) ...[
               const SizedBox(width: 6),
               const PremiumBadge(size: 24),
            ],
          ],
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
        key: ValueKey(_listingsRefreshKey),
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
               final listingId = data['id'] as String?;
               final title = (data['title'] as String?) ?? '-';
               final price = (data['price'] as String?) ?? '';
               
               return ListTile(
                 contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                 title: Text(title),
                 subtitle: Text(price),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                       icon: const Icon(Icons.edit, color: Color(0xFF8B4513)),
                       tooltip: loc.editListing,
                       onPressed: () {
                         _showEditListingDialog(data);
                       },
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       tooltip: loc.deleteListing,
                       onPressed: listingId != null 
                           ? () => _deleteListing(listingId, title)
                           : null,
                     ),
                   ],
                 ),
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

  Widget _buildMyAlertsCard() {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    return _card(
      title: loc.myAlerts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (_uid != null)
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: _uid)
                  .where('isRead', isEqualTo: false)
                  .limit(5)
                  .get(),
              builder: (context, notifSnapshot) {
                if (notifSnapshot.hasData && notifSnapshot.data!.docs.isNotEmpty) {
                  
                  final docs = notifSnapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.new_releases, color: Colors.orange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            loc.languageCode == 'tr' ? 'Yeni Eşleşmeler' : 'New Matches',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...docs.map((doc) {
                        final notif = doc.data() as Map<String, dynamic>;
                        final listingData = notif['listingData'] as Map<String, dynamic>?;
                        
                        return Card(
                          color: const Color(0xFFFFF9E6),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: const Icon(Icons.fiber_new, color: Colors.orange),
                            title: Text(
                              listingData?['title'] ?? (loc.languageCode == 'tr' ? 'Yeni İlan' : 'New Listing'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${listingData?['city'] ?? ''} - ${listingData?['price'] ?? ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () async {
                                await doc.reference.update({'isRead': true});
                                setState(() {
                                  _notificationCount = _notificationCount > 0 ? _notificationCount - 1 : 0;
                                });
                              },
                            ),
                            onTap: () async {
                              
                              final listingId = notif['listingId'] as String?;
                              if (listingId != null) {
                                try {
                                  
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (c) => const Center(child: CircularProgressIndicator()),
                                  );

                                  final docSnapshot = await FirebaseFirestore.instance
                                      .collection('listings')
                                      .doc(listingId)
                                      .get();
                                  
                                  Navigator.of(context, rootNavigator: true).pop();

                                  if (docSnapshot.exists && docSnapshot.data() != null) {
                                     final listingData = docSnapshot.data()!;
                                     
                                     final fullListing = Map<String, dynamic>.from(listingData);
                                     fullListing['id'] = listingId;
                                     
                                     Navigator.pushNamed(
                                       context, 
                                       '/listing-detail', 
                                       arguments: { 'listing': fullListing }
                                     );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bu ilan artık mevcut değil.')),
                                    );
                                  }
                                } catch (e) {
                                  
                                  if (Navigator.of(context).canPop()) {
                                     Navigator.of(context, rootNavigator: true).pop();
                                  }
                                  debugPrint('Nav error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bir hata oluştu.')),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          
          
          Text(
            loc.languageCode == 'tr' ? 'Aktif Aboneliklerim' : 'My Active Subscriptions',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: (_uid == null) 
                ? Future.value([]) 
                : ApiService.fetchSubscriptions(
                    userId: _uid!,
                    checkActive: true,
                  ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final subscriptions = snapshot.data ?? [];
              
              if (subscriptions.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.noActiveAlerts,
                    style: const TextStyle(color: Color(0xFFCD853F), fontSize: 12),
                  ),
                );
              }
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${subscriptions.length} ${loc.activeAlerts}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subscriptions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      final city = sub['city'] as String? ?? '-';
                      final category = sub['category'] as String? ?? '-';
                      final expiresAtStr = sub['expiresAt'] as String?;
                      
                      String expiryText = '-';
                      if (expiresAtStr != null) {
                        try {
                          final expiryDate = DateTime.parse(expiresAtStr);
                          final daysLeft = expiryDate.difference(DateTime.now()).inDays;
                          expiryText = '$daysLeft ${loc.languageCode == 'tr' ? 'gün' : 'days'}';
                        } catch (e) {
                          debugPrint('Date parse error: $e');
                        }
                      }
                      
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_city,
                            color: Color(0xFF4ECDC4),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '$city - $category',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B4513),
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${loc.expiresAt}: $expiryText',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCD853F),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
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


