import 'dart:convert';
import 'dart:math' show min;
import 'dart:io';
import 'dart:async';  // Aggiunto per TimeoutException
import 'package:http/http.dart' as http;
import '../models/fixture.dart';
import '../models/fixture_samples.dart';

class ApiFootballService {
  final String apiKey;
  final bool useSampleData;
  final Duration timeout;
  
  ApiFootballService(
    this.apiKey, {
    this.useSampleData = false,
    this.timeout = const Duration(seconds: 15),
  });

  Map<String, String> get _headers => {
        'x-apisports-key': apiKey,
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
      final url = Uri.parse(
          'https://v3.football.api-sports.io/fixtures?date=$today');
      
      print('URL richiesta: $url');
      print('Headers: $_headers');
      
      // Verifica connessione internet prima di fare la richiesta
      try {
        final result = await InternetAddress.lookup('api-sports.io');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          print('Nessuna connessione internet disponibile');
          return FixtureSamples.getSampleFixtures();
        }
      } on SocketException catch (_) {
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
        
        // Verifica che la risposta contenga il campo 'response'
        if (!data.containsKey('response')) {
          print('Risposta API non contiene il campo "response"');
          return FixtureSamples.getSampleFixtures();
        }
        
        // Verifica che 'response' sia una lista
        if (data['response'] is! List) {
          print('Il campo "response" non è una lista');
          return FixtureSamples.getSampleFixtures();
        }
        
        final list = (data['response'] as List).cast<Map<String, dynamic>>();
        final fixtures = list.map((e) => Fixture.fromJson(e)).toList();
        
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
    } on TimeoutException catch (e) {
      print('Timeout durante la chiamata API: $e');
      return FixtureSamples.getSampleFixtures();
    } on SocketException catch (e) {
      print('Errore di connessione durante la chiamata API: $e');
      return FixtureSamples.getSampleFixtures();
    } on HttpException catch (e) {
      print('Errore HTTP durante la chiamata API: $e');
      return FixtureSamples.getSampleFixtures();
    } on FormatException catch (e) {
      print('Errore di formato durante la chiamata API: $e');
      return FixtureSamples.getSampleFixtures();
    } catch (e) {
      print('Exception during API call: $e');
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
    if (!_isApiKeyValid && !useSampleData) {
      print('ATTENZIONE: Chiave API non valida o mancante. Utilizzo dati di esempio per monitoraggio.');
      return FixtureSamples.getSampleLiveFixtures(ids);
    }
    
    // Se useSampleData è true, restituisci dati di esempio
    if (useSampleData) {
      print('Utilizzo dati di esempio per getLiveByIds()');
      return FixtureSamples.getSampleLiveFixtures(ids);
    }
    
    try {
      print('Tentativo di chiamata API reale per monitoraggio con chiave: ${apiKey.substring(0, min(10, apiKey.length))}...');
      final idsString = ids.join('-');
      final url = Uri.parse(
          'https://v3.football.api-sports.io/fixtures?ids=$idsString');
      
      print('URL monitoraggio: $url');
      print('Headers: $_headers');
      
      // Verifica connessione internet prima di fare la richiesta
      try {
        final result = await InternetAddress.lookup('api-sports.io');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          print('Nessuna connessione internet disponibile per monitoraggio');
          return FixtureSamples.getSampleLiveFixtures(ids);
        }
      } on SocketException catch (_) {
        print('Nessuna connessione internet disponibile per monitoraggio (SocketException)');
        return FixtureSamples.getSampleLiveFixtures(ids);
      }
      
      // Aggiungi un timeout per evitare che la richiesta rimanga bloccata
      final res = await http.get(url, headers: _headers)
          .timeout(timeout, onTimeout: () {
        print('Timeout della richiesta API di monitoraggio dopo ${timeout.inSeconds} secondi');
        throw TimeoutException('API monitoring request timeout after ${timeout.inSeconds} seconds');
      });
      
      print('Risposta API di monitoraggio ricevuta con status code: ${res.statusCode}');
      
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
        return FixtureSamples.getSampleLiveFixtures(ids);
      }
      
      print('Richiesta API di monitoraggio completata con successo!');
      
      // Verifica che la risposta non sia vuota
      if (res.body.isEmpty) {
        print('Risposta API di monitoraggio vuota');
        return FixtureSamples.getSampleLiveFixtures(ids);
      }
      
      print('Risposta API: ${res.body.substring(0, min(100, res.body.length))}...');
      
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        
        // Verifica che la risposta contenga il campo 'response'
        if (!data.containsKey('response')) {
          print('Risposta API di monitoraggio non contiene il campo "response"');
          return FixtureSamples.getSampleLiveFixtures(ids);
        }
        
        // Verifica che 'response' sia una lista
        if (data['response'] is! List) {
          print('Il campo "response" non è una lista');
          return FixtureSamples.getSampleLiveFixtures(ids);
        }
        
        final list = (data['response'] as List).cast<Map<String, dynamic>>();
        final fixtures = list.map((e) => Fixture.fromJson(e)).toList();
        
        print('Partite recuperate per il monitoraggio: ${fixtures.length}');
        return fixtures;
      } catch (parseError) {
        print('Errore durante il parsing della risposta API di monitoraggio: $parseError');
        print('Risposta API che ha causato l\'errore: ${res.body.substring(0, min(200, res.body.length))}...');
        print('Fallback ai dati di esempio dopo errore di parsing');
        return FixtureSamples.getSampleLiveFixtures(ids);
      }
    } on TimeoutException catch (e) {
      print('Timeout durante la chiamata API di monitoraggio: $e');
      return FixtureSamples.getSampleLiveFixtures(ids);
    } on SocketException catch (e) {
      print('Errore di connessione durante la chiamata API di monitoraggio: $e');
      return FixtureSamples.getSampleLiveFixtures(ids);
    } on HttpException catch (e) {
      print('Errore HTTP durante la chiamata API di monitoraggio: $e');
      return FixtureSamples.getSampleLiveFixtures(ids);
    } on FormatException catch (e) {
      print('Errore di formato durante la chiamata API di monitoraggio: $e');
      return FixtureSamples.getSampleLiveFixtures(ids);
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
      final url = Uri.parse('https://v3.football.api-sports.io/status');
      
      // Verifica connessione internet prima di fare la richiesta
      try {
        final result = await InternetAddress.lookup('api-sports.io');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          print('Nessuna connessione internet disponibile');
          return false;
        }
      } on SocketException catch (_) {
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
}
