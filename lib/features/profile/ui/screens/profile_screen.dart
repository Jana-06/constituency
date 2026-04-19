import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../../shared/widgets/shimmer_box.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _primaryText = Color(0xFF111111);
  static const _secondaryText = Color(0xFF222222);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userDataAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile', style: TextStyle(color: _primaryText))),
      body: authState.when(
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(
              child: Text('Not signed in', style: TextStyle(color: _primaryText)),
            );
          }

          return userDataAsync.when(
            data: (userData) {
              final name = (userData?['name'] as String?)?.trim();
              final email = (userData?['email'] as String?)?.trim();
              final photoUrl = (userData?['photoUrl'] as String?)?.trim();
              final role = ((userData?['role'] as String?) ?? 'user').toUpperCase();
              final district = (userData?['homeDistrict'] as String?)?.trim();
              final constituency = (userData?['homeConstituency'] as String?)?.trim();

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(currentUserProvider);
                  await Future<void>.delayed(const Duration(milliseconds: 250));
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(
                      name: (name != null && name.isNotEmpty) ? name : (firebaseUser.displayName ?? 'Citizen'),
                      email: (email != null && email.isNotEmpty) ? email : (firebaseUser.email ?? ''),
                      role: role,
                      photoUrl: photoUrl,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.home_work_outlined, color: _primaryText),
                        title: const Text('Home Constituency', style: TextStyle(color: _primaryText)),
                        subtitle: Text(
                          '${district?.isNotEmpty == true ? district : '-'} · ${constituency?.isNotEmpty == true ? constituency : '-'}',
                          style: const TextStyle(color: _secondaryText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.badge_outlined, color: _primaryText),
                        title: const Text('User ID', style: TextStyle(color: _primaryText)),
                        subtitle: Text(firebaseUser.uid, style: const TextStyle(color: _secondaryText)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('My Recent Messages', style: TextStyle(color: _primaryText, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    StreamBuilder(
                      stream: ref.read(profileRepositoryProvider).watchMyMessages(firebaseUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const _MessageLoading();
                        }
                        if (snapshot.hasError) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Text('Unable to load your messages right now.', style: TextStyle(color: _secondaryText)),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? const [];
                        if (docs.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Text('No messages yet.', style: TextStyle(color: _secondaryText)),
                            ),
                          );
                        }

                        return Card(
                          child: Column(
                            children: docs.map((doc) {
                              final data = doc.data();
                              final roomId = (doc.reference.parent.parent?.id ?? '').toString();
                              final text = data['text']?.toString() ?? '';
                              final districtValue = data['district']?.toString() ?? '-';
                              final constituencyValue = data['constituency']?.toString() ?? '-';

                              return ListTile(
                                title: Text(
                                  text.isEmpty ? '(No text)' : text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: _primaryText),
                                ),
                                subtitle: Text(
                                  '$districtValue · $constituencyValue',
                                  style: const TextStyle(color: _secondaryText),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: roomId.isEmpty
                                      ? null
                                      : () async {
                                          await ref.read(profileRepositoryProvider).softDeleteMyMessage(
                                                roomId: roomId,
                                                messageId: doc.id,
                                              );
                                        },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out', style: TextStyle(color: _primaryText)),
                            content: const Text('Are you sure you want to sign out?', style: TextStyle(color: _secondaryText)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: _primaryText)),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await ref.read(authServiceProvider).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '-';
                        return Text(
                          'App version $version',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _secondaryText),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const _ProfileLoading(),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load profile: $error', style: const TextStyle(color: _primaryText)),
              ),
            ),
          );
        },
        loading: () => const _ProfileLoading(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Auth error: $error', style: const TextStyle(color: _primaryText)),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String role;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null,
              child: hasPhoto ? null : const Icon(Icons.person, size: 30, color: Color(0xFF111111)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF111111))),
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(color: Color(0xFF222222))),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text('Role: $role', style: const TextStyle(color: Color(0xFF111111))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerBox(height: 96),
        SizedBox(height: 12),
        ShimmerBox(height: 72),
        SizedBox(height: 8),
        ShimmerBox(height: 72),
        SizedBox(height: 12),
        ShimmerBox(height: 140),
      ],
    );
  }
}

class _MessageLoading extends StatelessWidget {
  const _MessageLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ShimmerBox(height: 56),
          SizedBox(height: 8),
          ShimmerBox(height: 56),
        ],
      ),
    );
  }
}
