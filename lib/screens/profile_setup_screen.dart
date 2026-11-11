import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  String _gender = 'male';
  String _marital = 'single';
  String _goal = 'zawaj';
  DateTime? _birth;
  File? _photo;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (d != null) setState(() => _birth = d);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _country.text.trim().isEmpty ||
        _birth == null) {
      _toast('أكمل الاسم والدولة وتاريخ الميلاد');
      return;
    }
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;

      String? photoUrl;
      if (_photo != null) {
        final path = '$uid/avatar.jpg';
        await client.storage.from('avatars').upload(path, _photo!,
            fileOptions: const FileOptions(upsert: true));
        photoUrl = client.storage.from('avatars').getPublicUrl(path);
      }

      await client.from('profiles').insert({
        'id': uid,
        'display_name': _name.text.trim(),
        'gender': _gender,
        'birth_date': _birth!.toIso8601String().substring(0, 10),
        'country': _country.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'marital_status': _marital,
        'goal': _goal,
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'photo_url': photoUrl,
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      _toast('تعذّر حفظ الملف: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أكمل ملفك الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: _photo != null ? FileImage(_photo!) : null,
                child: _photo == null
                    ? const Icon(Icons.add_a_photo_outlined, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'الجنس'),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('ذكر')),
              DropdownMenuItem(value: 'female', child: Text('أنثى')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickBirth,
            child: Text(_birth == null
                ? 'تاريخ الميلاد'
                : _birth!.toIso8601String().substring(0, 10)),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _country,
              decoration: const InputDecoration(labelText: 'الدولة')),
          const SizedBox(height: 12),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'المدينة (اختياري)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _marital,
            decoration: const InputDecoration(labelText: 'الحالة الاجتماعية'),
            items: const [
              DropdownMenuItem(value: 'single', child: Text('أعزب / عزباء')),
              DropdownMenuItem(value: 'divorced', child: Text('مطلّق / مطلّقة')),
              DropdownMenuItem(value: 'widowed', child: Text('أرمل / أرملة')),
            ],
            onChanged: (v) => setState(() => _marital = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: const InputDecoration(labelText: 'ما الذي تبحث عنه؟'),
            items: const [
              DropdownMenuItem(value: 'zawaj', child: Text('زواج')),
              DropdownMenuItem(value: 'misyar', child: Text('مسيار')),
              DropdownMenuItem(
                  value: 'getting_to_know', child: Text('تعارف بنيّة الزواج')),
            ],
            onChanged: (v) => setState(() => _goal = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'نبذة عنك'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('حفظ والمتابعة'),
          ),
        ],
      ),
    );
  }
}
