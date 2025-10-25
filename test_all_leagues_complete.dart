import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🌍 CHECK COMPLETO: TUTTI I CAMPIONATI');
  print('=' * 80);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    final fixtures = await liveScoreService.getFixturesToday();
    print('✅ Totale partite caricate: ${fixtures.length}\n');
    
    // Raggruppa per Campionato (League)
    Map<String, List<dynamic>> leagueGroups = {};
    Map<String, int> leagueCount = {};
    
    for (final fixture in fixtures) {
      String league = fixture.league;
      if (!leagueGroups.containsKey(league)) {
        leagueGroups[league] = [];
        leagueCount[league] = 0;
      }
      leagueGroups[league]!.add(fixture);
      leagueCount[league] = leagueCount[league]! + 1;
    }
    
    // Ordina per numero di partite (decrescente)
    List<MapEntry<String, int>> sortedLeagues = leagueCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Raggruppa anche per Paese
    Map<String, List<String>> countryLeagues = {};
    for (final fixture in fixtures) {
      String country = fixture.country;
      String league = fixture.league;
      if (!countryLeagues.containsKey(country)) {
        countryLeagues[country] = [];
      }
      if (!countryLeagues[country]!.contains(league)) {
        countryLeagues[country]!.add(league);
      }
    }
    
    print('📊 STATISTICHE:');
    print('   • Numero campionati: ${leagueCount.length}');
    print('   • Numero paesi: ${countryLeagues.length}');
    print('   • Partite per campionato: ${leagueCount.values.reduce((a, b) => a + b) ~/ leagueCount.length} (media)');
    print('');
    
    print('🏆 CAMPIONATI PRINCIPALI (Top 15):');
    print('-' * 80);
    
    int rank = 1;
    for (final entry in sortedLeagues.take(15)) {
      String league = entry.key;
      int count = entry.value;
      
      // Trova il paese per questo campionato
      String country = '';
      for (final countryEntry in countryLeagues.entries) {
        if (countryEntry.value.contains(league)) {
          country = countryEntry.key;
          break;
        }
      }
      
      print('$rank. 🏅 $league');
      print('   📍 Paese: $country');
      print('   ⚽ Partite: $count');
      
      // Mostra i match di questo campionato
      if (leagueGroups[league] != null && leagueGroups[league]!.isNotEmpty) {
        for (int i = 0; i < (leagueGroups[league]!.length <= 3 ? leagueGroups[league]!.length : 3); i++) {
          final match = leagueGroups[league]![i];
          print('      ⚽ ${match.home} vs ${match.away}');
        }
        if (leagueGroups[league]!.length > 3) {
          print('      ... e ${leagueGroups[league]!.length - 3} altre');
        }
      }
      print('');
      rank++;
    }
    
    print('\n📋 TUTTI I CAMPIONATI (${leagueCount.length} totali):');
    print('-' * 80);
    
    rank = 1;
    for (final entry in sortedLeagues) {
      String league = entry.key;
      int count = entry.value;
      
      // Trova il paese
      String country = '';
      for (final countryEntry in countryLeagues.entries) {
        if (countryEntry.value.contains(league)) {
          country = countryEntry.key;
          break;
        }
      }
      
      // Icona per i principali campionati
      String icon = '⚽';
      if (league.toLowerCase().contains('serie a') || 
          league.toLowerCase().contains('premier') ||
          league.toLowerCase().contains('la liga') ||
          league.toLowerCase().contains('ligue') ||
          league.toLowerCase().contains('bundesliga')) {
        icon = '🏆';
      }
      
      print('${rank.toString().padLeft(3)}. $icon $league ($country) - $count match');
      rank++;
    }
    
    print('\n🌍 DISTRIBUZIONE PER PAESE (${countryLeagues.length} paesi):');
    print('-' * 80);
    
    // Conta partite per paese
    Map<String, int> countryCount = {};
    for (final fixture in fixtures) {
      String country = fixture.country;
      countryCount[country] = (countryCount[country] ?? 0) + 1;
    }
    
    List<MapEntry<String, int>> sortedCountries = countryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedCountries.length; i++) {
      final entry = sortedCountries[i];
      int leaguesInCountry = countryLeagues[entry.key]?.length ?? 0;
      print('${(i+1).toString().padLeft(2)}. 🌐 ${entry.key.padRight(25)} - ${entry.value} match ($leaguesInCountry campionati)');
    }
    
    print('\n✅ CHECK COMPLETATO CORRETTAMENTE!');
    
  } catch (e, stackTrace) {
    print('❌ ERRORE: $e');
    print('Stack: $stackTrace');
    exit(1);
  }
}