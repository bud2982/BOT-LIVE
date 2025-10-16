import 'package:flutter/material.dart';
import 'dart:async';
import '../services/followed_matches_service.dart';
import '../services/telegram_service.dart';
import '../services/hybrid_football_service.dart';
import '../models/fixture.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowedMatchesPage extends StatefulWidget {
  const FollowedMatchesPage({super.key});

  @override
  State<FollowedMatchesPage> createState() => _FollowedMatchesPageState();
}

class _FollowedMatchesPageState extends State<FollowedMatchesPage> {
  final FollowedMatchesService _followedService = FollowedMatchesService();
  final TelegramService _telegramService = TelegramService();
  final HybridFootballService _footballService = HybridFootballService();
  
  List<Fixture> _followedMatches = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadFollowedMatches();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Aggiorna ogni 30 secondi per i risultati live
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _followedMatches.isNotEmpty) {
        _updateLiveScores();
      }
    });
  }

  Future<void> _loadFollowedMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Pulisci le partite vecchie prima di caricare
      await _followedService.cleanupOldMatches();
      
      final matches = await _followedService.getFollowedMatches();
      setState(() {
        _followedMatches = matches;
        _isLoading = false;
        _lastUpdate = DateTime.now();
      });
      
      // Aggiorna subito i risultati live dopo il caricamento iniziale
      if (matches.isNotEmpty) {
        _updateLiveScores();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLiveScores() async {
    if (_followedMatches.isEmpty) return;
    
    try {
      print('🔄 Aggiornamento risultati live per ${_followedMatches.length} partite seguite...');
      
      // Estrai gli ID delle partite seguite
      final followedIds = _followedMatches.map((m) => m.id).toList();
      print('📋 IDs partite seguite: $followedIds');
      
      // USA getLiveByIds per recuperare solo le partite seguite (più efficiente)
      final updatedMatches = await _footballService.getLiveByIds(followedIds);
      
      print('📊 Ricevuti aggiornamenti per ${updatedMatches.length} partite');
      
      // Crea una mappa per accesso rapido
      final Map<int, Fixture> updatedMatchesMap = {};
      for (final match in updatedMatches) {
        updatedMatchesMap[match.id] = match;
      }
      
      // Aggiorna i risultati delle partite seguite
      bool hasUpdates = false;
      int updatedCount = 0;
      
      for (int i = 0; i < _followedMatches.length; i++) {
        final followedMatch = _followedMatches[i];
        
        // Cerca la partita aggiornata
        final updatedMatch = updatedMatchesMap[followedMatch.id];
        
        if (updatedMatch == null) {
          print('⚠️ Partita ${followedMatch.home} vs ${followedMatch.away} (ID: ${followedMatch.id}) non trovata negli aggiornamenti');
          continue;
        }
        
        // Controlla se ci sono cambiamenti nei punteggi o nel tempo
        if (updatedMatch.goalsHome != followedMatch.goalsHome ||
            updatedMatch.goalsAway != followedMatch.goalsAway ||
            updatedMatch.elapsed != followedMatch.elapsed) {
          
          print('✅ Aggiornata: ${updatedMatch.home} ${updatedMatch.goalsHome}-${updatedMatch.goalsAway} ${updatedMatch.away} (${updatedMatch.elapsed ?? "N/A"}\')');
          print('   Vecchio: ${followedMatch.goalsHome}-${followedMatch.goalsAway} (${followedMatch.elapsed ?? "N/A"}\')');
          
          // Usa copyWith per preservare il campo 'start' originale
          // e aggiornare solo i campi che cambiano (punteggi e tempo)
          final mergedMatch = followedMatch.copyWith(
            goalsHome: updatedMatch.goalsHome,
            goalsAway: updatedMatch.goalsAway,
            elapsed: updatedMatch.elapsed,
          );
          
          _followedMatches[i] = mergedMatch;
          hasUpdates = true;
          updatedCount++;
          
          // Aggiorna anche in SharedPreferences per persistenza
          await _followedService.followMatch(mergedMatch);
        } else {
          print('ℹ️ Nessun cambiamento per: ${followedMatch.home} vs ${followedMatch.away}');
        }
      }
      
      if (hasUpdates && mounted) {
        setState(() {
          _lastUpdate = DateTime.now();
        });
        print('✅ Aggiornate $updatedCount partite con successo');
      } else {
        print('ℹ️ Nessun aggiornamento necessario per le partite seguite');
      }
    } catch (e) {
      print('⚠️ Errore aggiornamento risultati live: $e');
      print('   Stack trace: ${StackTrace.current}');
      // Non mostrare errore all'utente, continua con i dati esistenti
    }
  }

  Future<void> _unfollowMatch(Fixture match) async {
    final success = await _followedService.unfollowMatch(match.id);
    if (success) {
      setState(() {
        _followedMatches.removeWhere((m) => m.id == match.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Non segui più ${match.home} vs ${match.away}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification(Fixture match) async {
    final prefs = await SharedPreferences.getInstance();
    final chatId = prefs.getString('telegram_chat_id');
    
    if (chatId == null || chatId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Configura prima Telegram per le notifiche'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Configura',
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/telegram_config'),
            ),
          ),
        );
      }
      return;
    }
    
    final message = _telegramService.createMatchReminderMessage(match, 0);
    final success = await _telegramService.sendNotification(
      chatId: chatId,
      message: message,
      matchId: match.id,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Notifica di test inviata! Controlla Telegram'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Errore nell\'invio della notifica'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Partite Seguite'),
            if (_lastUpdate != null)
              Text(
                'Aggiornato: ${_formatTime(_lastUpdate!)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFollowedMatches,
            tooltip: 'Aggiorna manualmente',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/telegram_config'),
            tooltip: 'Configura Telegram',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'ora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m fa';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Caricamento partite seguite...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Errore: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowedMatches,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_followedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nessuna partita seguita',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vai alle partite per paese e segui le partite che ti interessano',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/country_matches'),
              icon: const Icon(Icons.flag),
              label: const Text('Vai alle Partite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Raggruppa le partite per stato (live vs non live)
    final liveMatches = _followedMatches.where((m) => m.elapsed != null).toList();
    final upcomingMatches = _followedMatches.where((m) => m.elapsed == null).toList();

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (liveMatches.isNotEmpty) ...[
          _buildSectionHeader('🔴 PARTITE LIVE', liveMatches.length, Colors.red),
          ...liveMatches.map((match) => _buildMatchCard(match, isLive: true)),
          const SizedBox(height: 16),
        ],
        if (upcomingMatches.isNotEmpty) ...[
          _buildSectionHeader('⏰ PROSSIME PARTITE', upcomingMatches.length, Colors.blue),
          ...upcomingMatches.map((match) => _buildMatchCard(match, isLive: false)),
        ],
     ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Fixture match, {required bool isLive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con squadre e risultato
            Row(
              children: [
                _getCountryFlag(match.country),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.home} vs ${match.away}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '🏆 ${match.league}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${match.goalsHome} - ${match.goalsAway}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLive ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info partita
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(match.start),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (match.elapsed != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.timer,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${match.elapsed}\'',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                // Azioni
                IconButton(
                  icon: const Icon(Icons.notifications_active, color: Colors.orange),
                  onPressed: () => _sendTestNotification(match),
                  tooltip: 'Invia notifica di test',
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => _unfollowMatch(match),
                  tooltip: 'Non seguire più',
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCountryFlag(String country) {
    const Map<String, String> flags = {
      'Italy': '🇮🇹',
      'Spain': '🇪🇸',
      'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'Germany': '🇩🇪',
      'France': '🇫🇷',
      'Netherlands': '🇳🇱',
      'Portugal': '🇵🇹',
      'Brazil': '🇧🇷',
      'Argentina': '🇦🇷',
      'Mexico': '🇲🇽',
      'USA': '🇺🇸',
      'Japan': '🇯🇵',
      'South Korea': '🇰🇷',
      'Australia': '🇦🇺',
      'International': '🌍',
      'Other': '⚽',
    };

    return Text(
      flags[country] ?? '⚽',
      style: const TextStyle(fontSize: 20),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}