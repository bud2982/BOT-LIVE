import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:live_bot/models/fixture.dart';

class SofaScoreScraperService {
  // Cache per ridurre le richieste
  Map<String, dynamic> _cache = {};
  DateTime? _lastFetchTime;
  
  // Headers per simulare un browser reale
  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Referer': 'https://www.google.com/',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'max-age=0',
  };
  
  // Metodo principale per ottenere le partite di oggi
  Future<List<Fixture>> getFixturesToday() async {
    // Controlla la cache (aggiorna solo ogni 5 minuti per le partite del giorno)
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        now.difference(_lastFetchTime!).inMinutes < 5 &&
        _cache.containsKey('today')) {
      return _cache['today'];
    }
    
    try {
      // Ottieni le partite da SofaScore
      final fixtures = await _scrapeSofaScore();
      
      // Aggiorna la cache
      _cache['today'] = fixtures;
      _lastFetchTime = now;
      
      return fixtures;
    } catch (e) {
      print('Errore nello scraping di SofaScore: $e');
      return []; // Ritorna lista vuota in caso di errore
    }
  }
  
  // Metodo per ottenere solo le partite live
  Future<List<Fixture>> getLiveMatches() async {
    // Per le partite live, aggiorniamo più frequentemente (ogni minuto)
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        now.difference(_lastFetchTime!).inMinutes < 1 &&
        _cache.containsKey('live')) {
      return _cache['live'];
    }
    
    try {
      // Ottieni tutte le partite
      final allFixtures = await getFixturesToday();
      
      // Filtra solo quelle live (con elapsed non null)
      final liveFixtures = allFixtures.where((f) => f.elapsed != null).toList();
      
      // Aggiorna la cache
      _cache['live'] = liveFixtures;
      
      return liveFixtures;
    } catch (e) {
      print('Errore nel recupero partite live: $e');
      return []; // Ritorna lista vuota in caso di errore
    }
  }
  
  // Scraper per SofaScore
  Future<List<Fixture>> _scrapeSofaScore() async {
    final fixtures = <Fixture>[];
    
    // Ottieni la data di oggi nel formato richiesto da SofaScore
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // URL per le partite di oggi
    final url = 'https://www.sofascore.com/it/calcio/$today';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        
        // Trova tutti i container delle partite
        // Nota: i selettori CSS potrebbero cambiare, quindi potrebbe essere necessario aggiornarli
        final matchElements = document.querySelectorAll('.sc-fqkvVR');
        
        int id = 1;
        for (var element in matchElements) {
          try {
            // Estrai i nomi delle squadre
            final teamElements = element.querySelectorAll('.sc-bXCLTC');
            if (teamElements.length < 2) continue;
            
            final homeTeam = teamElements[0].text.trim();
            final awayTeam = teamElements[1].text.trim();
            
            // Estrai i gol
            final scoreElements = element.querySelectorAll('.sc-fqkvVR');
            int homeGoals = 0;
            int awayGoals = 0;
            
            if (scoreElements.length >= 2) {
              homeGoals = int.tryParse(scoreElements[0].text.trim()) ?? 0;
              awayGoals = int.tryParse(scoreElements[1].text.trim()) ?? 0;
            }
            
            // Estrai lo stato della partita (minuto o orario)
            final statusElement = element.querySelector('.sc-bXCLTC');
            String startTime = '';
            String? elapsedTime;
            
            if (statusElement != null) {
              final statusText = statusElement.text.trim();
              
              // Controlla se la partita è in corso
              if (statusText.contains("'") || RegExp(r'^\d+$').hasMatch(statusText)) {
                elapsedTime = statusText.replaceAll("'", "");
                startTime = 'In corso';
              } else if (statusText.toLowerCase().contains('live')) {
                elapsedTime = 'Live';
                startTime = 'In corso';
              } else {
                // Altrimenti è l'orario di inizio
                startTime = statusText;
              }
            }
            
            // Crea l'oggetto Fixture
            fixtures.add(Fixture(
              id: id++,
              home: homeTeam,
              away: awayTeam,
              goalsHome: homeGoals,
              goalsAway: awayGoals,
              start: startTime,
              elapsed: elapsedTime,
            ));
          } catch (e) {
            print('Errore nel parsing di una partita: $e');
            // Continua con la prossima partita
          }
        }
      } else {
        print('Errore nella richiesta HTTP: ${response.statusCode}');
        print('Risposta: ${response.body}');
        throw Exception('Failed to load webpage: ${response.statusCode}');
      }
    } catch (e) {
      print('Eccezione durante lo scraping: $e');
      throw e;
    }
    
    return fixtures;
  }
  
  // Metodo per generare dati di esempio (fallback se tutto fallisce)
  List<Fixture> getSampleFixtures() {
    return [
      Fixture(
        id: 1,
        home: 'Juventus',
        away: 'Inter',
        goalsHome: 2,
        goalsAway: 1,
        start: '20:45',
        elapsed: '75',
      ),
      Fixture(
        id: 2,
        home: 'Milan',
        away: 'Roma',
        goalsHome: 0,
        goalsAway: 0,
        start: '18:30',
        elapsed: '32',
      ),
      Fixture(
        id: 3,
        home: 'Napoli',
        away: 'Lazio',
        goalsHome: 3,
        goalsAway: 0,
        start: '15:00',
        elapsed: null,
      ),
      Fixture(
        id: 4,
        home: 'Atalanta',
        away: 'Fiorentina',
        goalsHome: 1,
        goalsAway: 1,
        start: '20:45',
        elapsed: null,
      ),
      Fixture(
        id: 5,
        home: 'Bologna',
        away: 'Torino',
        goalsHome: 0,
        goalsAway: 0,
        start: '15:00',
        elapsed: '12',
      ),
    ];
  }
}