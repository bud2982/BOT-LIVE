import 'package:flutter/material.dart';
import '../services/hybrid_football_service.dart';
import '../models/fixture.dart';

class LiveMatchesScreen extends StatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  State<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends State<LiveMatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HybridFootballService _footballService;
  
  List<Fixture> _todayFixtures = [];
  List<Fixture> _liveFixtures = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _lastRefresh = DateTime.now();
  final List<String> _debugLogs = [];
  bool _showDebugLogs = false;
  bool _usingFallbackData = false; // Indica se stiamo usando dati di fallback
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inizializza il servizio e carica i dati
    _initializeService();
    
    // Imposta un timer per aggiornare automaticamente i dati ogni 60 secondi
    // ma solo se l'utente è sulla tab delle partite live
    _tabController.addListener(() {
      if (_tabController.index == 0) { // Tab partite live
        final now = DateTime.now();
        if (now.difference(_lastRefresh).inSeconds > 60) {
          _loadFixtures();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Inizializza il servizio
  Future<void> _initializeService() async {
    try {
      // Inizializza il servizio ibrido che utilizza LiveScore come fonte primaria
      _footballService = HybridFootballService();
      _addLog('Servizio ibrido inizializzato');
      
      // Carica i dati
      await _loadFixtures();
    } catch (e) {
      _addLog('Errore nell\'inizializzazione del servizio: $e');
      // Inizializza comunque il servizio con valori predefiniti
      _footballService = HybridFootballService();
      await _loadFixtures();
    }
  }
  
  // Funzione per aggiungere log di debug
  void _addLog(String log) {
    setState(() {
      _debugLogs.add('${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - $log');
      // Mantieni solo gli ultimi 100 log
      if (_debugLogs.length > 100) {
        _debugLogs.removeAt(0);
      }
    });
  }

  Future<void> _loadFixtures() async {
    _addLog('Inizio caricamento partite');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _usingFallbackData = false;
    });
    
    try {
      // Test di connessione
      _addLog('Test di connessione...');
      final isConnected = await _footballService.testConnection();
      
      if (isConnected) {
        _addLog('Connessione riuscita - Tentativo recupero dati reali');
      } else {
        _addLog('Connessione limitata - Possibile utilizzo dati di fallback');
      }
      
      // Carica le partite di oggi usando il servizio ibrido
      _addLog('Richiesta partite di oggi...');
      final todayFixtures = await _footballService.getFixturesToday();
      
      if (todayFixtures.isEmpty) {
        _addLog('Nessuna partita trovata per oggi');
        setState(() {
          _errorMessage = 'Nessuna partita trovata per oggi.';
          _isLoading = false;
        });
        return;
      }
      
      _addLog('Recuperate ${todayFixtures.length} partite di oggi');
      
      // Determina se stiamo usando dati di fallback
      // (se le partite hanno ID negativi, sono dati di esempio)
      _usingFallbackData = todayFixtures.any((f) => f.id < 0);
      if (_usingFallbackData) {
        _addLog('Rilevato utilizzo dati di fallback');
      } else {
        _addLog('Utilizzo dati reali da LiveScore');
      }
      
      // Carica le partite live
      _addLog('Richiesta partite live...');
      final liveFixtures = await _footballService.getLiveMatches();
      _addLog('Recuperate ${liveFixtures.length} partite live');
      
      if (mounted) {
        setState(() {
          _todayFixtures = todayFixtures;
          _liveFixtures = liveFixtures;
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
      }
    } catch (e) {
      _addLog('ERRORE: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore durante il caricamento delle partite: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partite di Oggi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFixtures,
            tooltip: 'Aggiorna',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              setState(() {
                _showDebugLogs = !_showDebugLogs;
              });
            },
            tooltip: 'Debug',
          ),
        ],
        // Aggiungiamo un sottotitolo per mostrare se stiamo usando dati reali o di esempio
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Partite Live (${_liveFixtures.length})'),
                  Tab(text: 'Tutte le Partite (${_todayFixtures.length})'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: _usingFallbackData ? Colors.orange.shade100 : Colors.green.shade100,
                width: double.infinity,
                child: Text(
                  _usingFallbackData
                      ? 'Utilizzo dati di fallback - Ultimo aggiornamento: ${_lastRefresh.hour}:${_lastRefresh.minute.toString().padLeft(2, '0')}'
                      : 'Dati reali da LiveScore - Ultimo aggiornamento: ${_lastRefresh.hour}:${_lastRefresh.minute.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _showDebugLogs
          ? ListView.builder(
              itemCount: _debugLogs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    _debugLogs[index],
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                );
              },
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadFixtures,
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Partite Live
                    _liveFixtures.isEmpty
                        ? const Center(child: Text('Nessuna partita live al momento'))
                        : RefreshIndicator(
                            onRefresh: _loadFixtures,
                            child: ListView.builder(
                              itemCount: _liveFixtures.length,
                              itemBuilder: (context, index) {
                                return _buildMatchCard(_liveFixtures[index], isLive: true);
                              },
                            ),
                          ),
                    
                    // Tab Tutte le Partite
                    _todayFixtures.isEmpty
                        ? const Center(child: Text('Nessuna partita oggi'))
                        : RefreshIndicator(
                            onRefresh: _loadFixtures,
                            child: ListView.builder(
                              itemCount: _todayFixtures.length,
                              itemBuilder: (context, index) {
                                return _buildMatchCard(_todayFixtures[index]);
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
  
  Widget _buildMatchCard(Fixture match, {bool isLive = false}) {
    final bool isFinished = match.elapsed != null && (match.elapsed == 90 || match.elapsed! > 90);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isLive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLive 
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    match.home, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ' ${match.goalsHome} - ${match.goalsAway} ', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: isLive ? Colors.red.shade900 : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    match.away, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLive && match.elapsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE: ${match.elapsed}\'',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TERMINATA',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    _formatDateTime(match.start),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    // Timestamp già in UTC+1 (convertito al parsing)
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}