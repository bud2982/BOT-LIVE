import 'lib/services/livescore_api_service.dart';

// Test per verificare che l'app funzioni con il nuovo endpoint fixtures/list.json
void main() async {
  print('🔍 TEST APP CON NUOVO ENDPOINT fixtures/list.json\n');
  print('=' * 80);
  
  final service = LiveScoreApiService();
  
  try {
    print('📡 Recupero partite di oggi...\n');
    
    final fixtures = await service.getFixturesToday();
    
    print('=' * 80);
    print('📊 RISULTATI:\n');
    print('✅ Totale partite recuperate: ${fixtures.length}\n');
    
    if (fixtures.isEmpty) {
      print('❌ ERRORE: Nessuna partita recuperata!');
      return;
    }
    
    // Analizza la qualità dei dati
    int withValidCountry = 0;
    int withValidTime = 0;
    Map<String, int> countryCounts = {};
    
    print('🏆 PRIME 10 PARTITE:\n');
    for (int i = 0; i < fixtures.length && i < 10; i++) {
      final fixture = fixtures[i];
      print('${i + 1}. ${fixture.home} vs ${fixture.away}');
      print('   Lega: ${fixture.league}');
      print('   Paese: ${fixture.country}');
      print('   Ora: ${fixture.start.hour.toString().padLeft(2, '0')}:${fixture.start.minute.toString().padLeft(2, '0')}');
      print('   Gol: ${fixture.goalsHome} - ${fixture.goalsAway}');
      if (fixture.elapsed != null) {
        print('   Minuto: ${fixture.elapsed}\'');
      }
      print('');
    }
    
    // Analizza TUTTE le partite
    print('=' * 80);
    print('📊 ANALISI COMPLETA DI TUTTE LE ${fixtures.length} PARTITE:\n');
    
    for (final fixture in fixtures) {
      // Conta paesi validi (non "International" o "Other")
      if (fixture.country != 'International' && 
          fixture.country != 'Other' && 
          fixture.country.isNotEmpty) {
        withValidCountry++;
        countryCounts[fixture.country] = (countryCounts[fixture.country] ?? 0) + 1;
      }
      
      // Conta orari validi (non mezzanotte)
      if (fixture.start.hour != 0 || fixture.start.minute != 0) {
        withValidTime++;
      }
    }
    
    print('✅ Partite con paese valido: $withValidCountry/${fixtures.length} (${(withValidCountry / fixtures.length * 100).toStringAsFixed(1)}%)');
    print('✅ Partite con orario valido: $withValidTime/${fixtures.length} (${(withValidTime / fixtures.length * 100).toStringAsFixed(1)}%)');
    
    print('\n🌍 DISTRIBUZIONE PER PAESE:');
    final sortedCountries = countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCountries) {
      print('   ${entry.key}: ${entry.value} partite');
    }
    
    print('\n' + '=' * 80);
    print('💡 CONCLUSIONE:');
    
    if (withValidCountry >= fixtures.length * 0.9 && withValidTime >= fixtures.length * 0.9) {
      print('   ✅ OTTIMO! Il nuovo endpoint fornisce dati di ALTA qualità!');
      print('   ✅ Paese: ${(withValidCountry / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ✅ Orario: ${(withValidTime / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ✅ L\'app è pronta per essere compilata e testata!');
    } else if (withValidCountry >= fixtures.length * 0.7 && withValidTime >= fixtures.length * 0.7) {
      print('   ⚠️  BUONO. Il nuovo endpoint fornisce dati di BUONA qualità.');
      print('   ⚠️  Paese: ${(withValidCountry / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ⚠️  Orario: ${(withValidTime / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ⚠️  Alcuni dati potrebbero richiedere miglioramenti.');
    } else {
      print('   ❌ ATTENZIONE. Il nuovo endpoint ha problemi con i dati.');
      print('   ❌ Paese: ${(withValidCountry / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ❌ Orario: ${(withValidTime / fixtures.length * 100).toStringAsFixed(1)}% validi');
      print('   ❌ Rivedere il parsing dei dati.');
    }
    
    print('\n⚠️  LIMITAZIONE API:');
    print('   L\'API LiveScore gratuita restituisce solo 30 partite al giorno.');
    print('   Per ottenere più partite, considera:');
    print('   1. Upgrade a piano API a pagamento');
    print('   2. Aggiungere altre fonti dati gratuite');
    print('   3. Usare il proxy server per aggregare più fonti');
    
  } catch (e, stackTrace) {
    print('❌ ERRORE: $e');
    print('Stack trace: $stackTrace');
  }
}