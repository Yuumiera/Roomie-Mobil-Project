class AppLocalizations {
  final String languageCode;
  
  AppLocalizations(this.languageCode);
  
  static AppLocalizations of(String langCode) {
    return AppLocalizations(langCode);
  }
  
  // Settings Screen
  String get settings => languageCode == 'tr' ? 'Ayarlar' : 'Settings';
  String get appearance => languageCode == 'tr' ? 'Görünüm' : 'Appearance';
  String get darkMode => languageCode == 'tr' ? 'Karanlık Mod' : 'Dark Mode';
  String get account => languageCode == 'tr' ? 'Hesap' : 'Account';
  String get editProfile => languageCode == 'tr' ? 'Profili Düzenle' : 'Edit Profile';
  String get changePassword => languageCode == 'tr' ? 'Şifre Değiştir' : 'Change Password';
  String get application => languageCode == 'tr' ? 'Uygulama' : 'Application';
  String get notifications => languageCode == 'tr' ? 'Bildirimler' : 'Notifications';
  String get language => languageCode == 'tr' ? 'Dil' : 'Language';
  String get support => languageCode == 'tr' ? 'Destek' : 'Support';
  String get helpCenter => languageCode == 'tr' ? 'Yardım Merkezi' : 'Help Center';
  String get about => languageCode == 'tr' ? 'Hakkında' : 'About';
  String get logout => languageCode == 'tr' ? 'Çıkış Yap' : 'Logout';
  String get comingSoon => languageCode == 'tr' ? 'Yakında eklenecek' : 'Coming soon';
  
  // Profile Screen
  String get profile => languageCode == 'tr' ? 'Profil' : 'Profile';
  String get name => languageCode == 'tr' ? 'Ad Soyad' : 'Name';
  String get bio => languageCode == 'tr' ? 'Hakkımda' : 'About';
  String get phone => languageCode == 'tr' ? 'Telefon' : 'Phone';
  String get city => languageCode == 'tr' ? 'Şehir' : 'City';
  String get department => languageCode == 'tr' ? 'Bölüm' : 'Department';
  String get classYear => languageCode == 'tr' ? 'Sınıf' : 'Class';
  String get gender => languageCode == 'tr' ? 'Cinsiyet' : 'Gender';
  String get hasPet => languageCode == 'tr' ? 'Evcil Hayvanım Var' : 'Has Pet';
  String get save => languageCode == 'tr' ? 'Kaydet' : 'Save';
  String get profileUpdated => languageCode == 'tr' ? 'Profil güncellendi' : 'Profile updated';
  String get saveError => languageCode == 'tr' ? 'Kaydetme hatası' : 'Save error';
  String get male => languageCode == 'tr' ? 'Erkek' : 'Male';
  String get female => languageCode == 'tr' ? 'Kadın' : 'Female';
  String get other => languageCode == 'tr' ? 'Diğer' : 'Other';
  String get myListings => languageCode == 'tr' ? 'İlanlarım' : 'My Listings';
  String get favorites => languageCode == 'tr' ? 'Favorilerim' : 'Favorites';
  String get reviews => languageCode == 'tr' ? 'Yorumlar' : 'Reviews';
  String get posts => languageCode == 'tr' ? 'Gönderiler' : 'Posts';
  
  // My Alerts (Premium Feature)
  String get myAlerts => languageCode == 'tr' ? 'Beklediğim İlanlar' : 'My Alerts';
  String get activeAlerts => languageCode == 'tr' ? 'Aktif Bildirim' : 'Active Alerts';
  String get noActiveAlerts => languageCode == 'tr' ? 'Aktif bildirim yok' : 'No active alerts';
  String get expiresAt => languageCode == 'tr' ? 'Son Kullanma' : 'Expires At';
  
  // Listing CRUD
  String get editListing => languageCode == 'tr' ? 'İlanı Düzenle' : 'Edit Listing';
  String get deleteListing => languageCode == 'tr' ? 'İlanı Sil' : 'Delete Listing';
  String get deleteConfirmTitle => languageCode == 'tr' ? 'Emin misiniz?' : 'Are you sure?';
  String get deleteConfirmMessage => languageCode == 'tr' ? 'Bu ilanı silmek istediğinize emin misiniz?' : 'Are you sure you want to delete this listing?';
  String get cancel => languageCode == 'tr' ? 'İptal' : 'Cancel';
  String get delete => languageCode == 'tr' ? 'Sil' : 'Delete';
  String get listingDeleted => languageCode == 'tr' ? 'İlan silindi' : 'Listing deleted';
  String get listingUpdated => languageCode == 'tr' ? 'İlan güncellendi' : 'Listing updated';
  String get update => languageCode == 'tr' ? 'Güncelle' : 'Update';
  
  // Language Selection
  String get selectLanguage => languageCode == 'tr' ? 'Dil Seçin' : 'Select Language';
  String get turkish => languageCode == 'tr' ? 'Türkçe' : 'Turkish';
  String get english => languageCode == 'tr' ? 'İngilizce' : 'English';
}
