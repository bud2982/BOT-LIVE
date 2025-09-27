import 'dart:math' show min;
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
  bool _useSampleData = false;
  bool _isMonitoring = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('HomeScreen._init() chiamato');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('api_key');
      _intervalMin = prefs.getInt('interval_min') ?? 1;
      _useSampleData = prefs.getBool('use_sample_data') ?? false;
      
      print('Preferenze caricate: API Key=${_apiKey != null ? "${_apiKey!.substring(0, min(5, _apiKey!.length))}..." : "null"}, Intervallo=$_intervalMin min, UseSampleData=$_useSampleData');
      
      // Se la chiave API non è impostata, usa quella predefinita
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = '239a1e02def2d210a0829a958348c5f5'; // Nuova chiave API autorizzata
        await prefs.setString('api_key', _apiKey!);
        print('Impostata API Key predefinita: ${_apiKey!.substring(0, 5)}...');
      }
      
      await _loadFixtures();
    } catch (e) {
      print('Errore critico durante l\'inizializzazione: $e');
      print('Stack trace: ${e.toString()}');
      
      setState(() {
        _errorMessage = 'Errore di inizializzazione: $e';
        _isLoading = false;
      });
      
      // In caso di errore critico, usa comunque i dati di esempio
      if (_apiKey == null) {
        _apiKey = '239a1e02def2d210a0829a958348c5f5'; // Chiave predefinita
        print('Impostata API Key predefinita dopo errore critico');
      }
      
      _useSampleData = true;
      await _loadFixtures();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore critico: $e - Verranno usati dati di esempio'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
    print('HomeScreen._init() completato');
  }
  
  Future<void> _loadFixtures() async {
    try {
      if (_useSampleData) {
        print('Utilizzo dati di esempio come richiesto nelle impostazioni');
        final apiService = ApiFootballService(_apiKey!, useSampleData: true);
        _future = apiService.getFixturesToday();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilizzo dati di esempio come richiesto nelle impostazioni'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Tenta di usare dati reali dall'API, ma con fallback ai dati di esempio
        print('Tentativo di utilizzare l\'API reale...');
        final apiService = ApiFootballService(_apiKey!, useSampleData: false);
        
        // Test di connessione
        final isConnected = await apiService.testConnection();
        if (!isConnected) {
          print('Test di connessione fallito, passaggio ai dati di esempio');
          final fallbackService = ApiFootballService(_apiKey!, useSampleData: true);
          _future = fallbackService.getFixturesToday();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connessione API non disponibile - Utilizzo dati di esempio'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('Test di connessione riuscito, utilizzo API reale');
          _future = apiService.getFixturesToday();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connessione API riuscita - Utilizzo dati reali'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Errore durante il caricamento delle partite: $e');
      print('Stack trace: ${e.toString()}');
      
      // Usa dati di esempio in caso di errore
      print('Passaggio ai dati di esempio dopo errore...');
      final apiService = ApiFootballService(_apiKey!, useSampleData: true);
      _future = apiService.getFixturesToday();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore di caricamento: $e - Verranno usati dati di esempio'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
    print('_startMonitoring chiamato');
    
    if (_isMonitoring) {
      _stopMonitoring();
      return;
    }
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('API key non impostata');
      _showError('API key non impostata. Vai nelle impostazioni per configurarla.');
      return;
    }
    
    if (_selected.isEmpty) {
      print('Nessuna partita selezionata');
      _showError('Seleziona almeno una partita da monitorare');
      return;
    }
    
    print('Partite selezionate: $_selected');
    setState(() => _isLoading = true);
    
    try {
      // Usa dati di esempio se richiesto nelle impostazioni o se ci sono stati errori
      final useSample = _useSampleData || _errorMessage != null;
      final api = ApiFootballService(_apiKey!, useSampleData: useSample);
      final notif = LocalNotifService();
      
      print('Inizializzazione servizio notifiche...');
      await notif.init();
      print('Servizio notifiche inizializzato');
      
      _controller?.stop();
      _controller = MonitorController(
        api: api, 
        notif: notif, 
        selected: _selected,
        intervalMinutes: _intervalMin,
      );
      
      print('Avvio monitoraggio...');
      await _controller!.start();
      print('Monitoraggio avviato');
      
      setState(() => _isMonitoring = true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monitoraggio avviato (intervallo: $_intervalMin min)'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Mostra un messaggio informativo sull'utilizzo dei dati
      if (useSample) {
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monitoraggio attivo con dati di esempio'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Errore durante l\'avvio del monitoraggio: $e');
      _showError('Errore: $e');
      
      // In caso di errore, prova con i dati di esempio
      try {
        final api = ApiFootballService(_apiKey!, useSampleData: true);
        final notif = LocalNotifService();
        
        await notif.init();
        
        _controller?.stop();
        _controller = MonitorController(
          api: api, 
          notif: notif, 
          selected: _selected,
          intervalMinutes: _intervalMin,
        );
        
        await _controller!.start();
        setState(() => _isMonitoring = true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monitoraggio avviato con dati di esempio (intervallo: $_intervalMin min)'),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e2) {
        print('Errore anche con dati di esempio: $e2');
        _showError('Errore critico: $e2');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _stopMonitoring() {
    if (_controller != null) {
      _controller!.stop();
      setState(() => _isMonitoring = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monitoraggio fermato'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  Future<void> _refreshData() async {
    print('Aggiornamento dati...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _loadFixtures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dati aggiornati'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Errore durante l\'aggiornamento: $e');
      setState(() {
        _errorMessage = 'Errore di aggiornamento: $e';
      });
      _showError('Errore durante l\'aggiornamento: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partite del giorno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Aggiorna dati',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // Ricarica le preferenze quando si torna dalle impostazioni
              _init();
            },
            tooltip: 'Impostazioni',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && (_apiKey == null || _future == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Errore',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<Fixture>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Errore di caricamento',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                '${snap.error}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text('Riprova'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final fixtures = snap.data ?? [];
                    
                    if (fixtures.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_soccer, color: Colors.grey, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Nessuna partita trovata',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Non ci sono partite disponibili per oggi',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text('Aggiorna'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _toggleAll(fixtures),
                                child: Text(_selected.length == fixtures.length
                                    ? 'Deseleziona tutte'
                                    : 'Seleziona tutte'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Selezionate: ${_selected.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (_isMonitoring)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Monitoraggio attivo',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
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
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: CheckboxListTile(
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
                                  title: Text(
                                    f.home + ' - ' + f.away,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Inizio: ' + f.start.toString().substring(0, 16)),
                                      Text('ID: ' + f.id.toString(), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  secondary: const Icon(Icons.sports_soccer),
                                ),
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
        backgroundColor: _isMonitoring ? Colors.red : Colors.green,
        child: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
        tooltip: _isMonitoring ? 'Ferma monitoraggio' : 'Avvia monitoraggio',
      ),
    );
  }
}
