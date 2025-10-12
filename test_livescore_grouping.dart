// Script per testare il raggruppamento per paese con LiveScore API
import 'lib/services/livescore_api_service.dart';

Future<void> main() async {
  print('🧪 TEST RAGGRUPPAMENTO PER PAESE - LiveScore API');
  print('=' * 60);
  print('');
  
  final service = LiveScoreApiService();
  
  // Test connessione
  print('1️⃣ Test connessione API...');
  final isConnected = await service.testConnection();
  if (!isConnected) {
    print('   ❌ Connessione fallita - Verifica la chiave API');
    return;
  }
  print('   ✅ Connessione riuscita');
  print('');
  
  // Recupera partite
  print('2️⃣ Recupero partite del giorno...');
  try {
    final fixtures = await service.getFixturesToday();
    print('   ✅ Recuperate ${fixtures.length} partite');
    print('');
    
    if (fixtures.isEmpty) {
      print('   ⚠️ Nessuna partita trovata per oggi');
      return;
    }
    
    // Raggruppa per paese
    print('3️⃣ Raggruppamento per paese...');
    final Map<String, int> countryGroups = {};
    
    for (final fixture in fixtures) {
      final country = fixture.country;
      countryGroups[country] = (countryGroups[country] ?? 0) + 1;
      
      print('   🏟️ ${fixture.home} vs ${fixture.away}');
      print('      League: ${fixture.league}');
      print('      Country: $country');
      print('');
    }
    
    // Mostra riepilogo
    print('4️⃣ Riepilogo raggruppamento:');
    print('   Totale paesi: ${countryGroups.length}');
    print('');
    
    final sortedCountries = countryGroups.keys.toList()..sort((a, b) {
      if (a == 'International') return 1;
      if (b == 'International') return -1;
      return a.compareTo(b);
    });
    
    for (final country in sortedCountries) {
      final count = countryGroups[country]!;
      print('   🌍 $country: $count partite');
    }
    
    print('');
    print('✅ Test completato con successo!');
    
  } catch (e) {
    print('   ❌ Errore: $e');
    print('');
    print('💡 Suggerimenti:');
    print('   - Verifica che la chiave API sia corretta');
    print('   - Controlla la connessione internet');
    print('   - Verifica i log sopra per dettagli sul parsing');
  }
}