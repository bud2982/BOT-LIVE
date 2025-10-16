import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🧪 TEST: Recupero partite da LiveScore API diretta\n');
  
  final service = LiveScoreApiService();
  
  try {
    print('📡 Chiamata a LiveScore API...');
    final fixtures = await service.getFixturesToday();
    
    print('\n✅ SUCCESSO!');
    print('📊 Totale partite recuperate: ${fixtures.length}');
    
    if (fixtures.isEmpty) {
      print('⚠️ ATTENZIONE: Nessuna partita trovata!');
      return;
    }
    
    // Raggruppa per paese
    final Map<String, int> byCountry = {};
    for (final fixture in fixtures) {
      byCountry[fixture.country] = (byCountry[fixture.country] ?? 0) + 1;
    }
    
    print('\n🌍 Partite per paese:');
    final sortedCountries = byCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCountries) {
      print('   ${entry.key}: ${entry.value} partite');
    }
    
    print('\n📋 Prime 5 partite:');
    for (int i = 0; i < fixtures.length && i < 5; i++) {
      final f = fixtures[i];
      final liveStatus = f.elapsed != null ? ' [LIVE ${f.elapsed}\']' : '';
      print('   ${i + 1}. ${f.home} vs ${f.away} (${f.country})$liveStatus');
      print('      Punteggio: ${f.goalsHome}-${f.goalsAway}');
      print('      Lega: ${f.league}');
      print('      Orario: ${f.start}');
    }
    
  } catch (e) {
    print('\n❌ ERRORE: $e');
    print('\n💡 Possibili cause:');
    print('   1. Chiave API non valida o scaduta');
    print('   2. Limite richieste API superato');
    print('   3. Problema di connessione internet');
    print('   4. Endpoint API non disponibile');
  }
}