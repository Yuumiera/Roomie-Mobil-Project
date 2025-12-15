import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme_controller.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showLanguageDialog() {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(loc.turkish),
              value: 'tr',
              groupValue: LanguageController.instance.languageCode,
              onChanged: (value) {
                if (value != null) {
                  LanguageController.instance.changeLanguage(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            ),
            RadioListTile<String>(
              title: Text(loc.english),
              value: 'en',
              groupValue: LanguageController.instance.languageCode,
              onChanged: (value) {
                if (value != null) {
                  LanguageController.instance.changeLanguage(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFFDF6E3);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF8B4513);
    final textColor = isDark ? Colors.white : const Color(0xFF8B4513);
    final sectionColor = isDark ? Colors.white70 : const Color(0xFFCD853F);
    
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(loc.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(loc.appearance, sectionColor),
          _buildCard([
            ListTile(
              leading: Icon(Icons.dark_mode, color: iconColor),
              title: Text(loc.darkMode, style: TextStyle(color: textColor)),
              trailing: Switch(
                value: ThemeController.instance.mode == ThemeMode.dark,
                onChanged: (val) {
                  ThemeController.instance.changeTheme(val ? ThemeMode.dark : ThemeMode.light);
                  setState(() {});
                },
                activeColor: const Color(0xFF4CAF50),
              ),
            ),
          ], cardColor),
          const SizedBox(height: 20),
          _buildSectionHeader(loc.account, sectionColor),
          _buildCard([
            ListTile(
              leading: Icon(Icons.person, color: iconColor),
              title: Text(loc.editProfile, style: TextStyle(color: textColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            Divider(height: 1, color: isDark ? Colors.white24 : null),
            ListTile(
              leading: Icon(Icons.lock, color: iconColor),
              title: Text(loc.changePassword, style: TextStyle(color: textColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.comingSoon)));
              },
            ),
          ], cardColor),
          const SizedBox(height: 20),
          _buildSectionHeader(loc.application, sectionColor),
          _buildCard([
            ListTile(
              leading: Icon(Icons.notifications, color: iconColor),
              title: Text(loc.notifications, style: TextStyle(color: textColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: () {},
            ),
            Divider(height: 1, color: isDark ? Colors.white24 : null),
            ListTile(
              leading: Icon(Icons.language, color: iconColor),
              title: Text(loc.language, style: TextStyle(color: textColor)),
              subtitle: Text(LanguageController.instance.languageName, style: TextStyle(color: sectionColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: _showLanguageDialog,
            ),
          ], cardColor),
          const SizedBox(height: 20),
          _buildSectionHeader(loc.support, sectionColor),
          _buildCard([
            ListTile(
              leading: Icon(Icons.help, color: iconColor),
              title: Text(loc.helpCenter, style: TextStyle(color: textColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: () {},
            ),
            Divider(height: 1, color: isDark ? Colors.white24 : null),
            ListTile(
              leading: Icon(Icons.info, color: iconColor),
              title: Text(loc.about, style: TextStyle(color: textColor)),
              trailing: Icon(Icons.chevron_right, color: iconColor),
              onTap: () {},
            ),
          ], cardColor),
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
              label: Text(loc.logout),
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

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
