import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/connectivity_provider.dart';
import '../../core/theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        elevation: 8,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), selectedIcon: Icon(Icons.how_to_vote), label: 'Parties'),
          NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper), label: 'News'),
          NavigationDestination(icon: Icon(Icons.poll_outlined), selectedIcon: Icon(Icons.poll), label: 'Polls'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider).value ?? false;
    if (!offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppTheme.saffron,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Text('You are offline. Changes will sync when connection is restored.'),
    );
  }
}
