import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';

class FollowedMatchesService {
  static const String _followedMatchesKey = 'followed_matches';
  static const String _migrationVersionKey = 'followed_matches_migration_v2';
  
  /// Migrazione dei dati: corregge i timestamp salvati con il parsing locale sbagliato
  /// (prima del fix del timezone)
  Future<void> migrateOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Controlla se la migrazione è già stata eseguita
      final migrated = prefs.getBool(_migrationVersionKey) ?? false;
      if (migrated) {
        print('✅ Migrazione timestamp già eseguita');
        return;
      }
      
      print('🔄 Inizio migrazione timestamp per partite seguite...');
      
      final matchesString = prefs.getString(_followedMatchesKey);
      if (matchesString == null || matchesString.isEmpty) {
        // Nessun dato da migrare
        await prefs.setBool(_migrationVersionKey, true);
        return;
      }
      
      final matchesJson = json.decode(matchesString) as List<dynamic>;
      final now = DateTime.now();
      bool needsUpdate = false;
      
      final migratedMatches = matchesJson.map((matchData) {
        var startTime = DateTime.tryParse(matchData['start'] ?? '') ?? DateTime.now();
        
        // Se il timestamp è nel passato recente (4-6 ore) e dovrebbe essere nel futuro
        // significa che è stato salvato con parsing locale sbagliato
        final timeDiff = startTime.difference(now);
        
        // Logica: se è tra -4 e +2 ore, probabilmente è sbagliato di 4 ore
        // (era salvato come UTC ma interpretato come local timezone)
        if (timeDiff.inHours >= -5 && timeDiff.inHours <= 2) {
          // Verifica se l'orario sembra plausibile (non di notte)
          if (startTime.hour >= 8 && startTime.hour <= 22) {
            // Aggiungi 4 ore per correggerlo
            print('🔧 Correzione timestamp: ${matchData['home']} vs ${matchData['away']}');
            print('   ❌ Prima: $startTime');
            startTime = startTime.add(const Duration(hours: 4));
            print('   ✅ Dopo: $startTime');
            matchData['start'] = startTime.toIso8601String();
            needsUpdate = true;
          }
        }
        
        return matchData;
      }).toList();
      
      if (needsUpdate) {
        print('💾 Salvataggio timestamp migrati...');
        await prefs.setString(_followedMatchesKey, json.encode(migratedMatches));
        print('✅ Timestamp migrati e salvati');
      }
      
