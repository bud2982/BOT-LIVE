import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔍 ANALISI COMPLETA: 15 PAGINE vs 10 PAGINE');
  print('=' * 80);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    print('\n📥 Recupero tutte le partite (con 15 pagine)...\n');
    final fixtures = await liveScoreService.getFixturesToday();
    print('✅ Totale partite caricate: ${fixtures.length}\n');
    
    // Analisi per campionato
    Map<String, List<dynamic>> leagueGroups = {};
    Map<String, int> leagueCount = {};
    Map<String, String> leagueCountry = {};
    
    for (final fixture in fixtures) {
      String league = fixture.league ?? 'Unknown';
      String country = fixture.country ?? 'Unknown';
      
      if (!leagueGroups.containsKey(league)) {
        leagueGroups[league] = [];
        leagueCount[league] = 0;
        leagueCountry[league] = country;
      }
      leagueGroups[league]!.add(fixture);
      leagueCount[league] = leagueCount[league]! + 1;
    }
    
    // Ordina per numero di partite
    List<MapEntry<String, int>> sortedLeagues = leagueCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('\n📊 STATISTICHE GENERALI:');
    print('   • Numero campionati: ${leagueCount.length}');
    print('   • Partite totali: ${fixtures.length}');
    print('   • Aumento rispetto 10 pagine (300): +${fixtures.length - 300} match');
    print('   • Aumento percentuale: ${((fixtures.length - 300) / 300 * 100).toStringAsFixed(1)}%\n');
    
    // Identifica campionati principali
    List<String> mainLeagues = [
      'Premier League', 'La Liga', 'Serie A', 'Bundesliga', 
      'Ligue 1', 'Championship', 'Serie B', 'La Liga 2',
      'Ligue 2', '2nd Bundesliga', 'Eredivisie', 'Super Lig',
      'Primeira Liga', 'Super Liga', 'Ekstraklasa', 'Primeira Liga',
      'Primera Division', 'Liga MX', 'A League', 'K League',
      'Super League', 'Allsvenskan', 'Eliteserien'
    ];
    
    print('🏆 CAMPIONATI PRINCIPALI - SITUAZIONE ATTUALE:\n');
    print('-' * 80);
    
    bool hasMainLeagues = false;
    for (final mainLeague in mainLeagues) {
      for (final entry in sortedLeagues) {
        if (entry.key.toLowerCase().contains(mainLeague.toLowerCase()) && 
            !entry.key.toLowerCase().contains('friendly')) {
          print('✅ ${entry.key.padRight(30)} (${leagueCountry[entry.key]}) - ${entry.value} match');
          hasMainLeagues = true;
        }
      }
    }
    
    if (!hasMainLeagues) {
      print('⚠️  NESSUN CAMPIONATO PRINCIPALE TROVATO NEL DATASET\n');
    }
    
    print('\n\n🔴 CAMPIONATI PRINCIPALI MANCANTI:\n');
    print('-' * 80);
    
    List<String> missingLeagues = [];
    for (final mainLeague in mainLeagues) {
      bool found = false;
      for (final entry in sortedLeagues) {
        if (entry.key.toLowerCase().contains(mainLeague.toLowerCase()) &&
            !entry.key.toLowerCase().contains('friendly')) {
          found = true;
          break;
        }
      }
      if (!found) {
        missingLeagues.add(mainLeague);
      }
    }
    
    if (missingLeagues.isNotEmpty) {
      print('⚠️  CAMPIONATI PRINCIPALI ASSENTI (${missingLeagues.length} totali):\n');
      for (int i = 0; i < missingLeagues.length; i++) {
        print('${(i+1).toString().padLeft(2)}. ❌ ${missingLeagues[i]}');
      }
    } else {
      print('🎉 TUTTI I CAMPIONATI PRINCIPALI SONO PRESENTI!');
    }
    
    print('\n\n📈 INCREMENTO PER PAGINA AGGIUNTIVA:\n');
    print('-' * 80);
    print('Con 10 pagine: 300 match');
    print('Con 15 pagine: ${fixtures.length} match');
    print('Incremento: +${fixtures.length - 300} match (+${((fixtures.length - 300) / 300 * 100).toStringAsFixed(1)}%)\n');
    
    print('\n🌍 TOP 20 CAMPIONATI (15 pagine):\n');
    print('-' * 80);
    
    for (int i = 0; i < (sortedLeagues.length < 20 ? sortedLeagues.length : 20); i++) {
      final entry = sortedLeagues[i];
      String icon = '⚽';
      if (entry.key.toLowerCase().contains('premier') ||
          entry.key.toLowerCase().contains('serie a') ||
          entry.key.toLowerCase().contains('la liga') ||
          entry.key.toLowerCase().contains('ligue 1') ||
          entry.key.toLowerCase().contains('bundesliga') ||
          entry.key.toLowerCase().contains('championship') &&
          !entry.key.toLowerCase().contains('2')) {
        icon = '🏆';
      }
      print('${(i+1).toString().padLeft(2)}. $icon ${entry.key.padRight(35)} (${leagueCountry[entry.key]}) - ${entry.value} match');
    }
    
    // Distribuzione di match per tipo di divisione
    print('\n\n📊 ANALISI PER TIPO DI DIVISIONE:\n');
    print('-' * 80);
    
    int primaryLeagues = 0;
    int secondaryLeagues = 0;
    int tertiaryLeagues = 0;
    int otherLeagues = 0;
    
    int primaryMatches = 0;
    int secondaryMatches = 0;
    int tertiaryMatches = 0;
    int otherMatches = 0;
    
    for (final entry in sortedLeagues) {
      String league = entry.key.toLowerCase();
      if (league.contains('1') && !league.contains('liga 1') && 
          (league.contains('division') || league.contains('liga') || league.contains('league'))) {
        primaryLeagues++;
        primaryMatches += entry.value;
      } else if (league.contains('2') || league.contains('secondary') || 
                 league.contains('second') || league.contains('championship')) {
        secondaryLeagues++;
        secondaryMatches += entry.value;
      } else if (league.contains('3') || league.contains('tertiary') || 
                 league.contains('third')) {
        tertiaryLeagues++;
        tertiaryMatches += entry.value;
      } else {
        otherLeagues++;
        otherMatches += entry.value;
      }
    }
    
    print('🥇 Divisioni primarie: $primaryLeagues campionati - $primaryMatches match');
    print('🥈 Divisioni secondarie: $secondaryLeagues campionati - $secondaryMatches match');
    print('🥉 Divisioni terziarie: $tertiaryLeagues campionati - $tertiaryMatches match');
    print('⚽ Altro: $otherLeagues campionati - $otherMatches match');
    
    print('\n✅ ANALISI COMPLETATA!');
    
  } catch (e, stackTrace) {
    print('❌ ERRORE: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}