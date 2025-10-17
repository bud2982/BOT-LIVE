import 'package:flutter/material.dart';
import 'dart:async';
import '../models/fixture.dart';
import '../services/hybrid_football_service.dart';
import '../services/followed_matches_service.dart';

class LiveResultsPage extends StatefulWidget {
  const LiveResultsPage({super.key});

  @override
  State<LiveResultsPage> createState() => _LiveResultsPageState();
}

class _LiveResultsPageState extends State<LiveResultsPage> {
  List<Fixture> _liveMatches = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  final HybridFootballService _footballService = HybridFootballService();
  final FollowedMatchesService _followedService = FollowedMatchesService();

  @override
  void initState() {
    super.initState();
    _loadLiveMatches();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadLiveMatches();
      }
    });
  }

  Future<void> _loadLiveMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Mostra TUTTE le partite live, incluse quelle appena iniziate (elapsed = 0)
      // Il servizio getLiveMatches() già filtra per partite effettivamente live
      final liveMatches = await _footballService.getLiveMatches();

      // Ordina per minuti trascorsi (partite più avanzate prima)
      liveMatches.sort((a, b) {
        final elapsedA = a.elapsed ?? 0;
        final elapsedB = b.elapsed ?? 0;
        return elapsedB.compareTo(elapsedA);
      });

      setState(() {
        _liveMatches = liveMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore nel caricamento: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollowed(Fixture fixture) async {
    final isFollowed = await _followedService.isMatchFollowed(fixture.id);
    
    if (isFollowed) {
      await _followedService.unfollowMatch(fixture.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fixture.home} vs ${fixture.away} rimossa dalle partite seguite'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _followedService.followMatch(fixture);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fixture.home} vs ${fixture.away} aggiunta alle partite seguite'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Aggiorna la UI
    setState(() {});
  }

  String _getMatchStatus(Fixture fixture) {
    if (fixture.elapsed == null) return 'LIVE'; // Se è nella sezione live ma senza elapsed, è comunque live
    if (fixture.elapsed! == 0) return 'LIVE'; // Appena iniziata
    if (fixture.elapsed! <= 45) return '${fixture.elapsed}\'';
    if (fixture.elapsed! <= 90) return '${fixture.elapsed}\'';
    if (fixture.elapsed! > 90) return '${fixture.elapsed}\' +';
    return 'LIVE';
  }

  Color _getStatusColor(Fixture fixture) {
    if (fixture.elapsed == null) return Colors.red; // Live senza elapsed = rosso (live)
    if (fixture.elapsed! == 0) return Colors.green; // Appena iniziata = verde
    if (fixture.elapsed! <= 45) return Colors.green; // Primo tempo = verde
    if (fixture.elapsed! <= 90) return Colors.orange; // Secondo tempo = arancione
    return Colors.red; // Oltre 90 minuti = rosso
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.live_tv, color: Colors.red),
            SizedBox(width: 8),
            Text('Risultati Live'),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLiveMatches,
            tooltip: 'Aggiorna',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_liveMatches.length} LIVE',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Caricamento partite live...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Errore nel caricamento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLiveMatches,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_liveMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nessuna partita live',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Al momento non ci sono partite in corso',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLiveMatches,
              child: const Text('Aggiorna'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLiveMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _liveMatches.length,
        itemBuilder: (context, index) {
          final match = _liveMatches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Fixture match) {
    final statusColor = _getStatusColor(match);
    final statusText = _getMatchStatus(match);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header con lega e stato
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${match.league} • ${match.country}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Squadre e punteggio
              Row(
                children: [
                  // Squadra casa
                  Expanded(
                    flex: 3,
                    child: Text(
                      match.home,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  
                  // Punteggio
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${match.goalsHome} - ${match.goalsAway}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  // Squadra ospite
                  Expanded(
                    flex: 3,
                    child: Text(
                      match.away,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Azioni
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aggiornato ora',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: _followedService.isMatchFollowed(match.id),
                    builder: (context, snapshot) {
                      final isFollowed = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isFollowed ? Icons.bookmark : Icons.bookmark_border,
                          color: isFollowed ? Colors.deepPurple : Colors.grey,
                        ),
                        onPressed: () => _toggleFollowed(match),
                        tooltip: isFollowed ? 'Rimuovi dalle partite seguite' : 'Aggiungi alle partite seguite',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}