import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';
import '../services/api_football_service.dart';
import '../services/local_notif_service.dart';
import '../controllers/monitor_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Fixture>> _future;
  final Set<int> _selected = {};
  MonitorController? _controller;
  String? _apiKey;
  int _intervalMin = 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key');
    _intervalMin = prefs.getInt('interval_min') ?? 1;
    if (_apiKey == null || _apiKey!.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/settings');
      return;
    }
    _future = ApiFootballService(_apiKey!).getFixturesToday();
    if (mounted) setState(() {});
  }

  void _toggleAll(List<Fixture> fixtures) {
    setState(() {
      if (_selected.length == fixtures.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(fixtures.map((e) => e.id));
      }
    });
  }

  Future<void> _startMonitoring() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    final api = ApiFootballService(_apiKey!);
    final notif = LocalNotifService();
    await notif.init();
    _controller?.stop();
    _controller = MonitorController(api: api, notif: notif, selected: _selected);
    _controller!.start();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monitoraggio avviato')),
    );
  }

  @override
  void dispose() {
    _controller?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partite del giorno'), actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        )
      ]),
      body: _apiKey == null
          ? const SizedBox.shrink()
          : FutureBuilder<List<Fixture>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Errore: \\'));
                }
                final fixtures = snap.data ?? [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _toggleAll(fixtures),
                            child: Text(_selected.length == fixtures.length
                                ? 'Deseleziona tutte'
                                : 'Seleziona tutte'),
                          ),
                          const SizedBox(width: 12),
                          Text('Selezionate: \\')
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: fixtures.length,
                        itemBuilder: (context, i) {
                          final f = fixtures[i];
                          final selected = _selected.contains(f.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(f.id);
                                } else {
                                  _selected.remove(f.id);
                                }
                              });
                            },
                            title: Text('\\ - \\'),
                            subtitle: Text(
                                'Start: \\  | ID: \\'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startMonitoring,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
