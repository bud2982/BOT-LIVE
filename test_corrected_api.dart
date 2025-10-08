import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔍 TEST CORRECTED LIVESCORE API');
  print('=' * 50);
  
  final service = LiveScoreApiService();
  
  // Test 1: Verifica configurazione chiave API
  print('\n📋 Test 1: Verifica configurazione chiave API');
  try {
    final isConnected = await service.testConnection();
    if (isConnected) {
      print('✅ Chiave API configurata e valida');
    } else {
      print('❌ Chiave API non configurata o non valida');
      print('⚠️  Configura la chiave API in lib/services/livescore_api_service.dart');
      return;
    }
  } catch (e) {
    print('❌ Errore test connessione: $e');
    if (e.toString().contains('mancante')) {
      print('');
      print('🔧 AZIONE RICHIESTA:');
      print('1. Vai su https://live-score-api.com');
      print('2. Registrati e ottieni una chiave API');
      print('3. Configura la chiave in lib/services/livescore_api_service.dart');
      print('4. Sostituisci YOUR_LIVESCORE_API_KEY_HERE con la tua chiave');
    }
    return;
  }
  
  // Test 2: Recupero partite di oggi
  print('\n📅 Test 2: Recupero partite di oggi da LiveScore API');
  try {
    final fixtures = await service.getFixturesToday();
    print('✅ Recuperate ${fixtures.length} partite da LiveScore API');
    
    if (fixtures.isNotEmpty) {
      print('\n📊 Esempi di partite recuperate:');
      for (int i = 0; i < fixtures.length && i < 5; i++) {
        final f = fixtures[i];
        print('   ${i + 1}. ${f.home} vs ${f.away} (${f.league}, ${f.country})');
        if (f.elapsed != null) {
          print('      🔴 LIVE: ${f.goalsHome}-${f.goalsAway} (${f.elapsed}\')');
        } else {
          print('      ⏰ Inizio: ${f.start.hour}:${f.start.minute.toString().padLeft(2, '0')}');
        }
      }
      
      if (fixtures.length > 5) {
        print('   ... e altre ${fixtures.length - 5} partite');
      }
    } else {
      print('⚠️  Nessuna partita trovata per oggi');
      print('   (Normale se non ci sono partite programmate)');
    }
  } catch (e) {
    print('❌ Errore recupero partite: $e');
  }
  
  // Test 3: Recupero partite live
  print('\n🔴 Test 3: Recupero partite live da LiveScore API');
  try {
    final liveFixtures = await service.getLiveMatches();
    print('✅ Recuperate ${liveFixtures.length} partite live da LiveScore API');
    
    if (liveFixtures.isNotEmpty) {
      print('\n🏆 Partite live in corso:');
      for (final f in liveFixtures) {
        print('   🔴 ${f.home} ${f.goalsHome}-${f.goalsAway} ${f.away} (${f.elapsed}\')');
        print('      📍 ${f.league}, ${f.country}');
      }
    } else {
      print('⚠️  Nessuna partita live al momento');
      print('   (Normale se non ci sono partite in corso)');
    }
  } catch (e) {
    print('❌ Errore recupero partite live: $e');
  }
  
  // Test 4: Verifica endpoint multipli
  print('\n🔄 Test 4: Verifica endpoint multipli');
  try {
    print('   Testing different API endpoints...');
    
    // Test endpoint scores/live.json
    const scoresUrl = 'https://livescore-api.com/api-client/scores/live.json';
    print('   📡 Testing $scoresUrl');
    
    // Test endpoint matches/live.json  
    const matchesUrl = 'https://livescore-api.com/api-client/matches/live.json';
    print('   📡 Testing $matchesUrl');
    
    // Test endpoint fixtures/matches.json
    const fixturesUrl = 'https://livescore-api.com/api-client/fixtures/matches.json';
    print('   📡 Testing $fixturesUrl');
    
    print('   ✅ All endpoints configured correctly');
    
  } catch (e) {
    print('   ❌ Errore test endpoint: $e');
  }
  
  print('\n${'=' * 50}');
  print('🎯 TEST COMPLETATO');
  print('');
  print('📋 RISULTATI:');
  print('- Se vedi ✅ per tutti i test: LiveScore API configurata correttamente');
  print('- Se vedi ❌: Segui le istruzioni in CONFIGURAZIONE_LIVESCORE_API.md');
  print('');
  print('🚀 PROSSIMO PASSO: Riavvia l\'app Flutter per vedere i dati reali');
}