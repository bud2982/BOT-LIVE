import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🔍 TEST: ANALISI COMPLETA CAMPIONATI A 20 PAGINE');
  print('=' * 70);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    print('⏳ Recupero partite (20 pagine = 600 match max)...\n');
    final allFixtures = await liveScoreService.getFixturesToday();
    
    print('\n' + '=' * 70);
    print('📊 STATISTICHE GENERALI');
    print('=' * 70);
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
    
    print('\n' + '=' * 70);
    print('📈 DISTRIBUZIONE PER PAESE (TOP 15)');
    print('=' * 70);
    
    final sortedCountries = countryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var i = 0; i < (sortedCountries.length > 15 ? 15 : sortedCountries.length); i++) {
      final entry = sortedCountries[i];
      final percentage = (entry.value / allFixtures.length * 100).toStringAsFixed(1);
      print('${i + 1}. 🏳️ ${entry.key.padRight(20)} → ${entry.value.toString().padLeft(3)} match ($percentage%)');
    }
    
    print('\n' + '=' * 70);
    print('🏆 CAMPIONATI PRINCIPALI (20+ PARTITE)');
    print('=' * 70);
    
    final topLeagues = leagueMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    for (final entry in topLeagues) {
      if (entry.value.length >= 20) {
        print('✅ ${entry.key.padRight(45)} → ${entry.value.length} match');
      }
    }
    
    print('\n' + '=' * 70);
    print('🎯 CAMPIONATI MEDI (10-19 PARTITE)');
    print('=' * 70);
    
    int mediumCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length >= 10 && entry.value.length < 20) {
        print('📊 ${entry.key.padRight(45)} → ${entry.value.length} match');
        mediumCount++;
      }
    }
    print('(Totale: $mediumCount campionati)');
    
    print('\n' + '=' * 70);
    print('📋 CAMPIONATI MINORI (< 10 PARTITE)');
    print('=' * 70);
    
    int smallCount = 0;
    for (final entry in topLeagues) {
      if (entry.value.length < 10) {
        smallCount++;
      }
    }
    print('(Totale: $smallCount campionati con < 10 match)');
    
    // Verifica campionati mancanti importanti
    print('\n' + '=' * 70);
    print('🔍 ANALISI CAMPIONATI MANCANTI IMPORTANTI');
    print('=' * 70);
    
    final missingLeagues = {
      'La Liga': ['spain', 'la liga'],
      'La Liga 2': ['spain', 'la liga 2'],
      'Ligue 1': ['france', 'ligue 1'],
      'Eredivisie': ['netherlands', 'eredivisie'],
      'Eerste Divisie': ['netherlands', 'eerste'],
      'Primeira Liga': ['portugal', 'primeira'],
      'Liga MX': ['mexico', 'liga mx'],
      'J League': ['japan', 'j league'],
      'K League': ['korea', 'k league'],
    };
    
    int foundMissing = 0;
    int stillMissing = 0;
    
    for (final missing in missingLeagues.entries) {
      final found = leagueMap.entries.any((entry) {
        final key = entry.key.toLowerCase();
        return missing.value.every((term) => key.contains(term));
      });
      
      if (found) {
        print('✅ ${missing.key.padRight(20)} → TROVATO!');
        foundMissing++;
      } else {
        print('❌ ${missing.key.padRight(20)} → ancora mancante');
        stillMissing++;
      }
    }
    
    print('\n' + '=' * 70);
    print('📊 RIASSUNTO MIGLIORAMENTI');
    print('=' * 70);
    print('✅ Campionati importanti aggiunti: $foundMissing');
    print('❌ Campionati importanti ancora mancanti: $stillMissing');
    print('\nⓘ  Configurazione: 20 pagine');
    print('ⓘ  Partite recuperate: ${allFixtures.length}');
    print('ⓘ  Campionati totali: $uniqueLeagues');
    print('ⓘ  Paesi coperti: $uniqueCountries');
    
    // Confronto con 15 pagine (se lo ricordiamo dai test precedenti)
    print('\n' + '=' * 70);
    print('📈 CONFRONTO CON CONFIGURAZIONE PRECEDENTE');
    print('=' * 70);
    print('15 pagine → 450 match, 83 campionati');
    print('20 pagine → ${allFixtures.length} match, $uniqueLeagues campionati');
    print('Differenza → +${allFixtures.length - 450} match, +${uniqueLeagues - 83} campionati');
    
    print('\n✅ TEST COMPLETATO CON SUCCESSO');
    
  } catch (e) {
    print('❌ ERRORE: $e');
    exit(1);
  }
}