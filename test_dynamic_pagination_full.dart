import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔓 TEST: PAGINAZIONE DINAMICA ILLIMITATA');
  print('=' * 80);
  print('📌 Configurazione: TUTTE le pagine disponibili (nessun limite fisso)');
  print('=' * 80);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    print('\n⏳ Recupero TUTTE le partite disponibili dall\'API...\n');
    final allFixtures = await liveScoreService.getFixturesToday();
    
    print('\n${'=' * 80}');
    print('📊 STATISTICHE GENERALI');
    print('=' * 80);
    print('✅ TOTALE PARTITE: ${allFixtures.length}');
    
    // Analisi per campionato
    final leagueMap = <String, List<dynamic>>{};
    final countryMap = <String, int>{};
    
    for (final fixture in allFixtures) {
      final leagueKey = '${fixture.country} | ${fixture.league}';
      leagueMap.putIfAbsent(leagueKey, () => []);
      leagueMap[leagueKey]!.add(fixture);
      
      countryMap.putIfAbsent(fixture.country, () => 0);
      countryMap[fixture.country] = countryMap[fixture.country]! + 1;
    }
    
    final uniqueLeagues = leagueMap.length;
    final uniqueCountries = countryMap.length;
    
    print('🏆 CAMPIONATI UNICI: $uniqueLeagues');
    print('🌍 PAESI: $uniqueCountries');
    
    print('\n${'=' * 80}');
    print('📈 DISTRIBUZIONE PER PAESE (TOP 20)');
    print('=' * 80);
    
    final sortedCountries = countryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var i = 0; i < (sortedCountries.length > 20 ? 20 : sortedCountries.length); i++) {
      final entry = sortedCountries[i];
      final percentage = (entry.value / allFixtures.length * 100).toStringAsFixed(1);
      final bar = '█' * (entry.value ~/ 10);
      print('${(i + 1).toString().padLeft(2)}. 🏳️  ${entry.key.padRight(25)} → ${entry.value.toString().padLeft(3)} (${percentage.padLeft(5)}%) $bar');
    }
    
    print('\n${'=' * 80}');
    print('🏆 CAMPIONATI PRINCIPALI (30+ PARTITE)');
    print('=' * 80);
    
    final topLeagues = leagueMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    int megaCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 30) {
        print('🔥 ${entry.key.padRight(50)} → ${entry.value.length} match');
        megaCount++;
      }
    }
    if (megaCount == 0) print('(Nessuno)');
    
    print('\n${'=' * 80}');
    print('📊 CAMPIONATI GRANDI (20-29 PARTITE)');
    print('=' * 80);
    
    int largeCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 20 && entry.value.length < 30) {
        print('⭐ ${entry.key.padRight(50)} → ${entry.value.length} match');
        largeCount++;
      }
    }
    if (largeCount == 0) print('(Nessuno)');
    
    print('\n${'=' * 80}');
    print('🎯 CAMPIONATI MEDI (10-19 PARTITE)');
    print('=' * 80);
    
    int mediumCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 10 && entry.value.length < 20) {
        mediumCount++;
      }
    }
    print('(Totale: $mediumCount campionati)');
    for (final entry in topLeagues) {
      if (entry.value.length >= 10 && entry.value.length < 20) {
        print('📊 ${entry.key.padRight(50)} → ${entry.value.length} match');
      }
    }
    
    print('\n${'=' * 80}');
    print('📋 CAMPIONATI MINORI (< 10 PARTITE)');
    print('=' * 80);
    
    int smallCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length < 10) {
        smallCount++;
      }
    }
    print('(Totale: $smallCount campionati con < 10 match)');
    
    // Verifica campionati mancanti importanti
    print('\n${'=' * 80}');
    print('🔍 ANALISI CAMPIONATI PRECEDENTEMENTE MANCANTI');
    print('=' * 80);
    
    final previouslyMissing = {
      'La Liga': ['spain', 'la liga'],
      'La Liga 2': ['spain', 'la liga 2'],
      'Liga MX': ['mexico', 'liga mx'],
      'J League': ['japan', 'j league'],
      'K League': ['korea', 'k league'],
    };
    
    int nowFound = 0;
    
    for (final missing in previouslyMissing.entries) {
      final found = leagueMap.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return missing.value.every((term) => key.contains(term));
      }).toList();
      
      if (found.isNotEmpty) {
        print('✅ ${missing.key.padRight(20)} → TROVATO! (${found[0].value.length} match)');
        nowFound++;
      } else {
        print('❌ ${missing.key.padRight(20)} → ancora mancante');
      }
    }
    
    print('\n${'=' * 80}');
    print('🎊 RISULTATI FINALI');
    print('=' * 80);
    print('📌 Campionati precedentemente mancanti trovati: $nowFound / 5');
    print('✅ Partite totali recuperate: ${allFixtures.length}');
    print('🏆 Campionati totali: $uniqueLeagues');
    print('🌍 Paesi coperti: $uniqueCountries');
    
    print('\n${'=' * 80}');
    print('📊 CONFRONTO TRA CONFIGURAZIONI');
    print('=' * 80);
    print('10 pagine (ORIGINALE)      → 300 match,   73 campionati');
    print('15 pagine (PRIMO UPGRADE)  → 450 match,   83 campionati');
    print('20 pagine (UPGRADE 2)      → 600 match,  150 campionati');
    print('∞ pagine (DINAMICA ATTUALE) → ${allFixtures.length} match, $uniqueLeagues campionati ⭐ MASSIMA COPERTURA!');
    
    print('\n✅ TEST COMPLETATO CON SUCCESSO');
    
  } catch (e) {
    print('❌ ERRORE: $e');
    exit(1);
  }
}