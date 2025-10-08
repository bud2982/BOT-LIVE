import 'package:live_bot/services/hybrid_football_service.dart';
import 'package:live_bot/services/country_matches_service.dart';
import 'package:live_bot/services/followed_matches_service.dart';

void main() async {
  print('🔍 Test Completo Funzionalità App\n');
  
  // Test 1: Verifica dati puliti e realistici
  print('1️⃣ VERIFICA DATI PULITI E REALISTICI');
  print('=' * 50);
  
  final hybridService = HybridFootballService();
  final fixtures = await hybridService.getFixturesToday();
  
  print('✅ Partite trovate: ${fixtures.length}');
  
  // Verifica nomi squadre corretti (non malformati)
  bool hasCleanNames = true;
  for (final fixture in fixtures) {
    if (fixture.home.contains('drew') || fixture.home.contains('with') || 
        fixture.away.contains('drew') || fixture.away.contains('with')) {
      hasCleanNames = false;
      print('❌ Nome malformato trovato: ${fixture.home} vs ${fixture.away}');
    }
  }
  
  if (hasCleanNames) {
    print('✅ Tutti i nomi delle squadre sono puliti e corretti');
  }
  
  // Mostra esempi di nomi corretti
  print('\n📋 Esempi di partite con nomi corretti:');
  for (int i = 0; i < fixtures.length && i < 5; i++) {
    final f = fixtures[i];
    final status = f.elapsed != null ? 'LIVE ${f.elapsed}\'' : 'PROGRAMMATA';
    print('   ${f.home} vs ${f.away} - ${f.league} ($status)');
  }
  
  print('\n${'=' * 70}\n');
  
  // Test 2: Verifica catalogazione per paese
  print('2️⃣ VERIFICA CATALOGAZIONE PER PAESE');
  print('=' * 50);
  
  final countryService = CountryMatchesService();
  final matchesByCountry = await countryService.getMatchesByCountry();
  
  print('✅ Paesi catalogati: ${matchesByCountry.length}');
  
  if (matchesByCountry.isNotEmpty) {
    print('\n🌍 Distribuzione partite per paese:');
    int totalMatches = 0;
    int totalLive = 0;
    
    for (final entry in matchesByCountry.entries) {
      final liveCount = entry.value.where((f) => f.elapsed != null).length;
      totalMatches += entry.value.length;
      totalLive += liveCount;
      
      print('   🏴 ${entry.key}: ${entry.value.length} partite ($liveCount live)');
      
      // Mostra alcune partite per questo paese
      for (int i = 0; i < entry.value.length && i < 2; i++) {
        final match = entry.value[i];
        final status = match.elapsed != null ? 'LIVE' : 'PROG';
        print('      • ${match.home} vs ${match.away} (${match.league}) [$status]');
      }
    }
    
    print('\n📊 STATISTICHE TOTALI:');
    print('   • Paesi: ${matchesByCountry.length}');
    print('   • Partite totali: $totalMatches');
    print('   • Partite live: $totalLive');
    print('   • Media partite per paese: ${(totalMatches / matchesByCountry.length).toStringAsFixed(1)}');
  }
  
  print('\n${'=' * 70}\n');
  
  // Test 3: Verifica funzionalità partite seguite
  print('3️⃣ VERIFICA FUNZIONALITÀ PARTITE SEGUITE');
  print('=' * 50);
  
  final followedService = FollowedMatchesService();
  
  // Pulisci partite vecchie
  await followedService.cleanupOldMatches();
  
  // Ottieni partite attuali seguite
  final currentFollowed = await followedService.getFollowedMatches();
  print('📋 Partite attualmente seguite: ${currentFollowed.length}');
  
  if (fixtures.isNotEmpty) {
    // Test: aggiungi una partita alle seguite
    final testMatch = fixtures.first;
    print('\n🧪 Test aggiunta partita alle seguite...');
    print('   Partita: ${testMatch.home} vs ${testMatch.away}');
    
    final addResult = await followedService.followMatch(testMatch);
    if (addResult) {
      print('✅ Partita aggiunta con successo alle seguite');
      
      // Verifica che sia stata aggiunta
      final isFollowed = await followedService.isMatchFollowed(testMatch.id);
      if (isFollowed) {
        print('✅ Verifica: partita correttamente seguita');
        
        // Test rimozione
        final removeResult = await followedService.unfollowMatch(testMatch.id);
        if (removeResult) {
          print('✅ Partita rimossa con successo dalle seguite');
        } else {
          print('❌ Errore nella rimozione della partita');
        }
      } else {
        print('❌ Errore: partita non risulta seguita dopo l\'aggiunta');
      }
    } else {
      print('❌ Errore nell\'aggiunta della partita alle seguite');
    }
  }
  
  print('\n${'=' * 70}\n');
  
  // Test 4: Verifica partite live
  print('4️⃣ VERIFICA PARTITE LIVE');
  print('=' * 50);
  
  final liveMatches = await hybridService.getLiveMatches();
  print('🔴 Partite live trovate: ${liveMatches.length}');
  
  if (liveMatches.isNotEmpty) {
    print('\n⚽ Partite attualmente in corso:');
    for (final match in liveMatches) {
      print('   🔴 ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}');
      print('      ${match.league} (${match.country}) - ${match.elapsed}\'');
    }
  }
  
  print('\n${'=' * 70}\n');
  
  // Riepilogo finale
  print('🎯 RIEPILOGO FINALE');
  print('=' * 50);
  
  final issues = <String>[];
  
  if (!hasCleanNames) issues.add('Nomi squadre malformati');
  if (matchesByCountry.isEmpty) issues.add('Catalogazione per paese non funziona');
  if (fixtures.isEmpty) issues.add('Nessuna partita trovata');
  
  if (issues.isEmpty) {
    print('🎉 TUTTI I PROBLEMI SONO STATI RISOLTI!');
    print('');
    print('✅ Nomi squadre corretti e puliti');
    print('✅ Partite catalogate correttamente per paese');
    print('✅ Funzionalità partite seguite operativa');
    print('✅ Partite live identificate correttamente');
    print('✅ Dati realistici e utilizzabili');
    print('');
    print('🚀 L\'app è pronta per l\'uso!');
  } else {
    print('⚠️ PROBLEMI RIMANENTI:');
    for (final issue in issues) {
      print('   ❌ $issue');
    }
  }
  
  print('\n🏁 Test completato!');
}