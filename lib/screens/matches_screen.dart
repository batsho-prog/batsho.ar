import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = _db.auth.currentUser!.id;
    final rows = await _db
        .from('matches')
        .select()
        .or('user_a.eq.$uid,user_b.eq.$uid');
    final ids = rows
        .map((r) => r['user_a'] == uid ? r['user_b'] : r['user_a'])
        .cast<String>()
        .toList();
    if (ids.isEmpty) return [];
    final profiles =
        await _db.from('profiles').select().inFilter('id', ids);
    return profiles.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
              child: Text('لا توجد مطابقات بعد، ابدأ بالإعجاب بالملفات'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = list[i];
              final photo = p['photo_url'] as String?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? const Icon(Icons.person) : null,
                ),
                title: Text(p['display_name']),
                subtitle: Text(p['country']),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherId: p['id'],
                    otherName: p['display_name'],
                  ),
                )),
              );
            },
          ),
        );
      },
    );
  }
}
