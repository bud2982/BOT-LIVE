import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class RealApiService {
  // TheSportsDB - API gratuita senza chiave
  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  
  // Football-Data.org - API gratuita con limite
  static const String _footballDataUrl = 'https://api.football-data.org/v4';
  
  Future<List<Fixture>> getFixturesToday() async {
    print('RealApiService: Recupero partite di oggi da API reali...');
    
    try {
      // Prima prova con TheSportsDB
      final fixtures = await _getFromTheSportsDB();
      if (fixtures.isNotEmpty) {
        print('RealApiService: Recuperate ${fixtures.length} partite da TheSportsDB');
        return fixtures;
      }
      
      // Se TheSportsDB non ha dati, prova con Football-Data.org
      final footballDataFixtures = await _getFromFootballData();
      if (footballDataFixtures.isNotEmpty) {
        print('RealApiService: Recuperate ${footballDataFixtures.length} partite da Football-Data.org');
        return footballDataFixtures;
      }
      
      print('RealApiService: Nessuna partita trovata dalle API reali');
      return [];
      
    } catch (e) {
      print('RealApiService: Errore durante il recupero partite: $e');
      return [];
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    print('RealApiService: Recupero partite live da API reali...');
    
    try {
      final allFixtures = await getFixturesToday();
      final liveFixtures = allFixtures.where((f) => f.elapsed != null).toList();
      print('RealApiService: Trovate ${liveFixtures.length} partite live');
      return liveFixtures;
    } catch (e) {
      print('RealApiService: Errore durante il recupero partite live: $e');
      return [];
    }
  }
  
  Future<List<Fixture>> _getFromTheSportsDB() async {
    try {
      print('RealApiService: Tentativo con TheSportsDB...');
      
      // Verifica connessione
      final result = await InternetAddress.lookup('thesportsdb.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        print('RealApiService: Nessuna connessione a TheSportsDB');
        return [];
      }
      
      // Recupera le partite di oggi per le principali leghe
      final leagues = [
        '4328', // Serie A
        '4335', // Premier League
        '4334', // La Liga
        '4331', // Bundesliga
        '4332', // Ligue 1
      ];
      
      final List<Fixture> allFixtures = [];
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      for (final leagueId in leagues) {
        try {
          final url = Uri.parse('$_baseUrl/eventsday.php?d=$dateStr&l=$leagueId');
          print('RealApiService: Richiesta a $url');
          
          final response = await http.get(url).timeout(const Duration(seconds: 15));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['events'] != null) {
              final events = data['events'] as List;
              for (final event in events) {
                final fixture = _parseTheSportsDBEvent(event);
                if (fixture != null) {
                  allFixtures.add(fixture);
                }
              }
            }
          }
        } catch (e) {
          print('RealApiService: Errore per lega $leagueId: $e');
          continue;
        }
      }
      
      print('RealApiService: TheSportsDB ha restituito ${allFixtures.length} partite');
      return allFixtures;
      
    } catch (e) {
      print('RealApiService: Errore generale TheSportsDB: $e');
      return [];
    }
  }
  
  Future<List<Fixture>> _getFromFootballData() async {
    try {
      print('RealApiService: Tentativo con Football-Data.org...');
      
      // Verifica connessione
      final result = await InternetAddress.lookup('api.football-data.org');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        print('RealApiService: Nessuna connessione a Football-Data.org');
        return [];
      }
      
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final url = Uri.parse('$_footballDataUrl/matches?dateFrom=$today&dateTo=$today');
      
      print('RealApiService: Richiesta a $url');
      
      final response = await http.get(
        url,
        headers: {
          'X-Auth-Token': 'free-tier', // Token gratuito
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['matches'] != null) {
          final matches = data['matches'] as List;
          final fixtures = matches.map((match) => _parseFootballDataMatch(match))
              .where((f) => f != null)
              .cast<Fixture>()
              .toList();
          
          print('RealApiService: Football-Data.org ha restituito ${fixtures.length} partite');
          return fixtures;
        }
      } else {
        print('RealApiService: Football-Data.org risposta: ${response.statusCode}');
      }
      
      return [];
      
    } catch (e) {
      print('RealApiService: Errore generale Football-Data.org: $e');
      return [];
    }
  }
  
  Fixture? _parseTheSportsDBEvent(Map<String, dynamic> event) {
    try {
      final homeTeam = event['strHomeTeam'] ?? 'Team Casa';
      final awayTeam = event['strAwayTeam'] ?? 'Team Ospite';
      final league = event['strLeague'] ?? 'Lega Sconosciuta';
      final country = _getCountryFromLeague(league);
      
      // Parse data e ora
      final dateStr = event['dateEvent'] ?? '';
      final timeStr = event['strTime'] ?? '00:00:00';
      DateTime? startTime;
      
      if (dateStr.isNotEmpty) {
        try {
          startTime = DateTime.parse('$dateStr $timeStr');
        } catch (e) {
          startTime = DateTime.now();
        }
      } else {
        startTime = DateTime.now();
      }
      
      // Parse punteggi
      int homeGoals = 0;
      int awayGoals = 0;
      int? elapsed;
      
      final homeScore = event['intHomeScore'];
      final awayScore = event['intAwayScore'];
      
      if (homeScore != null) homeGoals = int.tryParse(homeScore.toString()) ?? 0;
      if (awayScore != null) awayGoals = int.tryParse(awayScore.toString()) ?? 0;
      
      // Determina se è live (se ha punteggio e non è finita)
      final status = event['strStatus'] ?? '';
      if (status.contains('Match Finished') == false && (homeScore != null || awayScore != null)) {
        elapsed = 45; // Simula minuto di gioco
      }
      
      return Fixture(
        id: int.tryParse(event['idEvent']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch,
        home: homeTeam,
        away: awayTeam,
        goalsHome: homeGoals,
        goalsAway: awayGoals,
        start: startTime,
        elapsed: elapsed,
        league: league,
        country: country,
      );
      
    } catch (e) {
      print('RealApiService: Errore parsing TheSportsDB event: $e');
      return null;
    }
  }
  
  Fixture? _parseFootballDataMatch(Map<String, dynamic> match) {
    try {
      final homeTeam = match['homeTeam']?['name'] ?? 'Team Casa';
      final awayTeam = match['awayTeam']?['name'] ?? 'Team Ospite';
      final competition = match['competition']?['name'] ?? 'Competizione Sconosciuta';
      final area = match['area']?['name'] ?? 'Paese Sconosciuto';
      
      // Parse data
      final utcDateStr = match['utcDate'] ?? '';
      DateTime? startTime;
      
      if (utcDateStr.isNotEmpty) {
        try {
          startTime = DateTime.parse(utcDateStr);
        } catch (e) {
          startTime = DateTime.now();
        }
      } else {
        startTime = DateTime.now();
      }
      
      // Parse punteggi
      int homeGoals = 0;
      int awayGoals = 0;
      int? elapsed;
      
      final score = match['score'];
      if (score != null && score['fullTime'] != null) {
        homeGoals = score['fullTime']['home'] ?? 0;
        awayGoals = score['fullTime']['away'] ?? 0;
      }
      
      // Determina se è live
      final status = match['status'] ?? '';
      if (status == 'IN_PLAY' || status == 'PAUSED') {
        elapsed = 45; // Simula minuto di gioco
      }
      
      return Fixture(
        id: int.tryParse(match['id']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch,
        home: homeTeam,
        away: awayTeam,
        goalsHome: homeGoals,
        goalsAway: awayGoals,
        start: startTime,
        elapsed: elapsed,
        league: competition,
        country: area,
      );
      
    } catch (e) {
      print('RealApiService: Errore parsing Football-Data match: $e');
      return null;
    }
  }
  
  String _getCountryFromLeague(String league) {
    if (league.contains('Serie A') || league.contains('Italian')) return 'Italy';
    if (league.contains('Premier League') || league.contains('English')) return 'England';
    if (league.contains('La Liga') || league.contains('Spanish')) return 'Spain';
    if (league.contains('Bundesliga') || league.contains('German')) return 'Germany';
    if (league.contains('Ligue 1') || league.contains('French')) return 'France';
    if (league.contains('Champions League') || league.contains('Europa League')) return 'International';
    return 'Unknown';
  }
  
  Future<bool> testConnection() async {
    print('RealApiService: Test connessione alle API reali...');
    
    try {
      // Test TheSportsDB
      final result1 = await InternetAddress.lookup('thesportsdb.com');
      if (result1.isNotEmpty && result1[0].rawAddress.isNotEmpty) {
        print('RealApiService: TheSportsDB raggiungibile');
        return true;
      }
      
      // Test Football-Data.org
      final result2 = await InternetAddress.lookup('api.football-data.org');
      if (result2.isNotEmpty && result2[0].rawAddress.isNotEmpty) {
        print('RealApiService: Football-Data.org raggiungibile');
        return true;
      }
      
      print('RealApiService: Nessuna API raggiungibile');
      return false;
      
    } catch (e) {
      print('RealApiService: Errore durante test connessione: $e');
      return false;
    }
  }
}