import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔍 TEST CORREZIONI LIVE');
  print('=' * 80);
  
  final service = LiveScoreApiService();
  
  // Test 1: Partite di oggi
  print('\n📋 TEST 1: PARTITE DI OGGI');
  print('-' * 80);
  try {
    final fixtures = await service.getFixturesToday();
    print('✅ Recuperate ${fixtures.length} partite di oggi');
    
    // Conta partite con elapsed
    final withElapsed = fixtures.where((f) => f.elapsed != null).length;
    print('   Partite con elapsed: $withElapsed');
    
    // Mostra prime 5
    print('\n   Prime 5 partite:');
    for (int i = 0; i < (fixtures.length > 5 ? 5 : fixtures.length); i++) {
      final f = fixtures[i];
      print('   ${i + 1}. ${f.home} vs ${f.away}');
      print('      Score: ${f.goalsHome}-${f.goalsAway}');
      print('      Elapsed: ${f.elapsed ?? "N/A"}');
      print('      Country: ${f.country}');
      print('      League: ${f.league}');
      print('      Start: ${f.start.hour}:${f.start.minute.toString().padLeft(2, '0')}');
      print('');
    }
  } catch (e) {
    print('❌ Errore: $e');
  }
  
  // Test 2: Partite live
  print('\n🔴 TEST 2: PARTITE LIVE');
  print('-' * 80);
  try {
    final liveMatches = await service.getLiveMatches();
    print('✅ Recuperate ${liveMatches.length} partite live');
    
    if (liveMatches.isEmpty) {
      print('   ℹ️ Nessuna partita live al momento');
    } else {
      print('\n   Tutte le partite live:');
      for (int i = 0; i < liveMatches.length; i++) {
        final f = liveMatches[i];
        print('   ${i + 1}. ${f.home} ${f.goalsHome}-${f.goalsAway} ${f.away}');
        print('      🔴 LIVE: ${f.elapsed}\' minuto');
        print('      Country: ${f.country}');
        print('      League: ${f.league}');
        print('');
      }
    }
  } catch (e) {
    print('❌ Errore: $e');
  }
  
  print('=' * 80);
  print('✅ TEST COMPLETATO');
}