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
      String league = 'Unknown League';
      String country = 'International';
      
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
      
      print('LiveScoreApiService: Parsing paese per partita $homeTeam vs $awayTeam');
      print('LiveScoreApiService: Struttura match keys: ${match.keys.toList()}');
      
      // Formato 1: country come stringa diretta
      if (match['country'] != null && match['country'] is String) {
        country = match['country'].toString();
        countryFound = true;
        print('LiveScoreApiService: Paese trovato (formato stringa): $country');
      }
      // Formato 2: country.name (per partite live)
      else if (match['country'] != null && match['country'] is Map && match['country']['name'] != null) {
        country = match['country']['name'].toString();
        countryFound = true;
        print('LiveScoreApiService: Paese trovato (formato country.name): $country');
      }
      // Formato 3: location.country
      else if (match['location'] != null && match['location'] is Map) {
        if (match['location']['country'] != null) {
          if (match['location']['country'] is Map && match['location']['country']['name'] != null) {
            country = match['location']['country']['name'].toString();
            countryFound = true;
            print('LiveScoreApiService: Paese trovato (formato location.country.name): $country');
          } else if (match['location']['country'] is String) {
            country = match['location']['country'].toString();
            countryFound = true;
            print('LiveScoreApiService: Paese trovato (formato location.country): $country');
          }
        }
      }
      // Formato 4: competition.country
      else if (match['competition'] != null && match['competition'] is Map && match['competition']['country'] != null) {
        if (match['competition']['country'] is Map && match['competition']['country']['name'] != null) {
          country = match['competition']['country']['name'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato competition.country.name): $country');
        } else if (match['competition']['country'] is String) {
          country = match['competition']['country'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato competition.country): $country');
        }
      }
      // Formato 5: league.country
      else if (match['league'] != null && match['league'] is Map && match['league']['country'] != null) {
        if (match['league']['country'] is Map && match['league']['country']['name'] != null) {
          country = match['league']['country']['name'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato league.country.name): $country');
        } else if (match['league']['country'] is String) {
          country = match['league']['country'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato league.country): $country');
        }
      }
      // Formato 6: federation
      else if (match['federation'] != null) {
        if (match['federation'] is Map && match['federation']['name'] != null) {
          country = match['federation']['name'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato federation.name): $country');
        } else if (match['federation'] is String) {
          country = match['federation'].toString();
          countryFound = true;
          print('LiveScoreApiService: Paese trovato (formato federation): $country');
        }
      }
      
      // Se non abbiamo trovato il paese, prova a dedurlo dalla lega
      if (!countryFound) {
        // Estrai competition_id se disponibile
        int? competitionId;
        if (match['competition_id'] != null) {
          competitionId = int.tryParse(match['competition_id'].toString());
        } else if (match['competition'] != null && match['competition'] is Map && match['competition']['id'] != null) {
          competitionId = int.tryParse(match['competition']['id'].toString());
        }
        
        print('LiveScoreApiService: Paese non trovato nei dati API, deduzione dalla lega: $league (competition_id: $competitionId)');
        print('LiveScoreApiService: Struttura completa match per debug:');
        print('  - competition: ${match['competition']}');
        print('  - league: ${match['league']}');
        print('  - country: ${match['country']}');
        print('  - location: ${match['location']}');
        print('  - federation: ${match['federation']}');
        country = _getCountryFromLeague(league, competitionId);
        print('LiveScoreApiService: Paese dedotto: $country');
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
  
  String _getCountryFromLeague(String league, [int? competitionId]) {
    final leagueLower = league.toLowerCase();
    print('_getCountryFromLeague: Analizzando "$league" (lowercase: "$leagueLower", competitionId: $competitionId)');
    
    // Prima controlla se possiamo usare il competition_id per disambiguare
    if (competitionId != null) {
      // Mappa dei competition_id noti
      switch (competitionId) {
        // Spagna
        case 79: return 'Spain'; // Segunda División (Spagna)
        case 332: return 'Spain'; // Segunda B (Spagna)
        
        // Uruguay
        case 401: return 'Uruguay'; // Segunda División (Uruguay)
        case 48: return 'Uruguay'; // Primera División (Uruguay)
        
        // Perù
        case 406: return 'Peru'; // Segunda División (Perù)
        case 47: return 'Peru'; // Liga 1 / Primera División (Perù)
        
        // Argentina
        case 23: return 'Argentina'; // Liga Professional
        case 96: return 'Argentina'; // Primera Nacional
        case 233: return 'Argentina'; // Primera B Metropolitana
        case 234: return 'Argentina'; // Torneo Federal A
        
        // Brasile
        case 508: return 'Brazil'; // Copa Santa Catarina
        case 509: return 'Brazil'; // Copa Gaúcha
        case 13: return 'Brazil'; // Brasileiro Serie A
        case 14: return 'Brazil'; // Brasileiro Serie B
        
        // Chile
        case 259: return 'Chile'; // Primera B
        case 260: return 'Chile'; // Copa Chile
        case 46: return 'Chile'; // Primera División
        
        // Colombia
        case 45: return 'Colombia'; // Primera A
        
        // Ecuador
        case 398: return 'Ecuador'; // Liga Pro Serie B
        case 44: return 'Ecuador'; // Liga Pro Serie A
        
        // Italia
        case 207: return 'Italy'; // Serie C
        case 11: return 'Italy'; // Serie A
        case 12: return 'Italy'; // Serie B
        
        // USA
        case 384: return 'United States'; // USL League One
        case 253: return 'United States'; // MLS
        
        // Inghilterra
        case 2: return 'England'; // Premier League
        case 3: return 'England'; // Championship
        
        // Competizioni internazionali
        case 359: return 'International'; // World Cup CAF Qualifiers
        case 352: return 'International'; // World Cup UEFA Qualifiers
      }
    }
    
    // Leghe europee principali
    // Italia - Escludi "Liga Pro Serie B" (Ecuador)
    if (leagueLower.contains('serie a') && !leagueLower.contains('brazil') && !leagueLower.contains('liga pro')) return 'Italy';
    if (leagueLower.contains('serie b') && !leagueLower.contains('brazil') && !leagueLower.contains('liga pro')) return 'Italy';
    if (leagueLower.contains('serie c') && !leagueLower.contains('brazil') && !leagueLower.contains('liga pro')) return 'Italy';
    if (leagueLower.contains('coppa italia')) return 'Italy';
    if (leagueLower.contains('premier league') && !leagueLower.contains('canada')) return 'England';
    if (leagueLower.contains('championship') || leagueLower.contains('efl')) return 'England';
    if (leagueLower.contains('fa cup') || leagueLower.contains('carabao')) return 'England';
    if (leagueLower.contains('la liga') || leagueLower.contains('laliga')) return 'Spain';
    if (leagueLower.contains('segunda division') && leagueLower.contains('spain')) return 'Spain';
    if (leagueLower.contains('segunda b') && !leagueLower.contains('argentina')) return 'Spain';
    if (leagueLower.contains('copa del rey')) return 'Spain';
    if (leagueLower.contains('bundesliga')) return 'Germany';
    if (leagueLower.contains('2. bundesliga')) return 'Germany';
    if (leagueLower.contains('dfb-pokal') || leagueLower.contains('dfb pokal')) return 'Germany';
    if (leagueLower.contains('ligue 1') || leagueLower.contains('ligue1')) return 'France';
    if (leagueLower.contains('ligue 2') || leagueLower.contains('ligue2')) return 'France';
    if (leagueLower.contains('coupe de france')) return 'France';
    
    // Competizioni internazionali
    if (leagueLower.contains('champions league') || 
        leagueLower.contains('europa league') || 
        leagueLower.contains('uefa') ||
        leagueLower.contains('world cup') ||
        leagueLower.contains('euro') ||
        leagueLower.contains('nations league') ||
        leagueLower.contains('friendlies') ||
        leagueLower.contains('national teams')) {
      return 'International';
    }
    
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
    // Brasile
    if (leagueLower.contains('brasileiro') || 
        leagueLower.contains('campeonato brasileiro') ||
        (leagueLower.contains('serie') && leagueLower.contains('brazil')) ||
        leagueLower.contains('copa do brasil') ||
        leagueLower.contains('copa gaúcha') ||
        leagueLower.contains('copa santa catarina') ||
        leagueLower.contains('paulista') ||
        leagueLower.contains('carioca') ||
        leagueLower.contains('mineiro')) {
      return 'Brazil';
    }
    
    // Argentina
    if (leagueLower.contains('liga professional') ||
        leagueLower.contains('primera nacional') ||
        leagueLower.contains('primera b metropolitana') ||
        leagueLower.contains('torneo federal') ||
        leagueLower.contains('copa argentina') ||
        (leagueLower.contains('argentina') && !leagueLower.contains('copa'))) {
      return 'Argentina';
    }
    
    // Chile
    if (leagueLower.contains('primera b') && !leagueLower.contains('argentina') ||
        leagueLower.contains('copa chile') ||
        (leagueLower.contains('primera division') && !leagueLower.contains('peru')) ||
        leagueLower.contains('chilean')) {
      return 'Chile';
    }
    
    // Peru
    if (leagueLower.contains('segunda division') && leagueLower.contains('peru') ||
        leagueLower.contains('peruvian') ||
        leagueLower.contains('liga 1') && leagueLower.contains('peru')) {
      return 'Peru';
    }
    
    // Uruguay
    if (leagueLower.contains('segunda division') && leagueLower.contains('uruguay') ||
        leagueLower.contains('uruguayan') ||
        leagueLower.contains('primera division') && leagueLower.contains('uruguay')) {
      return 'Uruguay';
    }
    
    // Colombia
    if (leagueLower.contains('primera a') ||
        leagueLower.contains('colombian') ||
        leagueLower.contains('categoria primera')) {
      return 'Colombia';
    }
    
    // Altri paesi sudamericani
    // Ecuador - DEVE essere prima del check per "Serie B" italiana!
    if (leagueLower.contains('liga pro') || 
        leagueLower.contains('ecuador') || 
        leagueLower.contains('ecuadorian')) {
      return 'Ecuador';
    }
    if (leagueLower.contains('venezuela') || leagueLower.contains('venezuelan')) return 'Venezuela';
    if (leagueLower.contains('bolivia') || leagueLower.contains('bolivian')) return 'Bolivia';
    if (leagueLower.contains('paraguay') || leagueLower.contains('paraguayan')) return 'Paraguay';
    
    // Nord America
    // USA
    if (leagueLower.contains('mls') || 
        leagueLower.contains('usl') ||
        leagueLower.contains('nwsl') ||
        leagueLower.contains('us open cup') ||
        (leagueLower.contains('usa') && !leagueLower.contains('vs')) ||
        leagueLower.contains('united states')) {
      return 'United States';
    }
    
    // Canada
    if (leagueLower.contains('canadian premier league') ||
        leagueLower.contains('canada') ||
        leagueLower.contains('canadian')) {
      return 'Canada';
    }
    
    // Mexico
    if (leagueLower.contains('liga mx') ||
        leagueLower.contains('mexico') ||
        leagueLower.contains('mexican') ||
        leagueLower.contains('copa mx')) {
      return 'Mexico';
    }
    
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