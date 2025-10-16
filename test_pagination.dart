import 'lib/services/livescore_api_service.dart';

/// Test per verificare che la paginazione recuperi più di 30 partite
void main() async {
  print('🔍 TEST PAGINAZIONE API LIVESCORE');
  print('=' * 60);
  
  final service = LiveScoreApiService();
  
  try {
    print('\n📋 Recupero partite di oggi con paginazione...\n');
    
    final fixtures = await service.getFixturesToday();
    
    print('\n' + '=' * 60);
    print('✅ RISULTATO FINALE');
    print('=' * 60);
    print('📊 Totale partite recuperate: ${fixtures.length}');
    
    if (fixtures.length > 30) {
      print('✅ SUCCESSO! Recuperate più di 30 partite grazie alla paginazione!');
    } else if (fixtures.length == 30) {
      print('⚠️ Recuperate esattamente 30 partite. Potrebbero esserci più pagine disponibili.');
    } else {
      print('ℹ️ Recuperate ${fixtures.length} partite (meno di 30, probabilmente tutte le disponibili oggi)');
    }
    
    // Analizza le partite per paese
    final Map<String, int> countryCounts = {};
    for (final fixture in fixtures) {
      final country = fixture.country.isNotEmpty ? fixture.country : 'Unknown';
      countryCounts[country] = (countryCounts[country] ?? 0) + 1;
    }
    
    print('\n📊 DISTRIBUZIONE PER PAESE (Top 15):');
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (int i = 0; i < (sortedCountries.length > 15 ? 15 : sortedCountries.length); i++) {
      final entry = sortedCountries[i];
      print('   ${i + 1}. ${entry.key}: ${entry.value} partite');
    }
    
    // Cerca partite internazionali
    final internationalFixtures = fixtures.where((fixture) {
      final league = fixture.league.toLowerCase();
      return league.contains('champions') || 
             league.contains('europa') || 
             league.contains('world') ||
             league.contains('uefa') ||
             league.contains('fifa') ||
             league.contains('international');
    }).toList();
    
    if (internationalFixtures.isNotEmpty) {
      print('\n🌍 PARTITE INTERNAZIONALI TROVATE: ${internationalFixtures.length}');
      for (final fixture in internationalFixtures.take(10)) {
        print('   - ${fixture.home} vs ${fixture.away}');
        print('     ${fixture.league} (${fixture.country})');
      }
    } else {
      print('\n⚠️ NESSUNA PARTITA INTERNAZIONALE OGGI');
      print('   (Champions League e Europa League non si giocano tutti i giorni)');
    }
    
    // Mostra alcune partite di esempio
    print('\n📝 ESEMPI DI PARTITE (prime 10):');
    for (int i = 0; i < (fixtures.length > 10 ? 10 : fixtures.length); i++) {
      final fixture = fixtures[i];
      final timeStr = '${fixture.start.hour.toString().padLeft(2, '0')}:${fixture.start.minute.toString().padLeft(2, '0')}';
      print('   ${i + 1}. ${fixture.home} vs ${fixture.away}');
      print('      ${fixture.league} (${fixture.country})');
      print('      Orario: $timeStr');
    }
    
    print('\n' + '=' * 60);
    print('✅ TEST COMPLETATO CON SUCCESSO');
    print('=' * 60);
    
  } catch (e) {
    print('\n❌ ERRORE: $e');
    print('\nStack trace:');
    print(e);
  }
}