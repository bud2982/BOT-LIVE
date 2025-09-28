import 'package:flutter/material.dart';
import '../services/hybrid_football_service.dart';
import '../models/fixture.dart';
import 'package:intl/intl.dart';

class LiveMatchesScreen extends StatefulWidget {
  const LiveMatchesScreen({Key? key}) : super(key: key);

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
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inizializza il servizio ibrido che utilizza SofaScore come fonte primaria
    // e API-Football come fallback (opzionale)
    _footballService = HybridFootballService(
      apiKey: '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f', // Opzionale
      useSampleData: true, // Abilita i dati di esempio come fallback
    );
    
    _loadFixtures();
    
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
  
  Future<void> _loadFixtures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Carica le partite di oggi usando il servizio ibrido
      // che proverà prima SofaScore, poi API-Football, poi dati di esempio
      final todayFixtures = await _footballService.getFixturesToday();
      
      if (todayFixtures.isEmpty) {
        setState(() {
          _errorMessage = 'Nessuna partita trovata per oggi.';
          _isLoading = false;
        });
        return;
      }
      
      // Carica le partite live
      final liveFixtures = await _footballService.getLiveMatches();
      
      if (mounted) {
        setState(() {
          _todayFixtures = todayFixtures;
          _liveFixtures = liveFixtures;
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
      }
    } catch (e) {
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Partite Live (${_liveFixtures.length})'),
            Tab(text: 'Tutte le Partite (${_todayFixtures.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFixtures,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: _isLoading
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
    final bool isFinished = match.elapsed == 'FT' || match.elapsed == '90' || match.elapsed == '90+';
    
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
                    match.start is DateTime 
                        ? _formatDateTime(match.start) 
                        : match.start?.toString() ?? 'Orario non disponibile',
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}