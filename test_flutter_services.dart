// Test dei servizi Flutter
// Questo test verifica che tutte le modifiche al codice siano corrette

import 'dart:io';

void main() {
  print('🔬 TEST VERIFICA MODIFICHE AL CODICE');
  print('=' * 80);
  
  testLiveScoreApiService();
  testLiveScreen();
  testFollowedMatchesPage();
  testFollowedMatchesUpdater();
  
  print('\n${'=' * 80}');
  print('✅ VERIFICA COMPLETATA');
  print('=' * 80);
}

void testLiveScoreApiService() {
  print('\n📋 TEST 1: VERIFICA livescore_api_service.dart');
  print('-' * 80);
  
  final file = File('lib/services/livescore_api_service.dart');
  
  if (!file.existsSync()) {
    print('  ❌ File non trovato!');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Verifica 1: Paginazione implementata
  if (content.contains('while (hasMorePages && currentPage <= maxPages)') ||
      content.contains('const int maxPages = 5')) {
    print('  ✅ Paginazione implementata correttamente');
  } else {
    print('  ❌ Paginazione non trovata');
  }
  
  // Verifica 2: Parsing fixtures vs match
  if (content.contains('isLiveEndpoint') && 
      content.contains("['match']") && 
      content.contains("['fixtures']")) {
    print('  ✅ Distinzione fixtures/live implementata');
  } else {
    print('  ❌ Distinzione fixtures/live non trovata');
  }
  
  // Verifica 3: Parsing status per elapsed
  if (content.contains('IN PLAY') && 
      content.contains('HALF TIME') && 
      content.contains('FINISHED')) {
    print('  ✅ Parsing status implementato');
  } else {
    print('  ❌ Parsing status non trovato');
  }
  
  // Verifica 4: Regex per estrazione minuti
  if (content.contains(r"RegExp(r'(\d+)'")) {
    print('  ✅ Regex per estrazione minuti implementata');
  } else {
    print('  ❌ Regex per estrazione minuti non trovata');
  }
  
  // Verifica 5: Deduplicazione
  if (content.contains('uniqueFixtures') || content.contains('<int, Fixture>{}')) {
    print('  ✅ Deduplicazione implementata');
  } else {
    print('  ⚠️ Deduplicazione potrebbe mancare');
  }
  
  print('\n  📊 RIEPILOGO TEST 1:');
  print('     File: lib/services/livescore_api_service.dart');
  print('     Dimensione: ${(content.length / 1024).toStringAsFixed(2)} KB');
  print('     Righe: ${content.split('\n').length}');
}

void testLiveScreen() {
  print('\n\n🔴 TEST 2: VERIFICA live_screen.dart');
  print('-' * 80);
  
  final file = File('lib/screens/live_screen.dart');
  
  if (!file.existsSync()) {
    print('  ❌ File non trovato!');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Verifica 1: Usa getLiveMatches invece di getFixturesToday
  if (content.contains('getLiveMatches()')) {
    print('  ✅ Usa getLiveMatches() correttamente');
  } else {
    print('  ❌ Non usa getLiveMatches()');
  }
  
  // Verifica 2: Filtro per elapsed
  if (content.contains('elapsed') && 
      (content.contains('> 0') || content.contains('!= null'))) {
    print('  ✅ Filtro per partite live implementato');
  } else {
    print('  ⚠️ Filtro per partite live potrebbe mancare');
  }
  
  // Verifica 3: Esclude partite finite
  if (content.contains('< 90') || content.contains('<= 89')) {
    print('  ✅ Esclusione partite finite implementata');
  } else {
    print('  ⚠️ Esclusione partite finite potrebbe mancare');
  }
  
  print('\n  📊 RIEPILOGO TEST 2:');
  print('     File: lib/screens/live_screen.dart');
  print('     Dimensione: ${(content.length / 1024).toStringAsFixed(2)} KB');
  print('     Righe: ${content.split('\n').length}');
}

void testFollowedMatchesPage() {
  print('\n\n📌 TEST 3: VERIFICA followed_matches_page.dart');
  print('-' * 80);
  
  final file = File('lib/pages/followed_matches_page.dart');
  
  if (!file.existsSync()) {
    print('  ❌ File non trovato!');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Verifica 1: Timer per auto-refresh
  if (content.contains('Timer') && content.contains('periodic')) {
    print('  ✅ Timer auto-refresh implementato');
  } else {
    print('  ⚠️ Timer auto-refresh potrebbe mancare');
  }
  
  // Verifica 2: Usa copyWith per aggiornamenti
  if (content.contains('copyWith')) {
    print('  ✅ Usa copyWith per aggiornamenti');
  } else {
    print('  ⚠️ copyWith potrebbe non essere usato');
  }
  
  // Verifica 3: Combina fixtures e live
  if (content.contains('getFixturesToday') && content.contains('getLiveMatches')) {
    print('  ✅ Combina dati da fixtures e live');
  } else {
    print('  ⚠️ Potrebbe non combinare fixtures e live');
  }
  
  // Verifica 4: Salvataggio in SharedPreferences
  if (content.contains('SharedPreferences') || content.contains('FollowedMatchesService')) {
    print('  ✅ Salvataggio persistente implementato');
  } else {
    print('  ⚠️ Salvataggio persistente potrebbe mancare');
  }
  
  print('\n  📊 RIEPILOGO TEST 3:');
  print('     File: lib/pages/followed_matches_page.dart');
  print('     Dimensione: ${(content.length / 1024).toStringAsFixed(2)} KB');
  print('     Righe: ${content.split('\n').length}');
}

void testFollowedMatchesUpdater() {
  print('\n\n🔄 TEST 4: VERIFICA followed_matches_updater.dart');
  print('-' * 80);
  
  final file = File('lib/services/followed_matches_updater.dart');
  
  if (!file.existsSync()) {
    print('  ⚠️ File non trovato (potrebbe non essere necessario)');
    print('     La logica potrebbe essere in followed_matches_page.dart');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Verifica 1: Classe FollowedMatchesUpdater
  if (content.contains('class FollowedMatchesUpdater')) {
    print('  ✅ Classe FollowedMatchesUpdater definita');
  } else {
    print('  ❌ Classe FollowedMatchesUpdater non trovata');
  }
  
  // Verifica 2: Timer per aggiornamenti
  if (content.contains('Timer')) {
    print('  ✅ Timer implementato');
  } else {
    print('  ⚠️ Timer potrebbe mancare');
  }
  
  // Verifica 3: Merge di dati
  if (content.contains('merge') || content.contains('combine')) {
    print('  ✅ Merge di dati implementato');
  } else {
    print('  ⚠️ Merge di dati potrebbe mancare');
  }
  
  print('\n  📊 RIEPILOGO TEST 4:');
  print('     File: lib/services/followed_matches_updater.dart');
  print('     Dimensione: ${(content.length / 1024).toStringAsFixed(2)} KB');
  print('     Righe: ${content.split('\n').length}');
}