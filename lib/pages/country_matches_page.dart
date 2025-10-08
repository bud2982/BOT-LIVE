import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/country_matches_service.dart';
import '../services/telegram_service.dart';
import '../services/followed_matches_service.dart';
import '../models/fixture.dart';

class CountryMatchesPage extends StatefulWidget {
  const CountryMatchesPage({super.key});

  @override
  State<CountryMatchesPage> createState() => _CountryMatchesPageState();
}

class _CountryMatchesPageState extends State<CountryMatchesPage> {
  final CountryMatchesService _countryService = CountryMatchesService();
  final TelegramService _telegramService = TelegramService();
  final FollowedMatchesService _followedService = FollowedMatchesService();
  
  Map<String, List<Fixture>> _matchesByCountry = {};
  Set<int> _followedMatchIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatchesByCountry();
  }

  Future<void> _loadMatchesByCountry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _countryService.getMatchesByCountry();
      final followedMatches = await _followedService.getFollowedMatches();
      
      setState(() {
        _matchesByCountry = matches;
        _followedMatchIds = followedMatches.map((m) => m.id).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollowMatch(Fixture match) async {
    final isFollowed = _followedMatchIds.contains(match.id);
    
    if (isFollowed) {
      // Rimuovi dalla lista delle seguite
      final success = await _followedService.unfollowMatch(match.id);
      if (success) {
        setState(() {
          _followedMatchIds.remove(match.id);
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
    } else {
      // Aggiungi alla lista delle seguite
      final success = await _followedService.followMatch(match);
      if (success) {
        setState(() {
          _followedMatchIds.add(match.id);
        });
        
        // Controlla se l'utente ha configurato Telegram per le notifiche
        final prefs = await SharedPreferences.getInstance();
        final chatId = prefs.getString('telegram_chat_id');
        
        if (chatId != null && chatId.isNotEmpty) {
          // Registra anche per le notifiche Telegram
          await _telegramService.subscribeToMatch(
            chatId: chatId,
            matchId: match.id,
            matchInfo: match,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Ora segui ${match.home} vs ${match.away}'),
              backgroundColor: Colors.green,
              action: (chatId == null || chatId.isEmpty)
                ? SnackBarAction(
                    label: 'Config',
                    textColor: Colors.white,
                    onPressed: () => Navigator.pushNamed(context, '/telegram_config'),
                  )
                : null,
            ),
          );
        }
      }
    }
  }

  Future<void> _subscribeToMatch(Fixture match) async {
    // Controlla se l'utente ha configurato Telegram
    final prefs = await SharedPreferences.getInstance();
    final chatId = prefs.getString('telegram_chat_id');
    
    if (chatId == null || chatId.isEmpty) {
      // Mostra dialog per configurare Telegram
      _showTelegramConfigDialog();
      return;
    }
    
    final success = await _telegramService.subscribeToMatch(
      chatId: chatId,
      matchId: match.id,
      matchInfo: match,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notifiche attivate per ${match.home} vs ${match.away}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Test',
              textColor: Colors.white,
              onPressed: () => _sendTestNotification(match, chatId),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Errore nell\'attivazione delle notifiche'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTelegramConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.telegram, color: Colors.blue),
            SizedBox(width: 8),
            Text('Configura Telegram'),
          ],
        ),
        content: const Text(
          'Per ricevere notifiche devi prima configurare Telegram.\n\n'
          'Ti servirà il tuo Chat ID Telegram che puoi ottenere scrivendo a @userinfobot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/telegram_config');
            },
            child: const Text('Configura'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(Fixture match, String chatId) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partite per Paese'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.pushNamed(context, '/followed_matches'),
            tooltip: 'Partite Seguite',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatchesByCountry,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento partite per paese...'),
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
              onPressed: _loadMatchesByCountry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_matchesByCountry.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nessuna partita disponibile'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _matchesByCountry.length,
      itemBuilder: (context, index) {
        final country = _matchesByCountry.keys.elementAt(index);
        final matches = _matchesByCountry[country]!;
        
        return _buildCountrySection(country, matches);
      },
    );
  }

  Widget _buildCountrySection(String country, List<Fixture> matches) {
    // Conta le partite live in questo paese
    final liveMatches = matches.where((m) => m.elapsed != null).length;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Row(
          children: [
            _getCountryFlag(country),
            const SizedBox(width: 8),
            Text(
              country,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: liveMatches > 0 ? Colors.red : Colors.black,
              ),
            ),
            const Spacer(),
            if (liveMatches > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'LIVE $liveMatches',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${matches.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: matches.map((match) => _buildMatchTile(match)).toList(),
      ),
    );
  }

  Widget _buildMatchTile(Fixture match) {
    final isFollowed = _followedMatchIds.contains(match.id);
    final isLive = match.elapsed != null;
    
    return ListTile(
      leading: Icon(
        Icons.sports_soccer, 
        color: isLive ? Colors.red : Colors.green,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text('${match.home} vs ${match.away}'),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 ${match.league}'),
          Text('⏰ ${_formatDateTime(match.start)}'),
          if (match.elapsed != null) Text('⏱️ ${match.elapsed}\''),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${match.goalsHome} - ${match.goalsAway}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isFollowed ? Icons.favorite : Icons.favorite_border,
              color: isFollowed ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFollowMatch(match),
            tooltip: isFollowed ? 'Non seguire più' : 'Segui partita',
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.orange),
            onPressed: () => _subscribeToMatch(match),
            tooltip: 'Ricevi notifiche Telegram',
          ),
        ],
      ),
    );
  }

  Widget _getCountryFlag(String country) {
    // Emoji delle bandiere per i paesi principali
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
      style: const TextStyle(fontSize: 24),
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