      // Segna la migrazione come completata
      await prefs.setBool(_migrationVersionKey, true);
      print('✅ Migrazione completata');
      
    } catch (e) {
      print('💥 Errore durante la migrazione: $e');
    }
  }
  
  /// Aggiunge una partita alla lista delle partite seguite
  Future<bool> followMatch(Fixture match) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followedMatches = await getFollowedMatches();
      
      // Controlla se la partita è già seguita
      final isAlreadyFollowed = followedMatches.any((m) => m.id == match.id);
      if (isAlreadyFollowed) {
        print('⚠️ Partita già seguita: ${match.home} vs ${match.away}');
        return false;
      }
      
      // Aggiungi la partita
      followedMatches.add(match);
      
      // Salva la lista aggiornata
      final matchesJson = followedMatches.map((m) => {
        'id': m.id,
        'home': m.home,
        'away': m.away,
        'goalsHome': m.goalsHome,
        'goalsAway': m.goalsAway,
        'start': m.start.toIso8601String(),
        'elapsed': m.elapsed,
        'league': m.league,
        'country': m.country,
      }).toList();
      
      await prefs.setString(_followedMatchesKey, json.encode(matchesJson));
      
      print('✅ Partita aggiunta alle seguite: ${match.home} vs ${match.away}');
      return true;
      
    } catch (e) {
      print('💥 Errore nel seguire la partita: $e');
      return false;
    }
  }
  
  /// Rimuove una partita dalla lista delle partite seguite
  Future<bool> unfollowMatch(int matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followedMatches = await getFollowedMatches();
      
      // Rimuovi la partita
      final initialLength = followedMatches.length;
      followedMatches.removeWhere((m) => m.id == matchId);
      
      if (followedMatches.length == initialLength) {
        print('⚠️ Partita non trovata nelle seguite: ID $matchId');
        return false;
      }
      
      // Salva la lista aggiornata
      final matchesJson = followedMatches.map((m) => {
        'id': m.id,
        'home': m.home,
        'away': m.away,
        'goalsHome': m.goalsHome,
        'goalsAway': m.goalsAway,
        'start': m.start.toIso8601String(),
        'elapsed': m.elapsed,
        'league': m.league,
        'country': m.country,
      }).toList();
      
      await prefs.setString(_followedMatchesKey, json.encode(matchesJson));
      
      print('✅ Partita rimossa dalle seguite: ID $matchId');
      return true;
      
    } catch (e) {
      print('💥 Errore nel rimuovere la partita seguita: $e');
      return false;
    }
  }
  
  /// Ottiene la lista delle partite seguite
  Future<List<Fixture>> getFollowedMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesString = prefs.getString(_followedMatchesKey);
      
      if (matchesString == null || matchesString.isEmpty) {
        return [];
      }
      
      final matchesJson = json.decode(matchesString) as List<dynamic>;
      
      final matches = matchesJson.map((matchData) {
        var startTime = DateTime.tryParse(matchData['start'] ?? '') ?? DateTime.now();
        
        return Fixture(
          id: matchData['id'] ?? 0,
          home: matchData['home'] ?? 'Unknown',
          away: matchData['away'] ?? 'Unknown',
          goalsHome: matchData['goalsHome'] ?? 0,
          goalsAway: matchData['goalsAway'] ?? 0,
          start: startTime,
          elapsed: matchData['elapsed'],
          league: matchData['league'] ?? 'Unknown League',
          country: matchData['country'] ?? 'Other',
        );
      }).toList();
      
      return matches;
      
    } catch (e) {
      print('💥 Errore nel recuperare le partite seguite: $e');
      return [];
    }
  }
  
  /// Controlla se una partita è seguita
  Future<bool> isMatchFollowed(int matchId) async {
    final followedMatches = await getFollowedMatches();
    return followedMatches.any((m) => m.id == matchId);
  }
  
  /// Ottiene il numero di partite seguite
  Future<int> getFollowedMatchesCount() async {
    final followedMatches = await getFollowedMatches();
    return followedMatches.length;
  }
  
  /// Pulisce le partite seguite terminate (più vecchie di 24 ore)
  Future<void> cleanupOldMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesString = prefs.getString(_followedMatchesKey);
      
      if (matchesString == null || matchesString.isEmpty) {
        return;
      }
      
      final matchesJson = json.decode(matchesString) as List<dynamic>;
      final now = DateTime.now();
      
      // Filtra le partite vecchie
      final followedMatches = matchesJson.map((matchData) {
        return Fixture(
          id: matchData['id'] ?? 0,
          home: matchData['home'] ?? 'Unknown',
          away: matchData['away'] ?? 'Unknown',
          goalsHome: matchData['goalsHome'] ?? 0,
          goalsAway: matchData['goalsAway'] ?? 0,
          start: DateTime.tryParse(matchData['start'] ?? '') ?? DateTime.now(),
          elapsed: matchData['elapsed'],
          league: matchData['league'] ?? 'Unknown League',
          country: matchData['country'] ?? 'Other',
        );
      }).toList();
      
      // Rimuovi partite più vecchie di 24 ore
      final activeMatches = followedMatches.where((match) {
        final hoursSinceStart = now.difference(match.start).inHours;
        return hoursSinceStart < 24; // Mantieni solo partite delle ultime 24 ore
      }).toList();
      
      if (activeMatches.length != followedMatches.length) {
        final matchesJson = activeMatches.map((m) => {
          'id': m.id,
          'home': m.home,
          'away': m.away,
          'goalsHome': m.goalsHome,
          'goalsAway': m.goalsAway,
          'start': m.start.toIso8601String(),
          'elapsed': m.elapsed,
          'league': m.league,
          'country': m.country,
        }).toList();
        
        await prefs.setString(_followedMatchesKey, json.encode(matchesJson));
        
        final removedCount = followedMatches.length - activeMatches.length;
        print('🧹 Rimosse $removedCount partite vecchie dalle seguite');
      }
      
    } catch (e) {
      print('💥 Errore nella pulizia delle partite seguite: $e');
    }
  }
}