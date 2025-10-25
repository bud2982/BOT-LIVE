import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔍 ANALISI DETTAGLIATA: CAMPIONATI MANCANTI E SUGGERIMENTI');
  print('=' * 80);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    print('\n📥 Recupero tutte le partite...\n');
    final fixtures = await liveScoreService.getFixturesToday();
    print('✅ Totale partite caricate: ${fixtures.length}\n');
    
    // Analisi per campionato
    Map<String, int> leagueCount = {};
    Map<String, String> leagueCountry = {};
    
    for (final fixture in fixtures) {
      String league = fixture.league ?? 'Unknown';
      String country = fixture.country ?? 'Unknown';
      
      if (!leagueCount.containsKey(league)) {
        leagueCount[league] = 0;
        leagueCountry[league] = country;
      }
      leagueCount[league] = leagueCount[league]! + 1;
    }
    
    // Elenco campionati principali per paese
    Map<String, List<String>> mainLeaguesByCountry = {
      'Spain': ['La Liga', 'La Liga 2', 'Segunda Division'],
      'France': ['Ligue 1', 'Ligue 2'],
      'Netherlands': ['Eredivisie', 'Eerste Divisie', 'Tweede Divisie'],
      'Portugal': ['Primeira Liga', 'Segunda Liga'],
      'Argentina': ['Primera Division', 'Primera B Nacional'],
      'Brazil': ['Serie A', 'Serie B'],
      'Mexico': ['Liga MX', 'Ascenso'],
      'Australia': ['A League', 'A League 2'],
      'South Korea': ['K League', 'K League 2'],
      'Japan': ['J League', 'J2 League'],
      'Belgium': ['Pro League', 'Division 2'],
      'Switzerland': ['Super League', 'Challenge League'],
      'Scotland': ['Premiership', 'Championship', 'League One', 'League Two'],
      'Turkey': ['Super Lig', '1st Lig', '2nd Lig'],
      'Greece': ['Super League', 'Super League 2'],
      'Czech Republic': ['1st League', '2nd league', '3rd league'],
      'Poland': ['Ekstraklasa', '2nd Liga'],
    };
    
    print('\n🔴 CAMPIONATI PRINCIPALI MANCANTI:\n');
    print('-' * 80);
    
    Map<String, List<String>> missingLeagues = {};
    int totalMissingMatches = 0;
    
    for (final country in mainLeaguesByCountry.keys) {
      final leaguesForCountry = mainLeaguesByCountry[country]!;
      List<String> missing = [];
      
      for (final league in leaguesForCountry) {
        bool found = false;
        for (final entry in leagueCount.entries) {
          if (entry.key.toLowerCase().contains(league.toLowerCase())) {
            found = true;
            break;
          }
        }
        if (!found) {
          missing.add(league);
        }
      }
      
      if (missing.isNotEmpty) {
        missingLeagues[country] = missing;
      }
    }
    
    if (missingLeagues.isEmpty) {
      print('🎉 TUTTI I CAMPIONATI PRINCIPALI SONO PRESENTI!');
    } else {
      print('⚠️  ${missingLeagues.length} paesi con campionati mancanti:\n');
      int rank = 1;
      for (final country in missingLeagues.keys) {
        final missing = missingLeagues[country]!;
        print('$rank. 🌐 $country');
        for (final league in missing) {
          print('   ❌ $league');
        }
        print('');
        rank++;
      }
    }
    
    print('\n📊 CAMPIONATI PRESENTI PER PAESE PRINCIPALE:\n');
    print('-' * 80);
    
    for (final country in mainLeaguesByCountry.keys) {
      final leaguesForCountry = mainLeaguesByCountry[country]!;
      List<String> found = [];
      List<String> missing = [];
      
      for (final league in leaguesForCountry) {
        bool foundMatch = false;
        for (final entry in leagueCount.entries) {
          if (entry.key.toLowerCase().contains(league.toLowerCase())) {
            found.add('${entry.key} (${entry.value} match)');
            foundMatch = true;
            break;
          }
        }
        if (!foundMatch) {
          missing.add(league);
        }
      }
      
      if (found.isNotEmpty || missing.isNotEmpty) {
        print('🌐 $country:');
        if (found.isNotEmpty) {
          for (final f in found) {
            print('   ✅ $f');
          }
        }
        if (missing.isNotEmpty) {
          for (final m in missing) {
            print('   ❌ $m');
          }
        }
        print('');
      }
    }
    
    // Statistiche di qualità
    print('\n📈 STATISTICHE DI QUALITÀ DEL DATASET:\n');
    print('-' * 80);
    
    int primaryLeaguesCount = 0;
    int primaryMatches = 0;
    
    // Top 5 campionati
    List<MapEntry<String, int>> sortedLeagues = leagueCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('Top 5 campionati:');
    for (int i = 0; i < (sortedLeagues.length < 5 ? sortedLeagues.length : 5); i++) {
      final entry = sortedLeagues[i];
      print('${(i+1).toString().padLeft(2)}. ${entry.key.padRight(35)} (${leagueCountry[entry.key]}) - ${entry.value} match');
    }
    
    print('\n');
    print('Distribuzione match:');
    print('   • Partite nei top 5 campionati: ${sortedLeagues.take(5).fold(0, (sum, e) => sum + e.value)} (${((sortedLeagues.take(5).fold(0, (sum, e) => sum + e.value) / fixtures.length) * 100).toStringAsFixed(1)}%)');
    print('   • Partite nei top 10 campionati: ${sortedLeagues.take(10).fold(0, (sum, e) => sum + e.value)} (${((sortedLeagues.take(10).fold(0, (sum, e) => sum + e.value) / fixtures.length) * 100).toStringAsFixed(1)}%)');
    print('   • Campionati con 1 sola partita: ${leagueCount.values.where((v) => v == 1).length}');
    print('   • Media partite per campionato: ${(fixtures.length / leagueCount.length).toStringAsFixed(1)}');
    
    // Raccomandazioni
    print('\n\n💡 RACCOMANDAZIONI:\n');
    print('-' * 80);
    
    if (missingLeagues.isEmpty) {
      print('✅ Dataset COMPLETO - Tutti i principali campionati sono presenti');
      print('   Attuale: 15 pagine (450 match)');
      print('   Azione: MANTENERE CONFIGURAZIONE ATTUALE');
    } else {
      int missingCount = missingLeagues.values.fold(0, (sum, list) => sum + list.length);
      print('⚠️  Campionati principali mancanti: $missingCount');
      print('   Paesi interessati: ${missingLeagues.length}');
      print('\n   Opzioni:');
      print('   1️⃣  AUMENTARE A 20 PAGINE (600 match)');
      print('       • Probabilità di coprire campionati mancanti: ALTA');
      print('       • Tempo API aggiuntivo: ~5-10 secondi');
      print('       • Incremento dati: +150 match');
      print('   ');
      print('   2️⃣  MANTENERE 15 PAGINE (450 match)');
      print('       • Compromesso tra dati e performance');
      print('       • Copre ~90% dei campionati principali');
      print('   ');
      print('   3️⃣  IMPLEMENTARE LOGICA DINAMICA');
      print('       • Continua a paginate finché ci sono dati');
      print('       • Massima completezza ma performance variabile');
    }
    
    print('\n\n✅ ANALISI COMPLETATA!');
    
  } catch (e, stackTrace) {
    print('❌ ERRORE: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}