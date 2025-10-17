import 'package:flutter/material.dart';
import 'dart:async';
import '../models/fixture.dart';
import '../services/hybrid_football_service.dart';
import '../services/followed_matches_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
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
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Usa getLiveMatches() invece di getFixturesToday() per ottenere solo partite live
      final liveMatches = await _footballService.getLiveMatches();
      
      print('🔍 LiveScreen: Ricevute ${liveMatches.length} partite dal servizio');
      
      // DEBUG: Mostra le prime 3 partite con i loro dati
      if (liveMatches.isNotEmpty) {
        for (int i = 0; i < (liveMatches.length > 3 ? 3 : liveMatches.length); i++) {
          final match = liveMatches[i];
          print('  📊 Partita $i: ${match.home} vs ${match.away} - elapsed: ${match.elapsed}');
        }
      }
      
      // Filtra solo le partite effettivamente in corso (esclude finite e non iniziate)
      final activeLiveMatches = liveMatches.where((match) {
        // Partita è live se ha elapsed > 0 (include anche 90+ per recupero/supplementari)
        // Esclude solo partite non iniziate (elapsed == null o elapsed == 0)
        final isLive = match.elapsed != null && match.elapsed! > 0;
        
        if (!isLive) {
          print('  ❌ Filtrata: ${match.home} vs ${match.away} (elapsed: ${match.elapsed})');
        }
        
        return isLive;
      }).toList();
      
      print('✅ LiveScreen: ${activeLiveMatches.length} partite live dopo filtro');

      // Ordina per paese e poi per minuti trascorsi
      activeLiveMatches.sort((a, b) {
        // Prima ordina per paese
        final countryA = a.country;
        final countryB = b.country;
        final countryCompare = countryA.compareTo(countryB);
        if (countryCompare != 0) return countryCompare;
        
        // Poi per minuti trascorsi (partite più avanzate prima)
        final elapsedA = a.elapsed ?? 0;
        final elapsedB = b.elapsed ?? 0;
        return elapsedB.compareTo(elapsedA);
      });

      if (mounted) {
        setState(() {
          _liveMatches = activeLiveMatches;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Errore caricamento partite live: $e');
      if (mounted) {
        setState(() {
          _error = 'Errore nel caricamento: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollowed(Fixture fixture) async {
    final isFollowed = await _followedService.isMatchFollowed(fixture.id);
    
    if (isFollowed) {
      await _followedService.unfollowMatch(fixture.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fixture.home} vs ${fixture.away} non più seguita'),
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
            content: Text('${fixture.home} vs ${fixture.away} ora seguita'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Aggiorna lo stato per riflettere il cambiamento
    if (mounted) {
      setState(() {});
    }
  }

  String _getMatchStatus(Fixture fixture) {
    final elapsed = fixture.elapsed;
    if (elapsed == null) return 'Non iniziata';
    if (elapsed <= 0) return 'Non iniziata';
    if (elapsed <= 45) return '$elapsed\'';
    if (elapsed <= 90) return '$elapsed\'';
    if (elapsed > 90) return '$elapsed\' +';
    return 'LIVE';
  }

  Color _getStatusColor(Fixture fixture) {
    final elapsed = fixture.elapsed;
    if (elapsed == null || elapsed <= 0) return Colors.grey;
    if (elapsed <= 45) return Colors.green;
    if (elapsed <= 90) return Colors.orange;
    return Colors.red;
  }

  // Raggruppa le partite per paese
  Map<String, List<Fixture>> _groupByCountry() {
    final Map<String, List<Fixture>> grouped = {};
    
    for (final match in _liveMatches) {
      final country = match.country;
      if (!grouped.containsKey(country)) {
        grouped[country] = [];
      }
      grouped[country]!.add(match);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.live_tv, color: Colors.red),
            SizedBox(width: 8),
            Text('LIVE'),
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

    // Raggruppa per paese
    final groupedMatches = _groupByCountry();
    final countries = groupedMatches.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadLiveMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final country = countries[index];
          final matches = groupedMatches[country]!;
          return _buildCountrySection(country, matches);
        },
      ),
    );
  }

  Widget _buildCountrySection(String country, List<Fixture> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del paese
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                country,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${matches.length} LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista delle partite
        ...matches.map((match) => _buildMatchCard(match)),
        
        const SizedBox(height: 8),
      ],
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
                      match.league,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                          color: isFollowed ? Colors.purple : Colors.grey,
                        ),
                        onPressed: () => _toggleFollowed(match),
                        tooltip: isFollowed ? 'Non seguire più' : 'Segui partita',
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