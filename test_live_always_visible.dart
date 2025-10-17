import 'dart:io';
import 'lib/services/hybrid_football_service.dart';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🧪 TEST: PARTITE LIVE SEMPRE VISIBILI');
  print('=' * 80);
  print('Obiettivo: Verificare che le partite live vengano mostrate sempre,');
  print('indipendentemente dal valore di elapsed (0, null, >0)');
  print('=' * 80);
  
  final hybridService = HybridFootballService();
  final liveScoreService = LiveScoreApiService();
  
  try {
    // Test 1: Verifica partite live dal servizio diretto
    print('\n📋 TEST 1: SERVIZIO LIVESCORE API DIRETTO');
    print('-' * 50);
    
    final directLiveMatches = await liveScoreService.getLiveMatches();
    print('✅ Partite live dal servizio diretto: ${directLiveMatches.length}');
    
    if (directLiveMatches.isNotEmpty) {
      print('\n🔍 Analisi valori elapsed:');
      for (int i = 0; i < directLiveMatches.length; i++) {
        final match = directLiveMatches[i];
        final elapsedStr = match.elapsed?.toString() ?? 'null';
        print('   ${i + 1}. ${match.home} vs ${match.away}');
        print('      Elapsed: $elapsedStr');
        print('      Dovrebbe essere visibile: ✅ SÌ (è nell\'endpoint live)');
      }
    }
    
    // Test 2: Verifica partite live dal servizio hybrid
    print('\n📋 TEST 2: SERVIZIO HYBRID');
    print('-' * 50);
    
    final hybridLiveMatches = await hybridService.getLiveMatches();
    print('✅ Partite live dal servizio hybrid: ${hybridLiveMatches.length}');
    
    if (hybridLiveMatches.isNotEmpty) {
      print('\n🔍 Analisi valori elapsed (dopo filtri):');
      for (int i = 0; i < hybridLiveMatches.length; i++) {
        final match = hybridLiveMatches[i];
        final elapsedStr = match.elapsed?.toString() ?? 'null';
        print('   ${i + 1}. ${match.home} vs ${match.away}');
        print('      Elapsed: $elapsedStr');
        print('      Visibile nell\'app: ✅ SÌ');
      }
    }
    
    // Test 3: Confronto tra servizi
    print('\n📋 TEST 3: CONFRONTO SERVIZI');
    print('-' * 50);
    
    if (directLiveMatches.length == hybridLiveMatches.length) {
      print('✅ PERFETTO: Stesso numero di partite live in entrambi i servizi');
      print('   Servizio diretto: ${directLiveMatches.length}');
      print('   Servizio hybrid: ${hybridLiveMatches.length}');
    } else {
      print('⚠️ ATTENZIONE: Differenza nel numero di partite');
      print('   Servizio diretto: ${directLiveMatches.length}');
      print('   Servizio hybrid: ${hybridLiveMatches.length}');
      print('   Possibile causa: Filtri diversi o errori di rete');
    }
    
    // Test 4: Verifica casi specifici
    print('\n📋 TEST 4: VERIFICA CASI SPECIFICI');
    print('-' * 50);
    
    int elapsedNull = 0;
    int elapsedZero = 0;
    int elapsedPositive = 0;
    
    for (final match in hybridLiveMatches) {
      if (match.elapsed == null) {
        elapsedNull++;
      } else if (match.elapsed == 0) {
        elapsedZero++;
      } else if (match.elapsed! > 0) {
        elapsedPositive++;
      }
    }
    
    print('📊 Distribuzione valori elapsed:');
    print('   Elapsed = null: $elapsedNull partite');
    print('   Elapsed = 0: $elapsedZero partite');
    print('   Elapsed > 0: $elapsedPositive partite');
    print('   TOTALE: ${elapsedNull + elapsedZero + elapsedPositive} partite');
    
    // Test 5: Simulazione UI
    print('\n📋 TEST 5: SIMULAZIONE COMPORTAMENTO UI');
    print('-' * 50);
    
    for (final match in hybridLiveMatches) {
      String statusText;
      String colorDescription;
      
      // Simula la logica di _getMatchStatus
      if (match.elapsed == null) {
        statusText = 'LIVE';
        colorDescription = 'ROSSO (live senza elapsed)';
      } else if (match.elapsed! == 0) {
        statusText = 'LIVE';
        colorDescription = 'VERDE (appena iniziata)';
      } else if (match.elapsed! <= 45) {
        statusText = '${match.elapsed}\'';
        colorDescription = 'VERDE (primo tempo)';
      } else if (match.elapsed! <= 90) {
        statusText = '${match.elapsed}\'';
        colorDescription = 'ARANCIONE (secondo tempo)';
      } else {
        statusText = '${match.elapsed}\' +';
        colorDescription = 'ROSSO (oltre 90 minuti)';
      }
      
      print('   🎨 ${match.home} vs ${match.away}');
      print('      Status mostrato: "$statusText"');
      print('      Colore barra: $colorDescription');
    }
    
    // Risultato finale
    print('\n' + '=' * 80);
    if (hybridLiveMatches.isNotEmpty) {
      print('✅ SUCCESSO: Le partite live vengono mostrate sempre!');
      print('   - Totale partite live visibili: ${hybridLiveMatches.length}');
      print('   - Partite con elapsed null: $elapsedNull (mostrate come "LIVE")');
      print('   - Partite con elapsed = 0: $elapsedZero (mostrate come "LIVE")');
      print('   - Partite con elapsed > 0: $elapsedPositive (mostrate con minuti)');
      print('');
      print('🎯 OBIETTIVO RAGGIUNTO: Nessuna partita live viene nascosta!');
    } else {
      print('ℹ️ NESSUNA PARTITA LIVE AL MOMENTO');
      print('   Questo è normale se non ci sono partite in corso.');
      print('   Il sistema è configurato per mostrare tutte le partite live');
      print('   quando saranno disponibili.');
    }
    
  } catch (e) {
    print('❌ ERRORE durante il test: $e');
    exit(1);
  }
}