import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Görünüm'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Color(0xFF8B4513)),
              title: const Text('Karanlık Mod'),
              trailing: Switch(
                value: ThemeController.instance.mode == ThemeMode.dark,
                onChanged: (val) {
                  ThemeController.instance.changeTheme(val ? ThemeMode.dark : ThemeMode.light);
                  setState(() {});
                },
                activeColor: const Color(0xFF4CAF50),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Hesap'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF8B4513)),
              title: const Text('Profili Düzenle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF8B4513)),
              title: const Text('Şifre Değiştir'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Implement password change
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yakında eklenecek')));
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Uygulama'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.notifications, color: Color(0xFF8B4513)),
              title: const Text('Bildirimler'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF8B4513)),
              title: const Text('Dil'),
              subtitle: const Text('Türkçe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Destek'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.help, color: Color(0xFF8B4513)),
              title: const Text('Yardım Merkezi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF8B4513)),
              title: const Text('Hakkında'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFCD853F),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
