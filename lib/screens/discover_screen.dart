import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

int ageOf(String birthDate) {
  final b = DateTime.parse(birthDate);
  final n = DateTime.now();
  var a = n.year - b.year;
  if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
  return a;
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;

  RangeValues _ages = const RangeValues(18, 60);
  String? _goal;
  final _countryFilter = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser!.id;
      final me = await _db
          .from('profiles')
          .select('gender')
          .eq('id', uid)
          .single();
      final target = me['gender'] == 'male' ? 'female' : 'male';

      final liked = await _db.from('likes').select('to_user').eq('from_user', uid);
      final skip = <String>{
        uid,
        ...liked.map((r) => r['to_user'] as String),
      };

      final now = DateTime.now();
      final youngest = DateTime(now.year - _ages.start.round(), now.month, now.day);
      final oldest = DateTime(now.year - _ages.end.round() - 1, now.month, now.day);

      var q = _db
          .from('profiles')
          .select()
          .eq('gender', target)
          .lte('birth_date', youngest.toIso8601String().substring(0, 10))
          .gte('birth_date', oldest.toIso8601String().substring(0, 10));
      if (_goal != null) q = q.eq('goal', _goal!);
      final c = _countryFilter.text.trim();
      if (c.isNotEmpty) q = q.ilike('country', '%$c%');

      final rows = await q.order('created_at', ascending: false).limit(50);
      setState(() {
        _profiles =
            rows.where((r) => !skip.contains(r['id'])).toList().cast();
      });
    } catch (e) {
      _toast('تعذّر تحميل الملفات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like(String id) async {
    try {
      await _db.from('likes').insert({
        'from_user': _db.auth.currentUser!.id,
        'to_user': id,
      });
      // هل أصبحت مطابقة؟
      final back = await _db
          .from('likes')
          .select()
          .eq('from_user', id)
          .eq('to_user', _db.auth.currentUser!.id)
          .maybeSingle();
      if (back != null) _toast('مطابقة جديدة! يمكنك الآن بدء المحادثة 🎉');
      setState(() => _profiles.removeWhere((p) => p['id'] == id));
    } catch (e) {
      _toast('تعذّر تسجيل الإعجاب');
    }
  }

  Future<void> _block(String id) async {
    await _db.from('blocks').insert({
      'blocker': _db.auth.currentUser!.id,
      'blocked': id,
    });
    setState(() => _profiles.removeWhere((p) => p['id'] == id));
  }

  Future<void> _report(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('الإبلاغ عن مستخدم'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'سبب البلاغ'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: const Text('إرسال')),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return;
    await _db.from('reports').insert({
      'reporter': _db.auth.currentUser!.id,
      'reported': id,
      'reason': reason,
    });
    _toast('تم إرسال البلاغ، شكرًا لك');
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('العمر: ${_ages.start.round()} - ${_ages.end.round()}'),
              RangeSlider(
                values: _ages,
                min: 18,
                max: 80,
                divisions: 62,
                onChanged: (v) => setSheet(() => _ages = v),
              ),
              TextField(
                controller: _countryFilter,
                decoration: const InputDecoration(labelText: 'الدولة'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _goal,
                decoration: const InputDecoration(labelText: 'الهدف'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('الكل')),
                  DropdownMenuItem(value: 'zawaj', child: Text('زواج')),
                  DropdownMenuItem(value: 'misyar', child: Text('مسيار')),
                  DropdownMenuItem(
                      value: 'getting_to_know', child: Text('تعارف')),
                ],
                onChanged: (v) => setSheet(() => _goal = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
                child: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune),
            label: const Text('تصفية'),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _profiles.isEmpty
                  ? const Center(child: Text('لا توجد ملفات مطابقة حاليًا'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _profiles.length,
                        itemBuilder: (_, i) => _ProfileCard(
                          profile: _profiles[i],
                          onLike: () => _like(_profiles[i]['id']),
                          onBlock: () => _block(_profiles[i]['id']),
                          onReport: () => _report(_profiles[i]['id']),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLike, onBlock, onReport;

  const _ProfileCard({
    required this.profile,
    required this.onLike,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final photo = profile['photo_url'] as String?;
    final bio = profile['bio'] as String?;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null)
            Image.network(photo,
                height: 260, width: double.infinity, fit: BoxFit.cover)
          else
            Container(
              height: 160,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.person, size: 64)),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${profile['display_name']}، ${ageOf(profile['birth_date'])}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (profile['is_verified'] == true) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (v) => v == 'block' ? onBlock() : onReport(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'block', child: Text('حظر')),
                        PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                      ],
                    ),
                  ],
                ),
                Text('${profile['country']}'
                    '${profile['city'] != null ? '، ${profile['city']}' : ''}'),
                if (bio != null) ...[
                  const SizedBox(height: 8),
                  Text(bio),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('إعجاب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
