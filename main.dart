
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Android emulator -> host machine. For a real phone, replace with your PC's LAN IP.
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<String?> token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  static Future<List<Tournament>> tournaments() async {
    final r = await http.get(Uri.parse('$baseUrl/tournaments'));
    if (r.statusCode != 200) throw Exception('Could not load tournaments');
    final list = jsonDecode(r.body) as List;
    return list.map((x) => Tournament.fromJson(x)).toList();
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode >= 300) throw Exception(data['error'] ?? 'Registration failed');
    final p = await SharedPreferences.getInstance();
    await p.setString('token', data['token']);
    return data['user'];
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode >= 300) throw Exception(data['error'] ?? 'Login failed');
    final p = await SharedPreferences.getInstance();
    await p.setString('token', data['token']);
    return data['user'];
  }

  static Future<Map<String, dynamic>> join(int id) async {
    final t = await token();
    if (t == null) throw Exception('Please login first');
    final r = await http.post(
      Uri.parse('$baseUrl/tournaments/$id/join'),
      headers: {'Authorization': 'Bearer $t'},
    );
    final data = jsonDecode(r.body);
    if (r.statusCode >= 300) throw Exception(data['error'] ?? 'Join failed');
    return data;
  }
}

void main() => runApp(const EarnBattleApp());

class EarnBattleApp extends StatelessWidget {
  const EarnBattleApp({super.key});

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      final data = await ApiService.tournaments();
      if (!mounted) return;
      setState(() {
        tournaments = data;
        loading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Earn Battle',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020A10),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7CFF18),
          brightness: Brightness.dark,
        ),
      ),
      home: const TournamentHome(),
    );
  }
}

class TournamentHome extends StatefulWidget {
  const TournamentHome({super.key});

  @override
  State<TournamentHome> createState() => _TournamentHomeState();
}

class _TournamentHomeState extends State<TournamentHome> {
  int tab = 0;
  String filter = 'All';

  List<Tournament> tournaments = [];
  bool loading = true;
  String? loadError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF02070D),
        elevation: 0,
        title: const Text(
          'EARN BATTLE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
            color: Color(0xFF7CFF18),
          ),
        ),
        leading: const Icon(Icons.menu),
        actions: [
          const Icon(Icons.notifications_none, size: 28),
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1976B8)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Color(0xFF7CFF18), size: 19),
                SizedBox(width: 5),
                Text('₹245',
                    style: TextStyle(
                        color: Color(0xFF7CFF18),
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _body(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF02070D),
        indicatorColor: const Color(0xFF173B12),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Tournaments'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'My Teams'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _body() {
    if (tab != 0) {
      return Center(
        child: Text(
          ['Home', 'Tournaments', 'Wallet', 'My Teams', 'Profile'][tab],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Backend connection failed'),
            const SizedBox(height: 8),
            Text(loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadTournaments, child: const Text('RETRY')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _banner(),
        const SizedBox(height: 14),
        _tabs(),
        const SizedBox(height: 12),
        _filters(),
        const SizedBox(height: 14),
        ...tournaments.map(_tournamentCard),
      ],
    );
  }

  Widget _banner() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF061B3A), Color(0xFF064C9A), Color(0xFF06152C)],
        ),
        border: Border.all(color: const Color(0xFF0878D1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(9),
              color: Colors.red.shade700,
              child: const Text(
                'READ RULES BEFORE JOINING\nMINIMUM LEVEL 40+  ✕\nDOUBLE VECTOR AND M79 BAN ✕\nHACK NOT ALLOWED ✕',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            bottom: 18,
            child: Text(
              'SOLO FULL MAP\nTOURNAMENT',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Positioned(
            left: 22,
            top: 15,
            child: Text(
              'FREE FIRE MAX',
              style: TextStyle(
                color: Color(0xFF48E8FF),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        _bigTab('Upcoming', true),
        _bigTab('Live', false),
        _bigTab('Completed', false),
      ],
    );
  }

  Widget _bigTab(String text, bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7CFF18) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? const Color(0xFF7CFF18) : const Color(0xFF175A83),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return Row(
      children: ['All', 'Solo', 'Duo', 'Squad'].map((x) {
        final active = filter == x;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => filter = x),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF7CFF18) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF175A83)),
              ),
              child: Text(
                x,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tournamentCard(Tournament t) {
    if (filter != 'All' && filter != t.type) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF06131C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0878D1), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x3300A8FF), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF160F13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Center(
                  child: Text(
                    'GRIND\nZONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${t.title}  ${t.match}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Upcoming',
                          style: TextStyle(
                            color: Color(0xFF7CFF18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.time, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('🏆', 'PRIZE POOL', '₹${t.prize}'),
              _stat('☠', 'PER KILL', '₹${t.kill}'),
              _stat('🎟', 'ENTRY FEE', '₹${t.entry}'),
            ],
          ),
          const Divider(color: Color(0xFF164A67)),
          Row(
            children: [
              _mini('TYPE', t.type),
              _mini('VERSION', t.version),
              _mini('MAP', t.map),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: t.players / t.maxPlayers,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF173548),
                    color: const Color(0xFF7CFF18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${t.players}/${t.maxPlayers}'),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7CFF18),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                ),
                onPressed: () => _join(t),
                child: const Text(
                  'JOIN  →',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 3),
          Text('$icon  $value',
              style: const TextStyle(
                color: Color(0xFF7CFF18),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _join(Tournament t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF06131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Entry Fee: ₹${t.entry}   •   Prize Pool: ₹${t.prize}'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7CFF18),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () async {
                  try {
                    final result = await ApiService.join(t.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Joined successfully')),
                    );
                    _loadTournaments();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: const Text('CONFIRM JOIN',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Tournament {
  final int id;
  final String title, match, time, type, version, map;
  final int prize, kill, entry, players, maxPlayers;

  const Tournament({
    required this.id,
    required this.title,
    required this.match,
    required this.time,
    required this.prize,
    required this.kill,
    required this.entry,
    required this.type,
    required this.version,
    required this.map,
    required this.players,
    required this.maxPlayers,
  });

  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
    id: j['id'] as int,
    title: j['title'] as String,
    match: j['match_no'] as String,
    time: j['start_time'] as String,
    prize: j['prize_pool'] as int,
    kill: j['per_kill'] as int,
    entry: j['entry_fee'] as int,
    type: j['type'] as String,
    version: j['version'] as String,
    map: j['map'] as String,
    players: j['joined_players'] as int,
    maxPlayers: j['max_players'] as int,
  );
}
