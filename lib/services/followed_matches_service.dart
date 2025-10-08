import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';

class FollowedMatchesService {
  static const String _followedMatchesKey = 'followed_matches';
  
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
      
      return matchesJson.map((matchData) {
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
      final followedMatches = await getFollowedMatches();
      final now = DateTime.now();
      
      // Rimuovi partite più vecchie di 24 ore
      final activeMatches = followedMatches.where((match) {
        final hoursSinceStart = now.difference(match.start).inHours;
        return hoursSinceStart < 24; // Mantieni solo partite delle ultime 24 ore
      }).toList();
      
      if (activeMatches.length != followedMatches.length) {
        final prefs = await SharedPreferences.getInstance();
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