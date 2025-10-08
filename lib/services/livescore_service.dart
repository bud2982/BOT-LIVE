import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class LiveScoreService {
  static const String _baseUrl = 'http://localhost:3001';
  
  Future<List<Fixture>> getFixturesToday() async {
    print('LiveScoreService: Recupero partite di oggi dalle API ufficiali LiveScore...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/livescore'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('LiveScoreService: Risposta ricevuta - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('LiveScoreService: Dati decodificati - Success: ${data['success']}');
        
        if (data['success'] == true && data['matches'] != null) {
          final List<dynamic> matchesJson = data['matches'];
          print('LiveScoreService: Trovate ${matchesJson.length} partite da LiveScore');
          print('LiveScoreService: Fonte: ${data['source']}');
          
          final fixtures = matchesJson.map((json) => Fixture.fromJson(json)).toList();
          print('LiveScoreService: Convertite ${fixtures.length} partite in oggetti Fixture');
          return fixtures;
        } else {
          print('LiveScoreService: Risposta non valida o nessuna partita trovata');
          return getSampleFixtures();
        }
      } else {
        print('LiveScoreService: Errore HTTP ${response.statusCode}: ${response.body}');
        return getSampleFixtures();
      }
    } catch (e) {
      print('LiveScoreService: Errore durante il recupero partite: $e');
      return getSampleFixtures();
    }
  }

  Future<List<Fixture>> getLiveMatches() async {
    print('LiveScoreService: Recupero partite live dal proxy server...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/live'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('LiveScoreService: Risposta live ricevuta - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('LiveScoreService: Dati live decodificati - Success: ${data['success']}');
        
        if (data['success'] == true && data['matches'] != null) {
          final List<dynamic> matchesJson = data['matches'];
          print('LiveScoreService: Trovate ${matchesJson.length} partite live da LiveScore');
          
          final fixtures = matchesJson.map((json) => Fixture.fromJson(json)).toList();
          print('LiveScoreService: Convertite ${fixtures.length} partite live in oggetti Fixture');
          return fixtures;
        } else {
          print('LiveScoreService: Nessuna partita live trovata');
          return [];
        }
      } else {
        print('LiveScoreService: Errore HTTP live ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('LiveScoreService: Errore durante il recupero partite live: $e');
      return [];
    }
  }

  Future<List<Fixture>> getLiveByIds(List<int> fixtureIds) async {
    print('LiveScoreService: Recupero partite live per IDs: $fixtureIds');
    try {
      // Per ora, recuperiamo tutte le partite live e filtriamo per ID
      final allLive = await getLiveMatches();
      final filtered = allLive.where((f) => fixtureIds.contains(f.id)).toList();
      print('LiveScoreService: Filtrate ${filtered.length} partite live per IDs specifici');
      return filtered;
    } catch (e) {
      print('LiveScoreService: Errore durante getLiveByIds: $e');
      return [];
    }
  }

  Future<bool> testConnection() async {
    print('LiveScoreService: Test connessione alle API ufficiali LiveScore...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/livescore'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final isConnected = response.statusCode == 200 || response.statusCode == 503;
      print('LiveScoreService: Test connessione - Status: ${response.statusCode}, Connesso: $isConnected');
      return isConnected;
    } catch (e) {
      print('LiveScoreService: Errore durante test connessione: $e');
      return false;
    }
  }

  List<Fixture> getSampleFixtures() {
    print('LiveScoreService: Utilizzo dati di esempio come fallback');
    return [
      Fixture(
        id: 1,
        home: 'Juventus',
        away: 'Inter',
        goalsHome: 1,
        goalsAway: 2,
        start: DateTime.now().add(const Duration(hours: 2)),
        elapsed: null,
        league: 'Serie A',
        country: 'Italy',
      ),
      Fixture(
        id: 2,
        home: 'Milan',
        away: 'Napoli',
        goalsHome: 0,
        goalsAway: 1,
        start: DateTime.now().subtract(const Duration(minutes: 45)),
        elapsed: 45,
        league: 'Serie A',
        country: 'Italy',
      ),
      Fixture(
        id: 3,
        home: 'Real Madrid',
        away: 'Barcelona',
        goalsHome: 2,
        goalsAway: 1,
        start: DateTime.now().add(const Duration(hours: 4)),
        elapsed: null,
        league: 'La Liga',
        country: 'Spain',
      ),
      Fixture(
        id: 4,
        home: 'Manchester United',
        away: 'Liverpool',
        goalsHome: 1,
        goalsAway: 1,
        start: DateTime.now().subtract(const Duration(minutes: 30)),
        elapsed: 30,
        league: 'Premier League',
        country: 'England',
      ),
      Fixture(
        id: 5,
        home: 'Bayern Munich',
        away: 'Borussia Dortmund',
        goalsHome: 3,
        goalsAway: 0,
        start: DateTime.now().add(const Duration(hours: 1)),
        elapsed: null,
        league: 'Bundesliga',
        country: 'Germany',
      ),
    ];
  }
}