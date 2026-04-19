import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDocProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Loading profile...')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: user.photoUrl == null ? null : CachedNetworkImageProvider(user.photoUrl!),
                child: user.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => context.push('/app/profile/edit'), child: const Text('Edit profile')),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Home constituency'),
            subtitle: Text('${user.homeDistrict ?? '-'} · ${user.homeConstituency ?? '-'}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/app/profile/edit'),
          ),
          if (user.isAdmin)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Admin dashboard'),
              trailing: const Icon(Icons.admin_panel_settings_outlined),
              onTap: () => context.push('/admin'),
            ),
          const Divider(),
          Text('My messages', style: Theme.of(context).textTheme.titleMedium),
          StreamBuilder(
            stream: ref.read(profileRepositoryProvider).watchMyMessages(user.uid),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('No messages yet.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final roomId = ((doc.reference.parent.parent?.id) ?? '').toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data['text']?.toString() ?? ''),
                    subtitle: Text('${data['district'] ?? ''} · ${data['constituency'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        await ref.read(profileRepositoryProvider).softDeleteMyMessage(roomId: roomId, messageId: doc.id);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _confirmSignOut(context, ref),
            child: const Text('Sign out'),
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return Text(
                'Version ${snapshot.data?.version ?? '-'}',
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}


