// Simulazione esatta di quello che fa l'app Flutter
import 'dart:convert';
import 'dart:io';

class Fixture {
  final int id;
  final String home;
  final String away;
  final int goalsHome;
  final int goalsAway;
  final DateTime start;
  final int? elapsed;
  final String league;
  final String country;
  
  Fixture({
    required this.id,
    required this.home,
    required this.away,
    required this.goalsHome,
    required this.goalsAway,
    required this.start,
    this.elapsed,
    required this.league,
    required this.country,
  });
  
  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] ?? 0,
      home: json['home'] ?? 'Team Casa',
      away: json['away'] ?? 'Team Ospite',
      goalsHome: json['goalsHome'] ?? 0,
      goalsAway: json['goalsAway'] ?? 0,
      start: DateTime.tryParse(json['start'] ?? '') ?? DateTime.now(),
      elapsed: json['elapsed'],
      league: json['league'] ?? 'Lega Sconosciuta',
      country: json['country'] ?? 'Other',
    );
  }
}

String getCountryFromLeague(String league) {
  final leagueLower = league.toLowerCase();
  
  // Leghe italiane
  if (leagueLower.contains('serie a') || 
      leagueLower.contains('serie b') || 
      leagueLower.contains('serie c') ||
      leagueLower.contains('coppa italia') ||
      leagueLower.contains('supercoppa italiana')) return 'Italy';
  
  // Leghe inglesi
  if (leagueLower.contains('premier league') || 
      leagueLower.contains('championship') ||
      leagueLower.contains('league one') ||
      leagueLower.contains('league two') ||
      leagueLower.contains('fa cup') ||
      leagueLower.contains('carabao cup') ||
      leagueLower.contains('community shield')) return 'England';
  
  // Leghe spagnole
  if (leagueLower.contains('la liga') || 
      leagueLower.contains('segunda division') ||
      leagueLower.contains('copa del rey') ||
      leagueLower.contains('supercopa de españa')) return 'Spain';
  
  // Leghe tedesche
  if (leagueLower.contains('bundesliga') || 
      leagueLower.contains('2. bundesliga') ||
      leagueLower.contains('dfb-pokal') ||
      leagueLower.contains('dfl-supercup')) return 'Germany';
  
  // Leghe francesi
  if (leagueLower.contains('ligue 1') || 
      leagueLower.contains('ligue 2') ||
      leagueLower.contains('coupe de france') ||
      leagueLower.contains('trophée des champions')) return 'France';
  
  return 'Other';
}

Future<void> main() async {
  print('🧪 SIMULAZIONE FLUTTER APP - Test raggruppamento');
  print('================================================');
  
  try {
    // Simula la chiamata HTTP che fa TestProxyService
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3001/api/livescore'));
    final response = await request.close();
    
    if (response.statusCode != 200) {
      print('❌ Errore server: ${response.statusCode}');
      return;
    }
    
    final responseBody = await response.transform(utf8.decoder).join();
    final data = json.decode(responseBody);
    
    print('✅ Dati ricevuti dal server proxy');
    
    // Parse delle fixtures (come fa TestProxyService)
    final List<Fixture> fixtures = [];
    if (data['success'] == true && data['matches'] != null) {
      final matches = data['matches'] as List<dynamic>;
      
      for (final match in matches) {
        try {
          final fixture = Fixture.fromJson(match);
          fixtures.add(fixture);
        } catch (e) {
          print('⚠️ Errore parsing partita: $e');
          continue;
        }
      }
    }
    
    print('📊 Partite caricate: ${fixtures.length}');
    
    // Simula la logica di raggruppamento dell'home_screen.dart
    print('🌍 INIZIO RAGGRUPPAMENTO: ${fixtures.length} partite da raggruppare');
    final Map<String, List<Fixture>> groupedFixtures = {};
    
    for (final fixture in fixtures) {
      String country = fixture.country;
      print('   🏟️ Partita: ${fixture.home} vs ${fixture.away}');
      print('      Paese originale: "$country"');
      print('      League: "${fixture.league}"');
      
      // Se il paese è vuoto, sconosciuto o generico, prova a dedurlo dalla lega
      if (country.isEmpty || 
          country == 'Paese Sconosciuto' || 
          country == 'Other' || 
          country == 'Unknown' ||
          country == 'N/A') {
        final deducedCountry = getCountryFromLeague(fixture.league);
        print('      Paese dedotto dalla league: "$deducedCountry"');
        country = deducedCountry;
      }
      
      // Se ancora non abbiamo un paese valido, usa 'Internazionale'
      if (country.isEmpty || 
          country == 'Paese Sconosciuto' || 
          country == 'Other' || 
          country == 'Unknown' ||
          country == 'N/A') {
        country = 'Internazionale';
      }
      
      print('      Paese finale: "$country"');
      groupedFixtures.putIfAbsent(country, () => []).add(fixture);
      print('      ---');
    }
    
    // Ordina i paesi alfabeticamente, ma metti 'Internazionale' alla fine
    final sortedCountries = groupedFixtures.keys.toList()..sort((a, b) {
      if (a == 'Internazionale') return 1;
      if (b == 'Internazionale') return -1;
      return a.compareTo(b);
    });
    
    print('🌍 RAGGRUPPAMENTO COMPLETATO: ${sortedCountries.length} paesi trovati: $sortedCountries');
    print('');
    
    // Simula la creazione degli ExpansionTile
    print('📱 SIMULAZIONE UI - ExpansionTile per ogni paese:');
    print('================================================');
    
    for (final country in sortedCountries) {
      final matches = groupedFixtures[country]!;
      print('');
      print('🏴 ExpansionTile: $country (${matches.length} partite)');
      print('   Titolo: "$country (${matches.length})"');
      print('   Contenuto:');
      for (final match in matches) {
        print('     • Card: ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}');
        print('       League: ${match.league}');
      }
    }
    
    print('');
    print('✅ SIMULAZIONE COMPLETATA!');
    print('   Se vedi questo output, significa che il raggruppamento funziona correttamente.');
    print('   Nell\'app Flutter dovresti vedere ${sortedCountries.length} sezioni espandibili,');
    print('   una per ogni paese: ${sortedCountries.join(", ")}');
    
    client.close();
    
  } catch (e) {
    print('❌ Errore durante la simulazione: $e');
  }
}