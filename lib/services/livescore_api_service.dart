import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class LiveScoreApiService {
  // LiveScore API ufficiale
  static const String _baseUrl = 'https://livescore-api.com/api-client';
  
  // INSERISCI QUI LA TUA CHIAVE API LIVESCORE
  static const String _apiKey = 'wUOF0E1DmdetayWk';
  static const String _apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  
  // Headers per le richieste
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  bool get _isApiKeyValid => _apiKey.isNotEmpty && _apiKey != 'YOUR_LIVESCORE_API_KEY_HERE' && _apiSecret.isNotEmpty;
  
  Future<List<Fixture>> getFixturesToday() async {
    print('LiveScoreApiService: Recupero partite di oggi da LiveScore API...');
    
    if (!_isApiKeyValid) {
      print('ERRORE: Chiave API LiveScore non configurata!');
      print('Configura la chiave API in lib/services/livescore_api_service.dart');
      throw Exception('Chiave API LiveScore mancante. Configura _apiKey nel servizio.');
    }
    
    try {
      // Richiesta partite di oggi (usando fixtures endpoint)
      final url = Uri.parse('$_baseUrl/fixtures/matches.json?key=$_apiKey&secret=$_apiSecret');
      
      print('LiveScoreApiService: Richiesta a $url');
      print('LiveScoreApiService: Usando chiave API: ${_apiKey.substring(0, 8)}...');
      
      final response = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));
      
      print('LiveScoreApiService: Risposta ricevuta - Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        throw Exception('Chiave API LiveScore non valida o scaduta');
      } else if (response.statusCode == 429) {
        throw Exception('Limite richieste API LiveScore superato');
      } else if (response.statusCode != 200) {
        throw Exception('Errore API LiveScore: ${response.statusCode} - ${response.body}');
      }
      
      if (response.body.isEmpty) {
        throw Exception('Risposta API LiveScore vuota');
      }
      
      final data = json.decode(response.body);
      print('LiveScoreApiService: Dati ricevuti: ${response.body.substring(0, 200)}...');
      
      // Parse della risposta LiveScore
      final fixtures = _parseLiveScoreResponse(data);
      print('LiveScoreApiService: Convertite ${fixtures.length} partite');
      
      return fixtures;
      
    } on FormatException catch (e) {
      throw Exception('Errore formato risposta LiveScore API: $e');
    } catch (e) {
      print('LiveScoreApiService: Errore: $e');
      rethrow;
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    print('LiveScoreApiService: Recupero partite live da LiveScore API...');
    
    if (!_isApiKeyValid) {
      throw Exception('Chiave API LiveScore mancante. Configura _apiKey nel servizio.');
    }
    
    try {
      // Richiesta partite live (usando matches/live.json per dati più ricchi)
      final url = Uri.parse('$_baseUrl/matches/live.json?key=$_apiKey&secret=$_apiSecret');
      
      print('LiveScoreApiService: Richiesta partite live a $url');
      
      final response = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 30));
      
      print('LiveScoreApiService: Risposta live ricevuta - Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        throw Exception('Chiave API LiveScore non valida o scaduta');
      } else if (response.statusCode == 429) {
        throw Exception('Limite richieste API LiveScore superato');
      } else if (response.statusCode != 200) {
        throw Exception('Errore API LiveScore: ${response.statusCode} - ${response.body}');
      }
      
      if (response.body.isEmpty) {
        throw Exception('Risposta API LiveScore vuota');
      }
      
      final data = json.decode(response.body);
      print('LiveScoreApiService: Dati live ricevuti: ${response.body.substring(0, 200)}...');
      
      // Parse della risposta LiveScore per partite live
      final fixtures = _parseLiveScoreResponse(data);
      final liveFixtures = fixtures.where((f) => f.elapsed != null).toList();
      
      print('LiveScoreApiService: Trovate ${liveFixtures.length} partite live');
      return liveFixtures;
      
    } on FormatException catch (e) {
      throw Exception('Errore formato risposta LiveScore API: $e');
    } catch (e) {
      print('LiveScoreApiService: Errore partite live: $e');
      rethrow;
    }
  }
  
  List<Fixture> _parseLiveScoreResponse(Map<String, dynamic> data) {
    try {
      final List<Fixture> fixtures = [];
      
      // LiveScore API formato ufficiale
      List<dynamic>? matches;
      
      if (data['success'] == true && data['data'] != null) {
        final dataSection = data['data'];
        if (dataSection['match'] != null && dataSection['match'] is List) {
          matches = dataSection['match'] as List<dynamic>;
        } else if (dataSection['fixtures'] != null && dataSection['fixtures'] is List) {
          matches = dataSection['fixtures'] as List<dynamic>;
        } else if (dataSection['fixture'] != null && dataSection['fixture'] is List) {
          matches = dataSection['fixture'] as List<dynamic>;
        }
      } else if (data['data'] != null && data['data'] is List) {
        matches = data['data'] as List<dynamic>;
      } else if (data['matches'] != null && data['matches'] is List) {
        matches = data['matches'] as List<dynamic>;
      } else if (data is List) {
        matches = data as List<dynamic>;
      }
      
      if (matches == null) {
        print('LiveScoreApiService: Formato risposta non riconosciuto');
        return [];
      }
      
      for (final match in matches) {
        try {
          final fixture = _parseLiveScoreMatch(match);
          if (fixture != null) {
            fixtures.add(fixture);
          }
        } catch (e) {
          print('LiveScoreApiService: Errore parsing singola partita: $e');
          continue;
        }
      }
      
      return fixtures;
      
    } catch (e) {
      print('LiveScoreApiService: Errore parsing risposta: $e');
      return [];
    }
  }
  
  Fixture? _parseLiveScoreMatch(Map<String, dynamic> match) {
    try {
      // Parse squadre (formato LiveScore API)
      String homeTeam = 'Team Casa';
      String awayTeam = 'Team Ospite';
      
      // Per le partite live (formato match)
      if (match['home'] != null && match['home']['name'] != null) {
        homeTeam = match['home']['name'].toString();
      } 
      // Per le fixtures (formato diverso)
      else if (match['home_name'] != null) {
        homeTeam = match['home_name'].toString();
      } else if (match['home_team'] != null) {
        homeTeam = match['home_team']['name'] ?? match['home_team'].toString();
      } else if (match['homeTeam'] != null) {
        homeTeam = match['homeTeam']['name'] ?? match['homeTeam'].toString();
      }
      
      // Per le partite live (formato match)
      if (match['away'] != null && match['away']['name'] != null) {
        awayTeam = match['away']['name'].toString();
      } 
      // Per le fixtures (formato diverso)
      else if (match['away_name'] != null) {
        awayTeam = match['away_name'].toString();
      } else if (match['away_team'] != null) {
        awayTeam = match['away_team']['name'] ?? match['away_team'].toString();
      } else if (match['awayTeam'] != null) {
        awayTeam = match['awayTeam']['name'] ?? match['awayTeam'].toString();
      }
      
      // Parse punteggi (formato LiveScore API)
      int homeGoals = 0;
      int awayGoals = 0;
      
      if (match['scores'] != null && match['scores']['score'] != null) {
        final scoreString = match['scores']['score'].toString();
        final scoreParts = scoreString.split(' - ');
        if (scoreParts.length == 2) {
          homeGoals = int.tryParse(scoreParts[0].trim()) ?? 0;
          awayGoals = int.tryParse(scoreParts[1].trim()) ?? 0;
        }
      } else if (match['score'] != null) {
        homeGoals = int.tryParse(match['score']['home']?.toString() ?? '0') ?? 0;
        awayGoals = int.tryParse(match['score']['away']?.toString() ?? '0') ?? 0;
      } else if (match['home_score'] != null) {
        homeGoals = int.tryParse(match['home_score']?.toString() ?? '0') ?? 0;
        awayGoals = int.tryParse(match['away_score']?.toString() ?? '0') ?? 0;
      }
      
      // Parse data/ora (formato LiveScore API)
      DateTime startTime = DateTime.now();
      if (match['scheduled'] != null) {
        // Il formato scheduled è tipo "08:00"
        final timeString = match['scheduled'].toString();
        final now = DateTime.now();
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? now.hour;
          final minute = int.tryParse(timeParts[1]) ?? now.minute;
          startTime = DateTime(now.year, now.month, now.day, hour, minute);
        }
      } else if (match['start_time'] != null) {
        startTime = DateTime.tryParse(match['start_time'].toString()) ?? DateTime.now();
      } else if (match['date'] != null) {
        startTime = DateTime.tryParse(match['date'].toString()) ?? DateTime.now();
      }
      
      // Parse stato partita e minuti (formato LiveScore API)
      int? elapsed;
      final status = match['status']?.toString().toLowerCase() ?? '';
      
      if (status.contains('in play') || status.contains('live') || status.contains('playing')) {
        elapsed = int.tryParse(match['time']?.toString() ?? '45') ?? 45;
      } else if (match['elapsed'] != null) {
        elapsed = int.tryParse(match['elapsed'].toString());
      } else if (match['minute'] != null) {
        elapsed = int.tryParse(match['minute'].toString());
      }
      
      // Parse competizione e paese (formato LiveScore API)
      String league = 'Competizione Sconosciuta';
      String country = 'Paese Sconosciuto';
      
      if (match['competition'] != null && match['competition']['name'] != null) {
        league = match['competition']['name'].toString();
      } else if (match['league'] != null) {
        league = match['league']['name'] ?? match['league'].toString();
      } else if (match['competition_name'] != null) {
        league = match['competition_name'].toString();
      }
      
      if (match['country'] != null && match['country']['name'] != null) {
        country = match['country']['name'].toString();
      } else if (match['competition'] != null && match['competition']['country'] != null) {
        country = match['competition']['country'].toString();
      } else if (match['federation'] != null) {
        country = match['federation'].toString();
      } else {
        country = _getCountryFromLeague(league);
      }
      
      return Fixture(
        id: int.tryParse(match['id']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch,
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
      print('LiveScoreApiService: Errore parsing partita: $e');
      return null;
    }
  }
  
  String _getCountryFromLeague(String league) {
    final leagueLower = league.toLowerCase();
    
    if (leagueLower.contains('serie a') || leagueLower.contains('italian')) return 'Italy';
    if (leagueLower.contains('premier league') || leagueLower.contains('english')) return 'England';
    if (leagueLower.contains('la liga') || leagueLower.contains('spanish')) return 'Spain';
    if (leagueLower.contains('bundesliga') || leagueLower.contains('german')) return 'Germany';
    if (leagueLower.contains('ligue 1') || leagueLower.contains('french')) return 'France';
    if (leagueLower.contains('champions league') || leagueLower.contains('europa league')) return 'International';
    if (leagueLower.contains('portugal')) return 'Portugal';
    if (leagueLower.contains('netherlands')) return 'Netherlands';
    if (leagueLower.contains('brazil')) return 'Brazil';
    if (leagueLower.contains('argentina')) return 'Argentina';
    
    return 'International';
  }
  
  Future<bool> testConnection() async {
    print('LiveScoreApiService: Test connessione a LiveScore API...');
    
    if (!_isApiKeyValid) {
      print('LiveScoreApiService: Chiave API non configurata');
      return false;
    }
    
    try {
      // Test con endpoint di live matches (usando matches/live.json)
      final url = Uri.parse('$_baseUrl/matches/live.json?key=$_apiKey&secret=$_apiSecret');
      
      final response = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));
      
      final isConnected = response.statusCode == 200;
      print('LiveScoreApiService: Test connessione - Status: ${response.statusCode}, Connesso: $isConnected');
      
      return isConnected;
      
    } catch (e) {
      print('LiveScoreApiService: Errore durante test connessione: $e');
      return false;
    }
  }
}