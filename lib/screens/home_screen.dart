import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'discover_screen.dart';
import 'matches_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [DiscoverScreen(), MatchesScreen()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('باتشو'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.explore_outlined), label: 'استكشف'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'المحادثات'),
        ],
      ),
    );
  }
}
