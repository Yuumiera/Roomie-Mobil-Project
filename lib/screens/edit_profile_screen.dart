import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/cities.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  String? _name;
  String? _bio;
  String? _phone;
  String? _city;
  String? _department;
  String? _classYear;
  String? _gender;
  bool? _hasPet;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = await ApiService.fetchUser(user.uid);
      if (data != null) {
        setState(() {
          _name = data['name'];
          _bio = data['bio'];
          _phone = data['phone'];
          _city = data['city'];
          _department = data['department'];
          _classYear = data['classYear'];
          _gender = data['gender'];
          _hasPet = data['hasPet'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ApiService.updateUser(user.uid, {
          'name': _name,
          'bio': _bio,
          'phone': _phone,
          'city': _city,
          'department': _department,
          'classYear': _classYear,
          'gender': _gender,
          'hasPet': _hasPet,
          // timestamps added by backend
        });
        if (mounted) {
          final loc = AppLocalizations.of(LanguageController.instance.languageCode);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.profileUpdated)));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(LanguageController.instance.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.saveError}: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(LanguageController.instance.languageCode);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        title: Text(loc.editProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _saveProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(loc.name, _name, (v) => _name = v),
                    const SizedBox(height: 16),
                    _buildTextField(loc.bio, _bio, (v) => _bio = v, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(loc.phone, _phone, (v) => _phone = v, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _city != null && trCities81.contains(_city) ? _city : null,
                      items: trCities81.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _city = v),
                      decoration: InputDecoration(
                        labelText: loc.city,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(loc.department, _department, (v) => _department = v),
                    const SizedBox(height: 16),
                    _buildTextField(loc.classYear, _classYear, (v) => _classYear = v),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: () {
                        // Build unique dropdown items
                        final List<DropdownMenuItem<String>> items = [
                          DropdownMenuItem(value: 'Male', child: Text(loc.male)),
                          DropdownMenuItem(value: 'Female', child: Text(loc.female)),
                          DropdownMenuItem(value: 'Other', child: Text(loc.other)),
                        ];
                        
                        // If current value is Turkish, add it if not already English equivalent
                        if (_gender != null && !['Male', 'Female', 'Other'].contains(_gender)) {
                          String label = _gender!;
                          if (_gender == 'Erkek') label = loc.male;
                          else if (_gender == 'Kadın') label = loc.female;
                          else if (_gender == 'Diğer') label = loc.other;
                          
                          items.add(DropdownMenuItem(value: _gender, child: Text(label)));
                        }
                        
                        return items;
                      }(),
                      onChanged: (v) => setState(() => _gender = v),
                      decoration: InputDecoration(
                        labelText: loc.gender,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(loc.hasPet),
                      value: _hasPet ?? false,
                      onChanged: (v) => setState(() => _hasPet = v),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(loc.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String? initialValue, Function(String?) onSaved, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onSaved: onSaved,
    );
  }
}
