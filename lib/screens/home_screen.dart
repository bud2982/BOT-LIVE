import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';
import '../services/hybrid_football_service.dart';
import '../services/local_notif_service.dart';
import '../services/followed_matches_service.dart';
import '../controllers/monitor_controller.dart';
import '../widgets/api_key_required_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Fixture>> _future;
  final Set<int> _selected = {};
  MonitorController? _controller;
  int _intervalMin = 1;
  bool _isMonitoring = false;
  bool _isLoading = true;

  // Funzione di utilità per convertire orari UTC a UTC+1 (ora italiana)
  String _formatItalianTime(DateTime utcDateTime) {
    // Aggiungi 1 ora per convertire da UTC a UTC+1 (ora italiana)
    final italianTime = utcDateTime.add(const Duration(hours: 1));
    return italianTime.toString().substring(0, 16); // "yyyy-MM-dd HH:mm"
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('HomeScreen._init() chiamato');
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _intervalMin = prefs.getInt('interval_min') ?? 1;
      
      print('Preferenze caricate: Intervallo=$_intervalMin min');
      
      await _loadFixtures();
    } catch (e) {
      print('Errore critico durante l\'inizializzazione: $e');
      print('Stack trace: ${e.toString()}');
      
      setState(() {
        _isLoading = false;
      });
      
      // In caso di errore critico, prova comunque a caricare i dati
      await _loadFixtures();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore critico: $e - Tentativo di recupero dati'),
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
      print('Caricamento partite SOLO da LiveScore API...');
      final hybridService = HybridFootballService();
      
      // Test di connessione
      final isConnected = await hybridService.testConnection();
      if (!isConnected) {
        print('Test di connessione LiveScore API fallito');
        throw Exception('Impossibile connettersi a LiveScore API. Verifica la configurazione della chiave API.');
      } else {
        print('Test di connessione LiveScore API riuscito');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connesso a LiveScore API - Recupero dati reali'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      _future = hybridService.getFixturesToday();
    } catch (e) {
      print('Errore LiveScore API: $e');
      
      // Se l'errore è relativo alla chiave API, mostra il widget di configurazione
      if (e.toString().contains('mancante') || e.toString().contains('non valida') || e.toString().contains('scaduta')) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ApiKeyRequiredWidget(error: e.toString()),
            ),
          );
        }
        return;
      }
      
      // Per altri errori, mostra messaggio di errore ma fornisce un fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Errore LiveScore API: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Fallback: fornisci una lista vuota invece di crashare
      print('Utilizzo fallback - lista vuota');
      _future = Future.value([]);
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

  Future<void> _addSelectedToFollowed() async {
    if (_selected.isEmpty) {
      _showError('Seleziona almeno una partita da seguire');
      return;
    }

    final followedService = FollowedMatchesService();
    final hybridService = HybridFootballService();
    int addedCount = 0;

    try {
      // Ottieni tutte le partite per trovare quelle selezionate
      final allMatches = await hybridService.getFixturesToday();
      
      for (final fixtureId in _selected) {
        final match = allMatches.firstWhere((m) => m.id == fixtureId);
        final isAlreadyFollowed = await followedService.isMatchFollowed(fixtureId);
        
        if (!isAlreadyFollowed) {
          await followedService.followMatch(match);
          addedCount++;
        }
      }

      if (mounted) {
        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $addedCount ${addedCount == 1 ? "partita seguita" : "partite seguite"}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Vedi',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/followed_matches');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ Tutte le partite selezionate sono già seguite'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Errore nell\'aggiungere le partite: $e');
      }
    }
  }

  Future<void> _startMonitoring() async {
    print('_startMonitoring chiamato');
    
    if (_isMonitoring) {
      _stopMonitoring();
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
      final hybridService = HybridFootballService();
      final notif = LocalNotifService();
      
      print('Inizializzazione servizio notifiche...');
      await notif.init();
      print('Servizio notifiche inizializzato');
      
      _controller?.stop();
      _controller = MonitorController(
        api: hybridService, 
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
    } catch (e) {
      print('Errore durante l\'avvio del monitoraggio: $e');
      _showError('Errore: $e');
      
      // In caso di errore, prova comunque (il servizio ha fallback interni)
      try {
        final hybridService = HybridFootballService();
        final notif = LocalNotifService();
        
        await notif.init();
        
        _controller?.stop();
        _controller = MonitorController(
          api: hybridService, 
          notif: notif, 
          selected: _selected,
          intervalMinutes: _intervalMin,
        );
        
        await _controller!.start();
        setState(() => _isMonitoring = true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monitoraggio avviato con fallback (intervallo: $_intervalMin min)'),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e2) {
        print('Errore anche con servizio di fallback: $e2');
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
      // Errore già gestito con _showError
      _showError('Errore durante l\'aggiornamento: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Nota: La logica di deduzione del paese dalla lega è stata spostata
  // completamente in LiveScoreApiService per evitare duplicazioni e
  // garantire coerenza tra backend e UI.

  @override
  void dispose() {
    _controller?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                    
                    // Raggruppa le partite per nazione
                    print('🌍 INIZIO RAGGRUPPAMENTO: ${fixtures.length} partite da raggruppare');
                    final Map<String, List<Fixture>> groupedFixtures = {};
                    for (final fixture in fixtures) {
                      // Usa direttamente il paese dal backend (LiveScoreApiService)
                      // che ha già la logica completa di deduzione
                      String country = fixture.country;
                      print('   🏟️ Partita: ${fixture.home} vs ${fixture.away}');
                      print('      League: "${fixture.league}"');
                      print('      Paese dal backend: "$country"');
                      
                      // Se il backend non ha trovato un paese, usa 'International'
                      if (country.isEmpty || 
                          country == 'Paese Sconosciuto' || 
                          country == 'Other' || 
                          country == 'Unknown' ||
                          country == 'N/A') {
                        country = 'International';
                        print('      ⚠️ Paese non trovato, uso International');
                      }
                      
                      groupedFixtures.putIfAbsent(country, () => []).add(fixture);
                    }
                    
                    // Ordina i paesi alfabeticamente, ma metti 'International' alla fine
                    final sortedCountries = groupedFixtures.keys.toList()..sort((a, b) {
                      if (a == 'International') return 1;
                      if (b == 'International') return -1;
                      return a.compareTo(b);
                    });
                    
                    print('🌍 RAGGRUPPAMENTO COMPLETATO: ${sortedCountries.length} paesi trovati: $sortedCountries');
                    
                    return Column(
                      children: [
                        // Header informativo per raggruppamento per paesi
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flag, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Partite Raggruppate per Paese',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sortedCountries.length} paesi • ${fixtures.length} partite totali',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _toggleAll(fixtures),
                                    child: Text(_selected.length == fixtures.length
                                        ? 'Deseleziona tutte'
                                        : 'Seleziona tutte'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addSelectedToFollowed,
                                    icon: const Icon(Icons.bookmark, size: 18),
                                    label: const Text('Segui partite'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
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
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sortedCountries.length,
                            itemBuilder: (context, index) {
                              final country = sortedCountries[index];
                              final countryFixtures = groupedFixtures[country]!;
                              final countrySelected = countryFixtures.where((f) => _selected.contains(f.id)).length;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ExpansionTile(
                                  initiallyExpanded: true, // 🎯 ESPANDI AUTOMATICAMENTE TUTTE LE SEZIONI
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      country.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    country,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${countryFixtures.length} partite • $countrySelected selezionate',
                                    style: TextStyle(
                                      color: countrySelected > 0 ? Colors.green : null,
                                      fontWeight: countrySelected > 0 ? FontWeight.bold : null,
                                    ),
                                  ),
                                  trailing: countrySelected > 0 
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                  children: countryFixtures.map((f) {
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
                                      title: Text(
                                        '${f.home} - ${f.away}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('🏆 ${f.league}'),
                                          Text('⏰ ${_formatItalianTime(f.start)}'),
                                          Text('🆔 ${f.id}', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      secondary: const Icon(Icons.sports_soccer),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'followed_matches',
            onPressed: () {
              Navigator.pushNamed(context, '/followed_matches');
            },
            backgroundColor: Colors.purple,
            tooltip: 'Partite Seguite',
            child: const Icon(Icons.bookmark, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'live_results',
            onPressed: () {
              Navigator.pushNamed(context, '/live_results');
            },
            backgroundColor: Colors.red,
            tooltip: 'Risultati Live',
            child: const Icon(Icons.live_tv, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'country_matches',
            onPressed: () {
              Navigator.pushNamed(context, '/country_matches');
            },
            backgroundColor: Colors.orange,
            tooltip: 'Partite per Paese',
            child: const Icon(Icons.flag, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'live_matches',
            onPressed: () {
              Navigator.pushNamed(context, '/live_matches');
            },
            backgroundColor: Colors.blue,
            tooltip: 'Partite Live',
            child: const Icon(Icons.sports_soccer, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'monitor',
            onPressed: _startMonitoring,
            backgroundColor: _isMonitoring ? Colors.red : Colors.green,
            tooltip: _isMonitoring ? 'Ferma monitoraggio' : 'Avvia monitoraggio',
            child: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}
