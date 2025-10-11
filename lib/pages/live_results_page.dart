import 'package:flutter/material.dart';
import 'dart:async';
import '../models/fixture.dart';
import '../services/hybrid_football_service.dart';
import '../services/favorites_service.dart';

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
  final FavoritesService _favoritesService = FavoritesService.instance;

  @override
  void initState() {
    super.initState();
    _loadLiveMatches();
    _startAutoRefresh();
    _favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
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

      final allMatches = await _footballService.getFixturesToday();
      
      // Filtra solo le partite live (con elapsed non null e > 0)
      final liveMatches = allMatches.where((match) {
        return match.elapsed != null && match.elapsed! > 0;
      }).toList();

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

  Future<void> _toggleFavorite(Fixture fixture) async {
    if (_favoritesService.isFavorite(fixture.id)) {
      await _favoritesService.removeFromFavorites(fixture.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fixture.home} vs ${fixture.away} rimossa dai preferiti'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _favoritesService.addToFavorites(fixture.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fixture.home} vs ${fixture.away} aggiunta ai preferiti'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getMatchStatus(Fixture fixture) {
    if (fixture.elapsed == null) return 'Non iniziata';
    if (fixture.elapsed! <= 0) return 'Non iniziata';
    if (fixture.elapsed! <= 45) return '${fixture.elapsed}\'';
    if (fixture.elapsed! <= 90) return '${fixture.elapsed}\'';
    if (fixture.elapsed! > 90) return '${fixture.elapsed}\' +';
    return 'LIVE';
  }

  Color _getStatusColor(Fixture fixture) {
    if (fixture.elapsed == null || fixture.elapsed! <= 0) return Colors.grey;
    if (fixture.elapsed! <= 45) return Colors.green;
    if (fixture.elapsed! <= 90) return Colors.orange;
    return Colors.red;
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
              child: Text('Riprova'),
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
    final isFavorite = _favoritesService.isFavorite(match.id);
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
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(match),
                    tooltip: isFavorite ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
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