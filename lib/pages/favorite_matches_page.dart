import 'package:flutter/material.dart';
import 'dart:async';
import '../models/fixture.dart';
import '../services/hybrid_football_service.dart';
import '../services/favorites_service.dart';

class FavoriteMatchesPage extends StatefulWidget {
  const FavoriteMatchesPage({super.key});

  @override
  State<FavoriteMatchesPage> createState() => _FavoriteMatchesPageState();
}

class _FavoriteMatchesPageState extends State<FavoriteMatchesPage> {
  List<Fixture> _favoriteMatches = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  final HybridFootballService _footballService = HybridFootballService();
  final FavoritesService _favoritesService = FavoritesService.instance;

  @override
  void initState() {
    super.initState();
    _loadFavoriteMatches();
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
      _loadFavoriteMatches();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadFavoriteMatches();
      }
    });
  }

  Future<void> _loadFavoriteMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final allMatches = await _footballService.getFixturesToday();
      final favoriteMatches = _favoritesService.filterFavorites(allMatches);

      // Ordina per stato: live prima, poi per orario
      favoriteMatches.sort((a, b) {
        // Partite live prima
        final aIsLive = a.elapsed != null && a.elapsed! > 0;
        final bIsLive = b.elapsed != null && b.elapsed! > 0;
        
        if (aIsLive && !bIsLive) return -1;
        if (!aIsLive && bIsLive) return 1;
        
        // Se entrambe live, ordina per minuti trascorsi
        if (aIsLive && bIsLive) {
          return (b.elapsed ?? 0).compareTo(a.elapsed ?? 0);
        }
        
        // Altrimenti ordina per orario di inizio
        return a.start.compareTo(b.start);
      });

      setState(() {
        _favoriteMatches = favoriteMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Errore nel caricamento: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(Fixture fixture) async {
    await _favoritesService.removeFromFavorites(fixture.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${fixture.home} vs ${fixture.away} rimossa dai preferiti'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Annulla',
          textColor: Colors.white,
          onPressed: () async {
            await _favoritesService.addToFavorites(fixture.id);
          },
        ),
      ),
    );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Vuoi rimuovere tutte le partite dai preferiti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Conferma', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _favoritesService.clearAllFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutti i preferiti sono stati rimossi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMatchStatus(Fixture fixture) {
    if (fixture.elapsed == null || fixture.elapsed! <= 0) {
      final now = DateTime.now();
      final difference = fixture.start.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}g';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else if (difference.inMinutes > -120) {
        return 'Iniziata';
      } else {
        return 'Finita';
      }
    }
    
    if (fixture.elapsed! <= 45) return '${fixture.elapsed}\'';
    if (fixture.elapsed! <= 90) return '${fixture.elapsed}\'';
    return '${fixture.elapsed}\' +';
  }

  Color _getStatusColor(Fixture fixture) {
    if (fixture.elapsed == null || fixture.elapsed! <= 0) {
      final now = DateTime.now();
      final difference = fixture.start.difference(now);
      
      if (difference.inMinutes > 0) return Colors.blue;
      if (difference.inMinutes > -120) return Colors.orange;
      return Colors.grey;
    }
    
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
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text('Partite Preferite'),
          ],
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteMatches,
            tooltip: 'Aggiorna',
          ),
          if (_favoriteMatches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllFavorites,
              tooltip: 'Rimuovi tutti',
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_favoriteMatches.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
              'Caricamento preferiti...',
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
              onPressed: _loadFavoriteMatches,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_favoriteMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nessuna partita preferita',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi partite ai preferiti per vederle qui',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Torna alle partite'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favoriteMatches.length,
        itemBuilder: (context, index) {
          final match = _favoriteMatches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Fixture match) {
    final statusColor = _getStatusColor(match);
    final statusText = _getMatchStatus(match);
    final isLive = match.elapsed != null && match.elapsed! > 0;

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
                    child: Row(
                      children: [
                        if (isLive) ...[
                          const Icon(Icons.live_tv, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                        ],
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
                      ],
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
                      color: isLive ? Colors.red[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: isLive ? Border.all(color: Colors.red[200]!) : null,
                    ),
                    child: Text(
                      '${match.goalsHome} - ${match.goalsAway}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.red[700] : Colors.black87,
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
                    isLive ? 'LIVE' : 'Preferita',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLive ? Colors.red : Colors.grey[500],
                      fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _removeFromFavorites(match),
                        tooltip: 'Rimuovi dai preferiti',
                      ),
                    ],
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