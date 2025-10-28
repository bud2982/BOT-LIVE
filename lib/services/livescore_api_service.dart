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
    print('LiveScoreApiService: Recupero partite di oggi da LiveScore API (con paginazione)...');
    
    if (!_isApiKeyValid) {
      print('ERRORE: Chiave API LiveScore non configurata!');
      print('Configura la chiave API in lib/services/livescore_api_service.dart');
      throw Exception('Chiave API LiveScore mancante. Configura _apiKey nel servizio.');
    }
    
    try {
      final List<Fixture> allFixtures = [];
      int currentPage = 1;
      const int maxPages = 30; // Recupera fino a 30 pagine (900 partite) per copertura massima intelligente
      bool hasMorePages = true;
      int pagesLoaded = 0;
      
      // Recupera più pagine per ottenere tutti i campionati importanti
      // Limite intelligente a 30 pagine (include 99% campionati principali mondiali)
      while (hasMorePages && currentPage <= maxPages) {
        print('LiveScoreApiService: Recupero pagina $currentPage...');
        
        final url = Uri.parse('$_baseUrl/fixtures/list.json?key=$_apiKey&secret=$_apiSecret&page=$currentPage');
        
        if (currentPage == 1) {
          print('LiveScoreApiService: Usando chiave API: ${_apiKey.substring(0, 8)}...');
        }
        
        final response = await http.get(url, headers: _headers)
            .timeout(const Duration(seconds: 30));
        
        print('LiveScoreApiService: Pagina $currentPage - Status: ${response.statusCode}');
        
        if (response.statusCode == 401) {
          throw Exception('Chiave API LiveScore non valida o scaduta');
        } else if (response.statusCode == 429) {
          throw Exception('Limite richieste API LiveScore superato');
        } else if (response.statusCode != 200) {
          throw Exception('Errore API LiveScore: ${response.statusCode} - ${response.body}');
        }
        
        if (response.body.isEmpty) {
          print('LiveScoreApiService: Pagina $currentPage vuota, fine paginazione');
          break;
        }
        
        final data = json.decode(response.body);
        
        // Parse della risposta LiveScore
        final fixtures = _parseLiveScoreResponse(data);
        print('LiveScoreApiService: Pagina $currentPage - Trovate ${fixtures.length} partite');
        
        if (fixtures.isEmpty) {
          // Nessuna partita in questa pagina, fine paginazione
          print('LiveScoreApiService: Pagina $currentPage vuota - Fine paginazione raggiunta');
          hasMorePages = false;
        } else {
          allFixtures.addAll(fixtures);
          pagesLoaded = currentPage;
          
          // Se abbiamo meno di 30 partite, probabilmente è l'ultima pagina
          if (fixtures.length < 30) {
            print('LiveScoreApiService: Pagina $currentPage ha solo ${fixtures.length} partite - Fine paginazione (< 30)');
            hasMorePages = false;
          } else {
            currentPage++;
          }
        }
      }
      
      print('LiveScoreApiService: ✅ TOTALE partite recuperate: ${allFixtures.length} (da $pagesLoaded pagine)');
      
      // Rimuovi duplicati basati sull'ID
      final uniqueFixtures = <int, Fixture>{};
      for (final fixture in allFixtures) {
        uniqueFixtures[fixture.id] = fixture;
      }
      
      final finalFixtures = uniqueFixtures.values.toList();
      print('LiveScoreApiService: ✅ Partite uniche dopo deduplicazione: ${finalFixtures.length}');
      
      return finalFixtures;
      
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
      // STRATEGIA DOPPIA: Prova prima matches/live.json, poi fallback a fixtures/list.json filtrate
      List<Fixture> liveFixtures = [];
      
      // TENTATIVO 1: Endpoint matches/live.json (partite live dedicate)
      try {
        final liveUrl = Uri.parse('$_baseUrl/matches/live.json?key=$_apiKey&secret=$_apiSecret');
        print('LiveScoreApiService: Tentativo 1 - matches/live.json');
        
        final liveResponse = await http.get(liveUrl, headers: _headers)
            .timeout(const Duration(seconds: 30));
        
        print('LiveScoreApiService: matches/live.json - Status: ${liveResponse.statusCode}');
        
        if (liveResponse.statusCode == 200 && liveResponse.body.isNotEmpty) {
          final liveData = json.decode(liveResponse.body);
          final fixtures = _parseLiveScoreResponse(liveData, isLiveEndpoint: true);
          
          print('LiveScoreApiService: matches/live.json - Parse completato: ${fixtures.length} partite totali');
          
          // DEBUG: Mostra le prime 3 partite
          if (fixtures.isNotEmpty) {
            for (int i = 0; i < (fixtures.length > 3 ? 3 : fixtures.length); i++) {
              final f = fixtures[i];
              print('  📊 Partita $i: ${f.home} vs ${f.away} - elapsed: ${f.elapsed}');
            }
          }
          
          // Mostra TUTTE le partite live, indipendentemente da elapsed
          // Le partite live possono avere elapsed = 0 (appena iniziate) o null (senza info minuti)
          liveFixtures = fixtures;
          
          print('LiveScoreApiService: matches/live.json - Trovate ${liveFixtures.length} partite live dopo filtro');
        } else {
          print('LiveScoreApiService: matches/live.json - Risposta vuota o errore (status: ${liveResponse.statusCode})');
        }
      } catch (e) {
        print('LiveScoreApiService: matches/live.json fallito: $e');
      }
      
      // TENTATIVO 2: Se non abbiamo partite live, prova con fixtures/list.json filtrate
      if (liveFixtures.isEmpty) {
        print('LiveScoreApiService: Tentativo 2 - Filtro fixtures/list.json per partite live');
        
        try {
          final allFixtures = await getFixturesToday();
          
          // Filtra partite che sono effettivamente live (status-based, non elapsed-based)
          // Manteniamo tutte le partite che potrebbero essere live
          liveFixtures = allFixtures.where((f) {
            // Una partita è live se ha elapsed >= 0 (incluso 0 per appena iniziate)
            // o se non ha elapsed ma potrebbe essere live
            return f.elapsed != null && f.elapsed! >= 0;
          }).toList();
          
          print('LiveScoreApiService: fixtures/list.json filtrate - Trovate ${liveFixtures.length} partite live');
        } catch (e) {
          print('LiveScoreApiService: Anche fixtures/list.json fallito: $e');
        }
      }
      
      print('LiveScoreApiService: ✅ TOTALE partite live: ${liveFixtures.length}');
      return liveFixtures;
      
    } on FormatException catch (e) {
      throw Exception('Errore formato risposta LiveScore API: $e');
    } catch (e) {
      print('LiveScoreApiService: Errore partite live: $e');
      rethrow;
    }
  }
  
  List<Fixture> _parseLiveScoreResponse(Map<String, dynamic> data, {bool isLiveEndpoint = false}) {
    try {
      final List<Fixture> fixtures = [];
      
      // DEBUG: Mostra la struttura della risposta
      print('LiveScoreApiService: 🔍 Analisi struttura risposta API...');
      print('LiveScoreApiService: success = ${data['success']}');
      print('LiveScoreApiService: Chiavi root: ${data.keys.toList()}');
      
      // LiveScore API formato ufficiale
      List<dynamic>? matches;
      
      if (data['success'] == true && data['data'] != null) {
        final dataSection = data['data'];
        
        print('LiveScoreApiService: data è di tipo: ${dataSection.runtimeType}');
        if (dataSection is Map) {
          print('LiveScoreApiService: Chiavi in data: ${dataSection.keys.toList()}');
        }
        
        // IMPORTANTE: fixtures/list.json usa 'fixtures', matches/live.json usa 'match'
        if (isLiveEndpoint && dataSection['match'] != null && dataSection['match'] is List) {
          matches = dataSection['match'] as List<dynamic>;
          print('LiveScoreApiService: ✅ Trovato array "match" (endpoint live) - ${matches.length} elementi');
        } else if (!isLiveEndpoint && dataSection['fixtures'] != null && dataSection['fixtures'] is List) {
          matches = dataSection['fixtures'] as List<dynamic>;
          print('LiveScoreApiService: ✅ Trovato array "fixtures" (endpoint fixtures) - ${matches.length} elementi');
        } else if (dataSection['match'] != null && dataSection['match'] is List) {
          matches = dataSection['match'] as List<dynamic>;
          print('LiveScoreApiService: ✅ Trovato array "match" - ${matches.length} elementi');
        } else if (dataSection['fixtures'] != null && dataSection['fixtures'] is List) {
          matches = dataSection['fixtures'] as List<dynamic>;
          print('LiveScoreApiService: ✅ Trovato array "fixtures" - ${matches.length} elementi');
        } else if (dataSection['fixture'] != null && dataSection['fixture'] is List) {
          matches = dataSection['fixture'] as List<dynamic>;
          print('LiveScoreApiService: ✅ Trovato array "fixture" - ${matches.length} elementi');
        }
      } else if (data['data'] != null && data['data'] is List) {
        matches = data['data'] as List<dynamic>;
        print('LiveScoreApiService: ✅ data è direttamente un array - ${matches.length} elementi');
      } else if (data['matches'] != null && data['matches'] is List) {
        matches = data['matches'] as List<dynamic>;
        print('LiveScoreApiService: ✅ Trovato array "matches" - ${matches.length} elementi');
      } else if (data is List) {
        matches = data as List<dynamic>;
        print('LiveScoreApiService: ✅ Risposta è direttamente un array - ${matches.length} elementi');
      }
      
      if (matches == null) {
        print('LiveScoreApiService: ❌ Formato risposta non riconosciuto');
        print('LiveScoreApiService: Chiavi disponibili: ${data.keys.toList()}');
        if (data['data'] != null && data['data'] is Map) {
          print('LiveScoreApiService: Chiavi in data: ${(data['data'] as Map).keys.toList()}');
        }
        return [];
      }
      
      // DEBUG: Mostra i dati grezzi della prima partita
      if (matches.isNotEmpty) {
        print('LiveScoreApiService: 🔍 Esempio prima partita (dati grezzi):');
        final firstMatch = matches[0];
        if (firstMatch is Map) {
          print('  Chiavi: ${firstMatch.keys.toList()}');
          print('  status: ${firstMatch['status']}');
          print('  time: ${firstMatch['time']}');
          print('  elapsed: ${firstMatch['elapsed']}');
          print('  minute: ${firstMatch['minute']}');
        }
      }
      
      for (final match in matches) {
        try {
          final fixture = _parseLiveScoreMatch(match, isLiveEndpoint: isLiveEndpoint);
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
  
  Fixture? _parseLiveScoreMatch(Map<String, dynamic> match, {bool isLiveEndpoint = false}) {
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
      
      // Prova prima con il campo 'time' (formato "HH:MM:SS" da fixtures/list.json)
      if (match['time'] != null && match['time'].toString().contains(':')) {
        final timeString = match['time'].toString();
        final now = DateTime.now();
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? now.hour;
          final minute = int.tryParse(timeParts[1]) ?? now.minute;
          // Crea come UTC, poi converti a UTC+1 italiano
          startTime = DateTime.utc(now.year, now.month, now.day, hour, minute).add(const Duration(hours: 1));
        }
      }
      // Poi prova con 'scheduled' (formato "HH:MM")
      else if (match['scheduled'] != null) {
        final timeString = match['scheduled'].toString();
        final now = DateTime.now();
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? now.hour;
          final minute = int.tryParse(timeParts[1]) ?? now.minute;
          // Crea come UTC, poi converti a UTC+1 italiano
          startTime = DateTime.utc(now.year, now.month, now.day, hour, minute).add(const Duration(hours: 1));
        }
      } 
      // Poi prova con 'start_time' (formato ISO)
      else if (match['start_time'] != null) {
        startTime = DateTime.tryParse(match['start_time'].toString()) ?? DateTime.now();
      } 
      // Infine prova con 'date' (formato ISO)
      else if (match['date'] != null && match['date'].toString().contains('T')) {
        startTime = DateTime.tryParse(match['date'].toString()) ?? DateTime.now();
      }
      
      // Parse stato partita e minuti (formato LiveScore API)
      int? elapsed;
      final status = match['status']?.toString().toUpperCase() ?? '';
      final timeField = match['time']?.toString() ?? '';
      
      // IMPORTANTE: Distingui tra endpoint live e fixtures
      if (isLiveEndpoint) {
        // Per matches/live.json: usa lo status per determinare se è live
        // Status possibili: "IN PLAY", "FIRST HALF", "SECOND HALF", "HALF TIME BREAK", "FINISHED", "NOT STARTED"
        
        if (status.contains('IN PLAY') || status.contains('FIRST HALF') || status.contains('SECOND HALF')) {
          // Partita in corso - prova a estrarre il minuto dal campo 'time'
          // Il campo 'time' può contenere: "45'", "67'", "90+2'", ecc.
          if (timeField.contains("'")) {
            // Estrai il numero prima dell'apostrofo
            final minuteMatch = RegExp(r'(\d+)').firstMatch(timeField);
            if (minuteMatch != null) {
              elapsed = int.tryParse(minuteMatch.group(1)!);
            }
          } else {
            // Se non c'è apostrofo, prova a parsare direttamente
            elapsed = int.tryParse(timeField);
          }
          
          // Prova anche con il campo 'minute' se disponibile
          if (elapsed == null && match['minute'] != null) {
            elapsed = int.tryParse(match['minute'].toString());
          }
          
          // Prova con il campo 'elapsed' se disponibile
          if (elapsed == null && match['elapsed'] != null) {
            elapsed = int.tryParse(match['elapsed'].toString());
          }
          
          // Se non abbiamo trovato elapsed, imposta un valore di default per indicare che è live
          elapsed ??= 1;
        } else if (status.contains('HALF TIME')) {
          // Intervallo - imposta a 45 minuti
          elapsed = 45;
        } else if (status.contains('FINISHED') || status == 'FT' || timeField == 'FT') {
          // Partita finita - imposta a 90+ per indicare che è terminata
          elapsed = 90;
        }
        // Per "NOT STARTED" o altri status, elapsed rimane null
        
      } else {
        // Per fixtures/list.json: elapsed/time è l'orario (HH:MM:SS), non i minuti
        // Usa solo lo status per determinare se è live
        if (status.contains('IN PLAY') || status.contains('LIVE') || status.contains('PLAYING') || 
            status.contains('FIRST HALF') || status.contains('SECOND HALF')) {
          // Prova a estrarre il minuto se disponibile
          if (match['minute'] != null) {
            elapsed = int.tryParse(match['minute'].toString());
          }
          
          // Prova anche con il campo 'elapsed' se disponibile
          if (elapsed == null && match['elapsed'] != null) {
            elapsed = int.tryParse(match['elapsed'].toString());
          }
          
          // Se non c'è il minuto, imposta un valore di default
          elapsed ??= 1;
        } else if (status.contains('HALF TIME')) {
          elapsed = 45;
        } else if (status.contains('FINISHED') || status == 'FT') {
          elapsed = 90;
        }
        // NON usare match['time'] per fixtures perché è l'orario
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
      
      // Formato 1: country come stringa diretta
      if (match['country'] != null && match['country'] is String) {
        country = match['country'].toString();
        countryFound = true;
      }
      // Formato 2: country.name (per partite live)
      else if (match['country'] != null && match['country'] is Map && match['country']['name'] != null) {
        country = match['country']['name'].toString();
        countryFound = true;
      }
      // Formato 3: location.country
      else if (match['location'] != null && match['location'] is Map) {
        if (match['location']['country'] != null) {
          if (match['location']['country'] is Map && match['location']['country']['name'] != null) {
            country = match['location']['country']['name'].toString();
            countryFound = true;
          } else if (match['location']['country'] is String) {
            country = match['location']['country'].toString();
            countryFound = true;
          }
        }
      }
      // Formato 4: competition.country
      else if (match['competition'] != null && match['competition'] is Map && match['competition']['country'] != null) {
        if (match['competition']['country'] is Map && match['competition']['country']['name'] != null) {
          country = match['competition']['country']['name'].toString();
          countryFound = true;
        } else if (match['competition']['country'] is String) {
          country = match['competition']['country'].toString();
          countryFound = true;
        }
      }
      // Formato 5: league.country
      else if (match['league'] != null && match['league'] is Map && match['league']['country'] != null) {
        if (match['league']['country'] is Map && match['league']['country']['name'] != null) {
          country = match['league']['country']['name'].toString();
          countryFound = true;
        } else if (match['league']['country'] is String) {
          country = match['league']['country'].toString();
          countryFound = true;
        }
      }
      // Formato 6: federation
      else if (match['federation'] != null) {
        if (match['federation'] is Map && match['federation']['name'] != null) {
          country = match['federation']['name'].toString();
          countryFound = true;
        } else if (match['federation'] is String) {
          country = match['federation'].toString();
          countryFound = true;
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
        
        country = _getCountryFromLeague(league, competitionId);
      }
      
      // Parse ID - Se non disponibile, genera uno stabile basato su squadre + orario
      int fixtureId = int.tryParse(match['id']?.toString() ?? '') ?? 0;
      
      if (fixtureId == 0) {
        // Fallback: genera un ID stabile basato su squadre e orario
        // Questo garantisce che la stessa partita avrà sempre lo stesso ID
        final stableKey = '$homeTeam-$awayTeam-${startTime.year}-${startTime.month}-${startTime.day}-${startTime.hour}:${startTime.minute}';
        fixtureId = stableKey.hashCode.abs();
        print('LiveScoreApiService: ⚠️ ID API non disponibile, generato ID stabile: $fixtureId (da $stableKey)');
      }
      
      return Fixture(
        id: fixtureId,
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