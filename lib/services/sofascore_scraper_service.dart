import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:live_bot/models/fixture.dart';

class SofaScoreScraperService {
  // Cache per ridurre le richieste
  final Map<String, dynamic> _cache = {};
  DateTime? _lastFetchTime;
  
  // Headers per simulare un browser reale (aggiornati a versioni più recenti)
  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
    'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Referer': 'https://www.google.com/',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'max-age=0',
    'sec-ch-ua': '"Chromium";v="140", "Google Chrome";v="140", "Not-A.Brand";v="99"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'cross-site',
    'Sec-Fetch-User': '?1',
  };
  
  // Metodo principale per ottenere le partite di oggi
  Future<List<Fixture>> getFixturesToday() async {
    // Controlla la cache (aggiorna solo ogni 5 minuti per le partite del giorno)
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        now.difference(_lastFetchTime!).inMinutes < 5 &&
        _cache.containsKey('today')) {
      print('Usando dati in cache per le partite di oggi');
      return _cache['today'];
    }
    
    try {
      print('Recuperando partite di oggi da SofaScore...');
      // Ottieni le partite da SofaScore
      final fixtures = await _scrapeSofaScore();
      
      // Verifica se abbiamo ottenuto partite
      if (fixtures.isEmpty) {
        print('Nessuna partita trovata da SofaScore, uso dati di esempio');
        final sampleFixtures = getSampleFixtures();
        
        // Aggiorna la cache con i dati di esempio
        _cache['today'] = sampleFixtures;
        _lastFetchTime = now;
        
        return sampleFixtures;
      }
      
      // Aggiorna la cache
      _cache['today'] = fixtures;
      _lastFetchTime = now;
      
      print('Recuperate ${fixtures.length} partite di oggi');
      return fixtures;
    } catch (e) {
      print('Errore nello scraping di SofaScore: $e');
      print('Uso dati di esempio a causa dell\'errore');
      
      // In caso di errore, usa i dati di esempio
      final sampleFixtures = getSampleFixtures();
      
      // Aggiorna la cache con i dati di esempio
      _cache['today'] = sampleFixtures;
      _lastFetchTime = now;
      
      return sampleFixtures;
    }
  }
  
  // Metodo per ottenere solo le partite live
  Future<List<Fixture>> getLiveMatches() async {
    // Per le partite live, aggiorniamo più frequentemente (ogni minuto)
    final now = DateTime.now();
    if (_lastFetchTime != null && 
        now.difference(_lastFetchTime!).inMinutes < 1 &&
        _cache.containsKey('live')) {
      print('Usando dati in cache per le partite live');
      return _cache['live'];
    }
    
    try {
      print('Recuperando partite live...');
      // Ottieni tutte le partite
      final allFixtures = await getFixturesToday();
      
      // Filtra solo quelle live (con elapsed non null)
      final liveFixtures = allFixtures.where((f) => f.elapsed != null).toList();
      
      // Verifica se abbiamo trovato partite live
      if (liveFixtures.isEmpty) {
        print('Nessuna partita live trovata, uso dati di esempio');
        // Prendi alcune partite di esempio e rendile "live"
        final sampleLive = getSampleFixtures()
          .where((f) => f.elapsed != null)
          .toList();
        
        // Aggiorna la cache
        _cache['live'] = sampleLive;
        
        return sampleLive;
      }
      
      // Aggiorna la cache
      _cache['live'] = liveFixtures;
      
      print('Recuperate ${liveFixtures.length} partite live');
      return liveFixtures;
    } catch (e) {
      print('Errore nel recupero partite live: $e');
      print('Uso dati di esempio a causa dell\'errore');
      
      // In caso di errore, usa i dati di esempio
      final sampleLive = getSampleFixtures()
        .where((f) => f.elapsed != null)
        .toList();
      
      // Aggiorna la cache
      _cache['live'] = sampleLive;
      
      return sampleLive;
    }
  }
  
  // Scraper per SofaScore
  Future<List<Fixture>> _scrapeSofaScore() async {
    // Ottieni la data di oggi nel formato richiesto da SofaScore
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Lista di URL da provare (in ordine di priorità)
    final urls = [
      'https://www.sofascore.com/it/calcio/$today',
      'https://www.sofascore.com/football/$today',
      'https://www.sofascore.com/it/tournament/football/italy/serie-a/$today',
      'https://www.sofascore.com/tournament/football/italy/serie-a/$today',
    ];
    
    // Prova ogni URL fino a quando uno funziona
    for (final url in urls) {
      try {
        print('Iniziando scraping da SofaScore - URL: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: _headers,
        );
        
      if (response.statusCode == 200) {
        print('Risposta HTTP ricevuta con successo (${response.statusCode}) da $url');
        print('Lunghezza risposta: ${response.body.length} caratteri');
        
        // Salva i primi 500 caratteri per debug
        print('Primi 500 caratteri della risposta: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        
        final document = parser.parse(response.body);
        
        // Debug: stampa alcuni elementi trovati
        final allElements = document.querySelectorAll('*');
        print('Totale elementi HTML trovati: ${allElements.length}');
        
        // Prova diversi selettori CSS per adattarsi ai cambiamenti del sito
        final foundFixtures = await _tryMultipleSelectors(document);
        
        if (foundFixtures.isNotEmpty) {
          print('Scraping riuscito da $url! Trovate ${foundFixtures.length} partite');
          return foundFixtures;
        } else {
          print('Nessuna partita trovata con i selettori CSS su $url. Provo un approccio alternativo...');
          
          // Se non troviamo partite, proviamo un approccio più generico
          final fallbackFixtures = _fallbackScraping(document);
          
          if (fallbackFixtures.isNotEmpty) {
            print('Metodo di fallback ha trovato ${fallbackFixtures.length} partite su $url');
            return fallbackFixtures;
          } else {
            print('Anche il metodo di fallback non ha trovato partite. Ritorno dati di esempio.');
            return getSampleFixtures();
          }
        }
      } else {
        print('Errore nella richiesta HTTP a $url: ${response.statusCode}');
      }
    } catch (e) {
      print('Eccezione durante lo scraping di $url: $e');
    }
    }
    
    // Se arriviamo qui, nessun URL ha funzionato, ritorniamo i dati di esempio
    print('Tutti gli URL hanno fallito. Ritorno dati di esempio.');
    return getSampleFixtures();
  }
  
  // Prova diversi selettori CSS per trovare le partite
  Future<List<Fixture>> _tryMultipleSelectors(Document document) async {
    final fixtures = <Fixture>[];
    int id = 1;
    
    // Lista di possibili selettori per i container delle partite
    final selectors = [
      '.sc-fqkvVR',
      '.event',
      '.event__match',
      '.sportName-soccer',
      '.event__container',
      '.event-list',
      '.match-card',
      '.match-row',
      '.event-card',
      // Selettori aggiuntivi per SofaScore 2024
      'div[data-testid="event-card"]',
      'div[data-testid="match-card"]',
      'div[data-testid="event-list-item"]',
      '.sc-hLBbgP',
      '.sc-eDvSVe',
      '.sc-jSUZER',
      '.eventItem',
      '.matchItem',
      'div[class*="match"]',
      'div[class*="event"]',
      'div[class*="game"]',
      'div[class*="fixture"]',
    ];
    
    print('Cercando partite con ${selectors.length} selettori diversi...');
    
    // Stampa alcuni elementi HTML per debug
    final allDivs = document.querySelectorAll('div');
    print('Totale div trovati: ${allDivs.length}');
    if (allDivs.isNotEmpty) {
      print('Primi 5 div (o meno se ce ne sono meno):');
      for (var i = 0; i < min(5, allDivs.length); i++) {
        print('Div $i - classi: ${allDivs[i].classes.join(', ')}');
        print('Div $i - attributi: ${allDivs[i].attributes}');
        print('Div $i - testo: ${allDivs[i].text.substring(0, min(50, allDivs[i].text.length))}...');
      }
    }
    
    for (final selector in selectors) {
      print('Provo il selettore: $selector');
      final elements = document.querySelectorAll(selector);
      print('Trovati ${elements.length} elementi con selettore $selector');
      
      if (elements.isNotEmpty) {
        print('Primo elemento trovato con $selector - classi: ${elements.first.classes.join(', ')}');
        print('Primo elemento trovato con $selector - testo: ${elements.first.text.substring(0, min(50, elements.first.text.length))}...');
        
        for (var element in elements) {
          try {
            // Cerca i nomi delle squadre
            final teamSelectors = [
              '.sc-bXCLTC',
              '.event__participant',
              '.team-name',
              '.participant-name',
              '.event__team',
              'div[data-testid="team-name"]',
              'div[class*="team"]',
              'div[class*="participant"]',
              'span[class*="team"]',
              'span[class*="participant"]',
              '.sc-hLBbgP',
              '.sc-eDvSVe',
            ];
            
            List<Element> teamElements = [];
            for (final teamSelector in teamSelectors) {
              teamElements = element.querySelectorAll(teamSelector);
              if (teamElements.length >= 2) {
                print('Trovati nomi squadre con selettore: $teamSelector');
                break;
              }
            }
            
            if (teamElements.length < 2) {
              print('Non sono stati trovati nomi di squadre per questo elemento, provo il prossimo');
              continue;
            }
            
            final homeTeam = teamElements[0].text.trim();
            final awayTeam = teamElements[1].text.trim();
            print('Squadre trovate: $homeTeam vs $awayTeam');
            
            // Cerca i punteggi
            final scoreSelectors = [
              '.sc-fqkvVR',
              '.event__score',
              '.score',
              '.match-score',
              'div[data-testid="score"]',
              'div[class*="score"]',
              'span[class*="score"]',
              '.sc-jSUZER',
            ];
            
            int homeGoals = 0;
            int awayGoals = 0;
            
            for (final scoreSelector in scoreSelectors) {
              final scoreElements = element.querySelectorAll(scoreSelector);
              if (scoreElements.length >= 2) {
                print('Trovati punteggi con selettore: $scoreSelector');
                homeGoals = int.tryParse(scoreElements[0].text.trim()) ?? 0;
                awayGoals = int.tryParse(scoreElements[1].text.trim()) ?? 0;
                print('Punteggio: $homeGoals - $awayGoals');
                break;
              }
            }
            
            // Cerca lo stato della partita
            final statusSelectors = [
              '.sc-bXCLTC',
              '.event__time',
              '.match-time',
              '.event__status',
              '.status',
              'div[data-testid="match-status"]',
              'div[class*="status"]',
              'div[class*="time"]',
              'span[class*="status"]',
              'span[class*="time"]',
              '.sc-gswNZR',
            ];
            
            String startTime = '';
            String? elapsedTime;
            
            for (final statusSelector in statusSelectors) {
              final statusElement = element.querySelector(statusSelector);
              if (statusElement != null) {
                final statusText = statusElement.text.trim();
                print('Stato partita trovato: "$statusText" con selettore: $statusSelector');
                
                // Controlla se la partita è in corso
                if (statusText.contains("'") || RegExp(r'^\d+$').hasMatch(statusText)) {
                  elapsedTime = statusText.replaceAll("'", "");
                  startTime = 'In corso';
                  print('Partita in corso, minuto: $elapsedTime');
                  break;
                } else if (statusText.toLowerCase().contains('live')) {
                  elapsedTime = 'Live';
                  startTime = 'In corso';
                  print('Partita in corso (LIVE)');
                  break;
                } else {
                  // Altrimenti è l'orario di inizio
                  startTime = statusText;
                  print('Orario di inizio: $startTime');
                  break;
                }
              }
            }
            
            // Converti startTime in DateTime
            DateTime startDateTime;
            try {
              // Se è "In corso" o un altro formato non valido, usa l'ora corrente
              if (startTime == 'In corso' || startTime.isEmpty) {
                startDateTime = DateTime.now();
              } else {
                // Prova a convertire l'orario in un formato DateTime
                final today = DateTime.now();
                final parts = startTime.split(':');
                if (parts.length == 2) {
                  final hour = int.tryParse(parts[0]) ?? 0;
                  final minute = int.tryParse(parts[1]) ?? 0;
                  startDateTime = DateTime(today.year, today.month, today.day, hour, minute);
                } else {
                  startDateTime = DateTime.now();
                }
              }
            } catch (e) {
              print('Errore nella conversione dell\'orario: $e');
              startDateTime = DateTime.now();
            }
            
            // Converti elapsedTime in int?
            int? elapsedInt;
            if (elapsedTime != null) {
              if (elapsedTime.toLowerCase() == 'live') {
                elapsedInt = 1; // Valore arbitrario per indicare che è live
              } else {
                elapsedInt = int.tryParse(elapsedTime);
              }
            }
            
            // Crea l'oggetto Fixture
            fixtures.add(Fixture(
              id: id++,
              home: homeTeam,
              away: awayTeam,
              goalsHome: homeGoals,
              goalsAway: awayGoals,
              start: startDateTime,
              elapsed: elapsedInt,
            ));
            
            print('Aggiunta partita: $homeTeam vs $awayTeam');
          } catch (e) {
            print('Errore nel parsing di una partita: $e');
            // Continua con la prossima partita
          }
        }
        
        // Se abbiamo trovato partite con questo selettore, interrompiamo il ciclo
        if (fixtures.isNotEmpty) {
          print('Trovate ${fixtures.length} partite con il selettore $selector');
          break;
        }
      }
    }
    
    if (fixtures.isEmpty) {
      print('Non sono state trovate partite con nessun selettore. Ritorno dati di esempio.');
      return getSampleFixtures();
    }
    
    return fixtures;
  }
  
  // Metodo di fallback che cerca qualsiasi elemento che potrebbe contenere informazioni sulle partite
  List<Fixture> _fallbackScraping(Document document) {
    print('Utilizzando metodo di scraping di fallback');
    final fixtures = <Fixture>[];
    int id = 1;
    
    try {
      // Cerca qualsiasi elemento che potrebbe contenere testo relativo a squadre di calcio
      final allElements = document.querySelectorAll('*');
      print('Analizzando ${allElements.length} elementi HTML nel metodo di fallback');
      
      // Lista di squadre di calcio italiane e internazionali comuni per il riconoscimento
      final commonTeams = [
        // Squadre italiane
        'Juventus', 'Inter', 'Milan', 'Napoli', 'Roma', 'Lazio', 
        'Atalanta', 'Fiorentina', 'Torino', 'Bologna', 'Sassuolo',
        'Udinese', 'Sampdoria', 'Genoa', 'Cagliari', 'Verona',
        'Empoli', 'Lecce', 'Monza', 'Salernitana', 'Spezia', 'Venezia',
        // Squadre internazionali
        'Barcelona', 'Real Madrid', 'Atletico', 'Sevilla', 'Valencia',
        'Bayern', 'Dortmund', 'Leipzig', 'Leverkusen',
        'PSG', 'Marseille', 'Lyon', 'Monaco',
        'Manchester United', 'Manchester City', 'Liverpool', 'Chelsea', 'Arsenal', 'Tottenham',
        'Ajax', 'PSV', 'Feyenoord',
        'Porto', 'Benfica', 'Sporting'
      ];
      
      // Stampa i primi 10 elementi per debug
      print('Primi 10 elementi (o meno se ce ne sono meno):');
      for (var i = 0; i < min(10, allElements.length); i++) {
        final elementText = allElements[i].text.trim();
        if (elementText.isNotEmpty && elementText.length < 100) {
          print('Elemento $i: $elementText');
        }
      }
      
      // Cerca elementi che contengono nomi di squadre
      for (var i = 0; i < allElements.length; i++) {
        final element = allElements[i];
        final text = element.text.trim();
        
        // Verifica se il testo contiene il nome di una squadra
        bool containsTeam = commonTeams.any((team) => text.contains(team));
        
        if (containsTeam && text.length < 100) { // Evita testi troppo lunghi
          print('Possibile elemento partita trovato: $text');
          
          // Cerca un elemento vicino che potrebbe contenere l'altra squadra
          if (i + 1 < allElements.length) {
            final nextElement = allElements[i + 1];
            final nextText = nextElement.text.trim();
            
            // Verifica se anche questo contiene il nome di una squadra
            bool containsAnotherTeam = commonTeams.any((team) => nextText.contains(team));
            
            if (containsAnotherTeam && nextText.length < 100) {
              print('Possibile coppia di squadre trovata: $text vs $nextText');
              
              // Crea una partita con queste squadre
              fixtures.add(Fixture(
                id: id++,
                home: text,
                away: nextText,
                goalsHome: 0, // Non possiamo determinare i gol
                goalsAway: 0,
                start: DateTime.now(), // Non possiamo determinare l'orario
                elapsed: null, // Non possiamo determinare se è in corso
              ));
            }
          }
        }
      }
      
      print('Metodo di fallback ha trovato ${fixtures.length} possibili partite');
      
      // Se non abbiamo trovato partite, ritorna i dati di esempio
      if (fixtures.isEmpty) {
        print('Il metodo di fallback non ha trovato partite. Ritorno dati di esempio.');
        return getSampleFixtures();
      }
    } catch (e) {
      print('Errore nel metodo di fallback: $e');
      print('Ritorno dati di esempio a causa dell\'errore.');
      return getSampleFixtures();
    }
    
    return fixtures;
  }
  
  // Metodo per generare dati di esempio (fallback se tutto fallisce)
  List<Fixture> getSampleFixtures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Fixture(
        id: 1,
        home: 'Juventus',
        away: 'Inter',
        goalsHome: 2,
        goalsAway: 1,
        start: DateTime(today.year, today.month, today.day, 20, 45),
        elapsed: 75,
      ),
      Fixture(
        id: 2,
        home: 'Milan',
        away: 'Roma',
        goalsHome: 0,
        goalsAway: 0,
        start: DateTime(today.year, today.month, today.day, 18, 30),
        elapsed: 32,
      ),
      Fixture(
        id: 3,
        home: 'Napoli',
        away: 'Lazio',
        goalsHome: 3,
        goalsAway: 0,
        start: DateTime(today.year, today.month, today.day, 15, 0),
        elapsed: null,
      ),
      Fixture(
        id: 4,
        home: 'Atalanta',
        away: 'Fiorentina',
        goalsHome: 1,
        goalsAway: 1,
        start: DateTime(today.year, today.month, today.day, 20, 45),
        elapsed: null,
      ),
      Fixture(
        id: 5,
        home: 'Bologna',
        away: 'Torino',
        goalsHome: 0,
        goalsAway: 0,
        start: DateTime(today.year, today.month, today.day, 15, 0),
        elapsed: 12,
      ),
    ];
  }
}