import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('=' * 70);
  print('🔍 CHECK COMPLETO: TUTTE LE PARTITE DEL GIORNO');
  print('=' * 70);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    // Recupera tutte le partite
    print('\n📥 Recuperando TUTTE le partite del giorno...');
    final allFixtures = await liveScoreService.getFixturesToday();
    
    print('\n✅ TOTALE PARTITE RECUPERATE: ${allFixtures.length}');
    
    // Raggruppa per paese
    final Map<String, List<dynamic>> byCountry = {};
    for (final fixture in allFixtures) {
      if (!byCountry.containsKey(fixture.country)) {
        byCountry[fixture.country] = [];
      }
      byCountry[fixture.country]!.add(fixture);
    }
    
    print('\n📍 PARTITE PER PAESE:');
    print('=' * 70);
    
    final sortedCountries = byCountry.keys.toList()..sort();
    int totalCheckBundesliga = 0;
    
    for (final country in sortedCountries) {
      final fixtures = byCountry[country]!;
      
      // Raggruppa per lega
      final Map<String, List<dynamic>> byLeague = {};
      for (final fixture in fixtures) {
        if (!byLeague.containsKey(fixture.league)) {
          byLeague[fixture.league] = [];
        }
        byLeague[fixture.league]!.add(fixture);
      }
      
      print('\n🌍 ${country.toUpperCase()} - Totale: ${fixtures.length} partite');
      
      for (final league in byLeague.keys) {
        final leagueFixtures = byLeague[league]!;
        print('   📊 $league: ${leagueFixtures.length} partite');
        
        // Se è Bundesliga, mostra i dettagli
        if (league.toLowerCase().contains('bundesliga')) {
          totalCheckBundesliga = leagueFixtures.length;
          print('      Teams (Bundesliga):');
          for (final match in leagueFixtures) {
            print('         ${match.home} vs ${match.away} (Score: ${match.goalsHome}-${match.goalsAway})');
          }
        }
      }
    }
    
    print('\n' + '=' * 70);
    print('📊 STATISTICHE FINALI:');
    print('=' * 70);
    print('Paesi trovati: ${byCountry.length}');
    print('Partite totali: ${allFixtures.length}');
    print('Bundesliga trovate: $totalCheckBundesliga');
    
    // Analisi partite per verificare se ci sono duplicati
    print('\n🔎 RICERCA DUPLICATI:');
    final Set<int> ids = {};
    int duplicates = 0;
    for (final fixture in allFixtures) {
      if (ids.contains(fixture.id)) {
        duplicates++;
        print('   ⚠️  DUPLICATO: ${fixture.home} vs ${fixture.away} (ID: ${fixture.id})');
      }
      ids.add(fixture.id);
    }
    print('Duplicati trovati: $duplicates');
    
    // Verifica la paginazione
    print('\n📄 VERIFICA PAGINAZIONE:');
    print('Se il numero di partite totali è esattamente 150 (5 pagine × 30),');
    print('potrebbe significare che la paginazione si ferma prima di tempo.');
    print('Totale partite recuperate: ${allFixtures.length}');
    if (allFixtures.length >= 150) {
      print('⚠️  ATTENZIONE: Potrebbe esserci un problema di paginazione!');
    }
    
    print('\n✅ TEST COMPLETATO');
    print('=' * 70);
    
  } catch (e) {
    print('❌ ERRORE: $e');
    print('Stack trace:');
    print(StackTrace.current);
    exit(1);
  }
}