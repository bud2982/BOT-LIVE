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
      
      // Parse della lega/competizione
      if (match['competition'] != null && match['competition']['name'] != null) {
        league = match['competition']['name'].toString();
      } else if (match['league'] != null) {
        if (match['league']['name'] != null) {
          league = match['league']['name'].toString();
        } else {
          league = match['league'].toString();
        }
      } else if (match['competition_name'] != null) {
        league = match['competition_name'].toString();
      }
      
      // Parse del paese - migliorato per gestire diversi formati API
      bool countryFound = false;
      
      // Formato 1: country.name (per partite live)
      if (match['country'] != null && match['country']['name'] != null) {
        country = match['country']['name'].toString();
        countryFound = true;
      }
      // Formato 2: competition.country
      else if (match['competition'] != null && match['competition']['country'] != null) {
        if (match['competition']['country'] is Map && match['competition']['country']['name'] != null) {
          country = match['competition']['country']['name'].toString();
          countryFound = true;
        } else {
          country = match['competition']['country'].toString();
          countryFound = true;
        }
      }
      // Formato 3: league.country
      else if (match['league'] != null && match['league']['country'] != null) {
        if (match['league']['country'] is Map && match['league']['country']['name'] != null) {
          country = match['league']['country']['name'].toString();
          countryFound = true;
        } else {
          country = match['league']['country'].toString();
          countryFound = true;
        }
      }
      // Formato 4: federation
      else if (match['federation'] != null) {
        if (match['federation'] is Map && match['federation']['name'] != null) {
          country = match['federation']['name'].toString();
          countryFound = true;
        } else {
          country = match['federation'].toString();
          countryFound = true;
        }
      }
      
      // Se non abbiamo trovato il paese, prova a dedurlo dalla lega
      if (!countryFound) {
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
    
    // Leghe europee principali
    if (leagueLower.contains('serie a') || leagueLower.contains('italian')) return 'Italy';
    if (leagueLower.contains('premier league') || leagueLower.contains('english')) return 'England';
    if (leagueLower.contains('la liga') || leagueLower.contains('spanish')) return 'Spain';
    if (leagueLower.contains('bundesliga') || leagueLower.contains('german')) return 'Germany';
    if (leagueLower.contains('ligue 1') || leagueLower.contains('french')) return 'France';
    
    // Competizioni internazionali
    if (leagueLower.contains('champions league') || 
        leagueLower.contains('europa league') || 
        leagueLower.contains('uefa') ||
        leagueLower.contains('world cup') ||
        leagueLower.contains('euro') ||
        leagueLower.contains('nations league') ||
        leagueLower.contains('friendlies') ||
        leagueLower.contains('national teams')) return 'International';
    
    // Altri paesi europei
    if (leagueLower.contains('portugal') || leagueLower.contains('primeira liga')) return 'Portugal';
    if (leagueLower.contains('netherlands') || leagueLower.contains('eredivisie')) return 'Netherlands';
    if (leagueLower.contains('belgium') || leagueLower.contains('pro league')) return 'Belgium';
    if (leagueLower.contains('scotland') || leagueLower.contains('scottish')) return 'Scotland';
    if (leagueLower.contains('turkey') || leagueLower.contains('turkish')) return 'Turkey';
    if (leagueLower.contains('russia') || leagueLower.contains('russian')) return 'Russia';
    if (leagueLower.contains('ukraine') || leagueLower.contains('ukrainian')) return 'Ukraine';
    if (leagueLower.contains('poland') || leagueLower.contains('polish')) return 'Poland';
    if (leagueLower.contains('czech') || leagueLower.contains('czechia')) return 'Czech Republic';
    if (leagueLower.contains('austria') || leagueLower.contains('austrian')) return 'Austria';
    if (leagueLower.contains('switzerland') || leagueLower.contains('swiss')) return 'Switzerland';
    if (leagueLower.contains('greece') || leagueLower.contains('greek')) return 'Greece';
    if (leagueLower.contains('croatia') || leagueLower.contains('croatian')) return 'Croatia';
    if (leagueLower.contains('serbia') || leagueLower.contains('serbian')) return 'Serbia';
    if (leagueLower.contains('denmark') || leagueLower.contains('danish')) return 'Denmark';
    if (leagueLower.contains('sweden') || leagueLower.contains('swedish')) return 'Sweden';
    if (leagueLower.contains('norway') || leagueLower.contains('norwegian')) return 'Norway';
    
    // Sud America
    if (leagueLower.contains('brazil') || leagueLower.contains('brasileiro') || leagueLower.contains('serie b')) return 'Brazil';
    if (leagueLower.contains('argentina') || leagueLower.contains('argentinian')) return 'Argentina';
    if (leagueLower.contains('colombia') || leagueLower.contains('colombian')) return 'Colombia';
    if (leagueLower.contains('chile') || leagueLower.contains('chilean') || leagueLower.contains('primera division')) return 'Chile';
    if (leagueLower.contains('uruguay') || leagueLower.contains('uruguayan')) return 'Uruguay';
    if (leagueLower.contains('peru') || leagueLower.contains('peruvian')) return 'Peru';
    if (leagueLower.contains('ecuador') || leagueLower.contains('ecuadorian')) return 'Ecuador';
    if (leagueLower.contains('venezuela') || leagueLower.contains('venezuelan')) return 'Venezuela';
    if (leagueLower.contains('bolivia') || leagueLower.contains('bolivian')) return 'Bolivia';
    if (leagueLower.contains('paraguay') || leagueLower.contains('paraguayan')) return 'Paraguay';
    
    // Nord America
    if (leagueLower.contains('mls') || leagueLower.contains('usa') || leagueLower.contains('united states')) return 'United States';
    if (leagueLower.contains('canada') || leagueLower.contains('canadian')) return 'Canada';
    if (leagueLower.contains('mexico') || leagueLower.contains('mexican')) return 'Mexico';
    
    // Asia
    if (leagueLower.contains('japan') || leagueLower.contains('j-league')) return 'Japan';
    if (leagueLower.contains('china') || leagueLower.contains('chinese')) return 'China';
    if (leagueLower.contains('south korea') || leagueLower.contains('korean')) return 'South Korea';
    if (leagueLower.contains('saudi') || leagueLower.contains('arabia')) return 'Saudi Arabia';
    if (leagueLower.contains('uae') || leagueLower.contains('emirates')) return 'UAE';
    if (leagueLower.contains('qatar') || leagueLower.contains('qatari')) return 'Qatar';
    if (leagueLower.contains('iran') || leagueLower.contains('iranian')) return 'Iran';
    if (leagueLower.contains('iraq') || leagueLower.contains('iraqi')) return 'Iraq';
    if (leagueLower.contains('india') || leagueLower.contains('indian')) return 'India';
    if (leagueLower.contains('australia') || leagueLower.contains('a-league')) return 'Australia';
    
    // Africa
    if (leagueLower.contains('egypt') || leagueLower.contains('egyptian')) return 'Egypt';
    if (leagueLower.contains('morocco') || leagueLower.contains('moroccan')) return 'Morocco';
    if (leagueLower.contains('tunisia') || leagueLower.contains('tunisian')) return 'Tunisia';
    if (leagueLower.contains('algeria') || leagueLower.contains('algerian')) return 'Algeria';
    if (leagueLower.contains('south africa') || leagueLower.contains('african')) return 'South Africa';
    if (leagueLower.contains('nigeria') || leagueLower.contains('nigerian')) return 'Nigeria';
    if (leagueLower.contains('ghana') || leagueLower.contains('ghanaian')) return 'Ghana';
    if (leagueLower.contains('ivory coast') || leagueLower.contains('ivorian')) return 'Ivory Coast';
    if (leagueLower.contains('senegal') || leagueLower.contains('senegalese')) return 'Senegal';
    if (leagueLower.contains('cameroon') || leagueLower.contains('cameroonian')) return 'Cameroon';
    if (leagueLower.contains('angola') || leagueLower.contains('angolan')) return 'Angola';
    
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