import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../candidates/ui/screens/constituency_search_screen.dart';
import '../../news/ui/screens/news_screen.dart';
import '../../polls/ui/screens/polls_screen.dart';
import '../../profile/ui/screens/profile_screen.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final String? initialRoute;

  const MainScaffold({
    super.key,
    this.initialRoute,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _selectedIndex;

  static const _tabs = [
    ConstituencySearchScreen(),
    NewsScreen(),
    PollsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _getInitialIndex(widget.initialRoute);
  }

  int _getInitialIndex(String? route) {
    switch (route) {
      case '/news':
        return 1;
      case '/polls':
        return 2;
      case '/profile':
        return 3;
      case '/parties':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.how_to_vote_outlined),
            selectedIcon: Icon(Icons.how_to_vote),
            label: 'Constituencies',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.poll_outlined),
            selectedIcon: Icon(Icons.poll),
            label: 'Polls',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
