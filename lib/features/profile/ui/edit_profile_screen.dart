import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/parties/data/tn_constituency_data.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  XFile? _picked;
  String? _district;
  String? _constituency;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('Loading...')));

    _nameController.text = _nameController.text.isEmpty ? user.name : _nameController.text;
    _district ??= user.homeDistrict;
    _constituency ??= user.homeConstituency;

    final constituencies = _district == null ? const <String>[] : tnDistrictConstituencies[_district] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
              if (file != null) {
                setState(() => _picked = file);
              }
            },
            icon: const Icon(Icons.upload_rounded),
            label: Text(_picked == null ? 'Upload profile picture' : 'Image selected'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _district,
            items: sortedDistricts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() {
              _district = value;
              _constituency = null;
            }),
            decoration: const InputDecoration(labelText: 'Home district'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _constituency,
            items: constituencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _constituency = value),
            decoration: const InputDecoration(labelText: 'Home constituency'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(profileRepositoryProvider).updateProfile(
                      uid: user.uid,
                      name: _nameController.text.trim(),
                      district: _district,
                      constituency: _constituency,
                      pickedFile: _picked,
                    );
                if (context.mounted) {
                  showSuccessSnackBar(context, 'Profile updated');
                }
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackBar(context, e.toString());
                }
              }
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

