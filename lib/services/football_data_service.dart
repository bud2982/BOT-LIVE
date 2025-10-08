import 'dart:convert';
import 'dart:math' show min;
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';
import '../models/fixture_samples.dart';
import '../models/fixture_live_simulator.dart';

/// Servizio per l'API di Football-Data.org (alternativa gratuita a API-Football)
class FootballDataService {
  final String apiKey;
  final bool useSampleData;
  final bool useRealisticSimulation;
  final Duration timeout;
  
  FootballDataService(
    this.apiKey, {
    this.useSampleData = false,
    this.useRealisticSimulation = false,
    this.timeout = const Duration(seconds: 15),
  });

  Map<String, String> get _headers => {
        'X-Auth-Token': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
  bool get _isApiKeyValid => apiKey.isNotEmpty && apiKey.length > 10;

  Future<List<Fixture>> getFixturesToday() async {
    // Verifica se la chiave API è valida
    if (!_isApiKeyValid && !useSampleData) {
      print('ATTENZIONE: Chiave API non valida o mancante. Utilizzo dati di esempio.');
      return FixtureSamples.getSampleFixtures();
    }
    
    // Se useSampleData è true, restituisci dati di esempio
    if (useSampleData) {
      print('Utilizzo dati di esempio per getFixturesToday()');
      return FixtureSamples.getSampleFixtures();
    }
    
    try {
      print('Tentativo di chiamata API reale con chiave: ${apiKey.substring(0, min(10, apiKey.length))}...');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Football-Data.org API per le partite del giorno
      final url = Uri.parse(
          'https://api.football-data.org/v4/matches?date=$today');
      
      print('URL richiesta: $url');
      print('Headers: $_headers');
      
      // Verifica connessione internet prima di fare la richiesta
      try {
        final result = await InternetAddress.lookup('football-data.org');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          print('Nessuna connessione internet disponibile');
          return FixtureSamples.getSampleFixtures();
        }
      } catch (_) {
        print('Nessuna connessione internet disponibile (SocketException)');
        return FixtureSamples.getSampleFixtures();
      }
      
      // Aggiungi un timeout per evitare che la richiesta rimanga bloccata
      final res = await http.get(url, headers: _headers)
          .timeout(timeout, onTimeout: () {
        print('Timeout della richiesta API dopo ${timeout.inSeconds} secondi');
        throw TimeoutException('API request timeout after ${timeout.inSeconds} seconds');
      });
      
      print('Risposta API ricevuta con status code: ${res.statusCode}');
      
      if (res.statusCode != 200) {
        print('API error: ${res.statusCode} - ${res.body}');
        
        // Gestione specifica per errori comuni
        if (res.statusCode == 401) {
          print('Errore di autenticazione: chiave API non valida o scaduta');
        } else if (res.statusCode == 429) {
          print('Limite di richieste API superato');
        } else if (res.statusCode >= 500) {
          print('Errore del server API');
        }
        
        print('Fallback ai dati di esempio dopo errore API');
        return FixtureSamples.getSampleFixtures();
      }
      
      print('Richiesta API completata con successo!');
      
      // Verifica che la risposta non sia vuota
      if (res.body.isEmpty) {
        print('Risposta API vuota');
        return FixtureSamples.getSampleFixtures();
      }
      
      print('Risposta API: ${res.body.substring(0, min(100, res.body.length))}...');
      
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        
        // Verifica che la risposta contenga il campo 'matches'
        if (!data.containsKey('matches')) {
          print('Risposta API non contiene il campo "matches"');
          return FixtureSamples.getSampleFixtures();
        }
        
        // Verifica che 'matches' sia una lista
        if (data['matches'] is! List) {
          print('Il campo "matches" non è una lista');
          return FixtureSamples.getSampleFixtures();
        }
        
        final list = (data['matches'] as List).cast<Map<String, dynamic>>();
        
        // Converti il formato di Football-Data.org nel formato Fixture della tua app
        final fixtures = list.map((match) {
          // Adatta il formato di Football-Data.org al tuo modello Fixture
          return Fixture(
            id: match['id'] ?? 0,
            home: match['homeTeam']?['name'] ?? 'Home Team',
            away: match['awayTeam']?['name'] ?? 'Away Team',
            start: DateTime.parse(match['utcDate'] ?? DateTime.now().toIso8601String()),
            elapsed: _getElapsedMinutes(match),
            goalsHome: match['score']?['fullTime']?['home'] ?? 0,
            goalsAway: match['score']?['fullTime']?['away'] ?? 0,
          );
        }).toList();
        
        print('Partite trovate oggi: ${fixtures.length}');
        
        // Se non ci sono partite, usa i dati di esempio
        if (fixtures.isEmpty) {
          print('Nessuna partita trovata oggi. Utilizzo dati di esempio...');
          return FixtureSamples.getSampleFixtures();
        }
        
        return fixtures;
      } catch (parseError) {
        print('Errore durante il parsing della risposta API: $parseError');
        print('Risposta API che ha causato l\'errore: ${res.body.substring(0, min(200, res.body.length))}...');
        print('Fallback ai dati di esempio dopo errore di parsing');
        return FixtureSamples.getSampleFixtures();
      }
    } catch (e) {
      print('Errore durante la chiamata API: $e');
      print('Stack trace: ${e.toString()}');
      print('Fallback ai dati di esempio dopo eccezione');
      return FixtureSamples.getSampleFixtures();
    }
  }

  Future<List<Fixture>> getLiveByIds(List<int> ids) async {
    if (ids.isEmpty) {
      print('getLiveByIds: Lista IDs vuota, nessuna richiesta necessaria');
      return [];
    }
    
    // Verifica se la chiave API è valida
    if (!_isApiKeyValid && !useSampleData && !useRealisticSimulation) {
      print('ATTENZIONE: Chiave API non valida o mancante. Utilizzo dati di esempio per monitoraggio.');
      return FixtureSamples.getSampleLiveFixtures(ids);
    }
    
    // Se useRealisticSimulation è true, usa il simulatore realistico
    if (useRealisticSimulation) {
      print('Utilizzo simulatore realistico per getLiveByIds()');
      final baseFixtures = await getFixturesToday();
      return FixtureLiveSimulator.getRealisticLiveFixtures(ids, baseFixtures);
    }
    
    // Se useSampleData è true, restituisci dati di esempio
    if (useSampleData) {
      print('Utilizzo dati di esempio per getLiveByIds()');
      return FixtureSamples.getSampleLiveFixtures(ids);
    }
    
    try {
      print('Tentativo di chiamata API reale per monitoraggio con chiave: ${apiKey.substring(0, min(10, apiKey.length))}...');
      
      // Football-Data.org non supporta il recupero di partite specifiche per ID in un'unica chiamata
      // Dobbiamo recuperare tutte le partite del giorno e filtrare per ID
      final allFixtures = await getFixturesToday();
      final filteredFixtures = allFixtures.where((fixture) => ids.contains(fixture.id)).toList();
      
      print('Partite recuperate per il monitoraggio: ${filteredFixtures.length}');
      return filteredFixtures;
    } catch (e) {
      print('Exception during API monitoring call: $e');
      print('Stack trace: ${e.toString()}');
      print('Fallback ai dati di esempio dopo eccezione');
      return FixtureSamples.getSampleLiveFixtures(ids);
    }
  }
  
  // Metodo per verificare se l'API è raggiungibile
  Future<bool> testConnection() async {
    if (!_isApiKeyValid) {
      print('Impossibile testare la connessione: chiave API non valida');
      return false;
    }
    
    try {
      print('Test connessione API...');
      final url = Uri.parse('https://api.football-data.org/v4/competitions');
      
      // Verifica connessione internet prima di fare la richiesta
      try {
        final result = await InternetAddress.lookup('football-data.org');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          print('Nessuna connessione internet disponibile');
          return false;
        }
      } catch (_) {
        print('Nessuna connessione internet disponibile (SocketException)');
        return false;
      }
      
      final res = await http.get(url, headers: _headers)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('Timeout del test di connessione dopo 10 secondi');
        throw TimeoutException('Connection test timeout');
      });
      
      print('Test connessione completato con status code: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        print('Connessione API riuscita!');
        return true;
      } else {
        print('Connessione API fallita con status code: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Errore durante il test di connessione: $e');
      return false;
    }
  }
  
  // Metodi di supporto per convertire i formati
  
  int _getElapsedMinutes(Map<String, dynamic> match) {
    final status = match['status'];
    if (status == 'IN_PLAY' || status == 'LIVE') {
      // Football-Data.org non fornisce i minuti trascorsi, quindi dobbiamo stimarli
      final utcDate = DateTime.parse(match['utcDate']);
      final now = DateTime.now().toUtc();
      final difference = now.difference(utcDate);
      
      // Stima approssimativa dei minuti trascorsi
      int minutes = difference.inMinutes;
      
      // Limita a 45 minuti per primo tempo, 90 per secondo tempo
      if (minutes <= 45) {
        return minutes;
      } else if (minutes <= 60) {
        return 45; // Intervallo
      } else {
        return min(90, minutes - 15); // Secondo tempo (sottrai 15 minuti di intervallo)
      }
    } else if (status == 'PAUSED') {
      return 45; // Intervallo
    } else if (status == 'FINISHED') {
      return 90; // Partita finita
    }
    return 0; // Non iniziata o altro stato
  }
}