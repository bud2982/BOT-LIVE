import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔥 TEST: COPERTURA MASSIMA 30 PAGINE');
  print('=' * 80);
  print('📌 Configurazione: 30 pagine (900 match max) - MASSIMA COPERTURA SOSTENIBILE');
  print('=' * 80);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    print('\n⏳ Recupero partite (30 pagine = 900 match max)...\n');
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
    print('🔍 VERIFICA CAMPIONATI MANCANTI (PRIORITARI)');
    print('=' * 80);
    
    final priorityMissing = {
      'La Liga': ['spain', 'la liga', 'laliga'],
      'La Liga 2': ['spain', 'la liga 2', 'segunda'],
      'Liga MX': ['mexico', 'liga mx'],
      'J League': ['japan', 'j league', 'j-league'],
      'K League': ['korea', 'k league', 'k-league'],
    };
    
    int foundPriority = 0;
    
    print('\n📊 CAMPIONATI PRECEDENTEMENTE MANCANTI:');
    for (final missing in priorityMissing.entries) {
      final found = leagueMap.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return missing.value.any((term) => key.contains(term));
      }).toList();
      
      if (found.isNotEmpty) {
        print('✅ ${missing.key.padRight(20)} → TROVATO!');
        for (final f in found) {
          print('   └─ ${f.key} (${f.value.length} match)');
        }
        foundPriority++;
      } else {
        print('❌ ${missing.key.padRight(20)} → ancora mancante');
      }
    }
    
    print('\n${'=' * 80}');
    print('🏆 TOP CAMPIONATI (15+ PARTITE)');
    print('=' * 80);
    
    final topLeagues = leagueMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    int topCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 15) {
        print('${(topCount + 1).toString().padLeft(2)}. ⭐ ${entry.key.padRight(50)} → ${entry.value.length} match');
        topCount++;
      }
    }
    
    print('\n${'=' * 80}');
    print('📈 DISTRIBUZIONE PER PAESE (TOP 15)');
    print('=' * 80);
    
    final sortedCountries = countryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var i = 0; i < (sortedCountries.length > 15 ? 15 : sortedCountries.length); i++) {
      final entry = sortedCountries[i];
      final percentage = (entry.value / allFixtures.length * 100).toStringAsFixed(1);
      print('${(i + 1).toString().padLeft(2)}. 🏳️  ${entry.key.padRight(25)} → ${entry.value.toString().padLeft(3)} match ($percentage%)');
    }
    
    print('\n${'=' * 80}');
    print('📊 ANALISI PER CATEGORIA');
    print('=' * 80);
    
    int mega = 0, large = 0, medium = 0, small = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 30) {
        mega++;
      } else if (entry.value.length >= 20) {
        large++;
      } else if (entry.value.length >= 10) {
        medium++;
      } else {
        small++;
      }
    }
    
    print('🔥 Mega campionati (30+):  $mega');
    print('⭐ Grandi (20-29):         $large');
    print('📊 Medi (10-19):           $medium');
    print('📋 Piccoli (<10):          $small');
    
    print('\n${'=' * 80}');
    print('🎯 RISULTATI FINALI');
    print('=' * 80);
    print('✅ Campionati mancanti trovati: $foundPriority / 5');
    print('✅ Partite totali: ${allFixtures.length}');
    print('🏆 Campionati totali: $uniqueLeagues');
    print('🌍 Paesi coperti: $uniqueCountries');
    
    print('\n${'=' * 80}');
    print('📊 CRONOLOGIA UPGRADE COPERTURA');
    print('=' * 80);
    print('v1: 10 pagine → 300 match,   73 campionati');
    print('v2: 15 pagine → 450 match,   83 campionati');
    print('v3: 20 pagine → 600 match,  150 campionati');
    print('v4: 30 pagine → ${allFixtures.length} match, $uniqueLeagues campionati ⭐ MASSIMA COPERTURA!');
    
    print('\n✅ TEST COMPLETATO CON SUCCESSO');
    
  } catch (e) {
    print('❌ ERRORE: $e');
    exit(1);
  }
}