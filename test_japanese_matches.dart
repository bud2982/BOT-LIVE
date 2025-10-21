import 'dart:io';
import 'lib/services/hybrid_football_service.dart';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🇯🇵 TEST: RICERCA PARTITE GIAPPONESI');
  print('=' * 80);
  print('Obiettivo: Capire perché le partite giapponesi non vengono trovate');
  print('=' * 80);
  
  final hybridService = HybridFootballService();
  final liveScoreService = LiveScoreApiService();
  
  try {
    // Test 1: Partite live generali
    print('\n📋 TEST 1: TUTTE LE PARTITE LIVE');
    print('-' * 50);
    
    final allLiveMatches = await liveScoreService.getLiveMatches();
    print('✅ Totale partite live trovate: ${allLiveMatches.length}');
    
    // Cerca partite giapponesi nelle live
    final japaneseInLive = allLiveMatches.where((match) => 
      match.league.toLowerCase().contains('japan') ||
      match.league.toLowerCase().contains('j-league') ||
      match.league.toLowerCase().contains('j1') ||
      match.league.toLowerCase().contains('j2') ||
      match.league.toLowerCase().contains('j3') ||
      match.country.toLowerCase().contains('japan') ||
      match.home.toLowerCase().contains('japan') ||
      match.away.toLowerCase().contains('japan') ||
      _isJapaneseTeam(match.home) ||
      _isJapaneseTeam(match.away)
    ).toList();
    
    print('🇯🇵 Partite giapponesi nelle LIVE: ${japaneseInLive.length}');
    
    if (japaneseInLive.isNotEmpty) {
      for (final match in japaneseInLive) {
        print('   ⚽ ${match.home} vs ${match.away}');
        print('      Lega: ${match.league}');
        print('      Paese: ${match.country}');
        print('      Elapsed: ${match.elapsed?.toString() ?? "null"}');
      }
    }
    
    // Test 2: Partite di oggi
    print('\n📋 TEST 2: PARTITE DI OGGI');
    print('-' * 50);
    
    final todayMatches = await hybridService.getFixturesToday();
    print('✅ Totale partite di oggi: ${todayMatches.length}');
    
    // Cerca partite giapponesi in quelle di oggi
    final japaneseToday = todayMatches.where((match) => 
      match.league.toLowerCase().contains('japan') ||
      match.league.toLowerCase().contains('j-league') ||
      match.league.toLowerCase().contains('j1') ||
      match.league.toLowerCase().contains('j2') ||
      match.league.toLowerCase().contains('j3') ||
      match.country.toLowerCase().contains('japan') ||
      _isJapaneseTeam(match.home) ||
      _isJapaneseTeam(match.away)
    ).toList();
    
    print('🇯🇵 Partite giapponesi OGGI: ${japaneseToday.length}');
    
    if (japaneseToday.isNotEmpty) {
      for (final match in japaneseToday) {
        print('   ⚽ ${match.home} vs ${match.away}');
        print('      Lega: ${match.league}');
        print('      Paese: ${match.country}');
        print('      Elapsed: ${match.elapsed?.toString() ?? "null"}');
        print('      Inizio: ${match.start}');
      }
    }
    
    // Test 3: Analisi leghe disponibili
    print('\n📋 TEST 3: ANALISI LEGHE DISPONIBILI');
    print('-' * 50);
    
    final allLeagues = <String>{};
    for (final match in todayMatches) {
      allLeagues.add(match.league);
    }
    
    final sortedLeagues = allLeagues.toList()..sort();
    print('📊 Leghe trovate oggi (${sortedLeagues.length}):');
    
    // Cerca leghe che potrebbero essere giapponesi
    final possibleJapaneseLeagues = sortedLeagues.where((league) =>
      league.toLowerCase().contains('japan') ||
      league.toLowerCase().contains('j-league') ||
      league.toLowerCase().contains('j1') ||
      league.toLowerCase().contains('j2') ||
      league.toLowerCase().contains('j3') ||
      league.toLowerCase().contains('jfl') ||
      league.toLowerCase().contains('emperor') ||
      league.toLowerCase().contains('nabisco')
    ).toList();
    
    if (possibleJapaneseLeagues.isNotEmpty) {
      print('🇯🇵 Leghe giapponesi trovate:');
      for (final league in possibleJapaneseLeagues) {
        final matchesInLeague = todayMatches.where((m) => m.league == league).length;
        print('   - $league ($matchesInLeague partite)');
      }
    } else {
      print('❌ Nessuna lega giapponese trovata nelle leghe di oggi');
      print('');
      print('🔍 Prime 20 leghe disponibili:');
      for (int i = 0; i < sortedLeagues.length && i < 20; i++) {
        print('   ${i + 1}. ${sortedLeagues[i]}');
      }
    }
    
    // Test 4: Verifica fuso orario
    print('\n📋 TEST 4: VERIFICA FUSO ORARIO');
    print('-' * 50);
    
    final now = DateTime.now();
    final japanTime = now.toUtc().add(const Duration(hours: 9)); // JST = UTC+9
    
    print('⏰ Ora locale: ${now.toString()}');
    print('⏰ Ora in Giappone: ${japanTime.toString()}');
    print('');
    
    // Le partite giapponesi di solito si giocano tra le 13:00 e le 20:00 JST
    final japanHour = japanTime.hour;
    if (japanHour >= 13 && japanHour <= 20) {
      print('✅ Orario favorevole per partite giapponesi (13:00-20:00 JST)');
    } else {
      print('⚠️ Orario non tipico per partite giapponesi');
      print('   Le partite J-League di solito si giocano 13:00-20:00 JST');
    }
    
    // Risultato finale
    print('\n${'=' * 80}');
    print('📊 RIEPILOGO RICERCA PARTITE GIAPPONESI:');
    print('   - Partite live giapponesi: ${japaneseInLive.length}');
    print('   - Partite oggi giapponesi: ${japaneseToday.length}');
    print('   - Leghe giapponesi trovate: ${possibleJapaneseLeagues.length}');
    print('   - Ora in Giappone: ${japanTime.hour}:${japanTime.minute.toString().padLeft(2, '0')}');
    
    if (japaneseInLive.isEmpty && japaneseToday.isEmpty) {
      print('');
      print('🤔 POSSIBILI MOTIVI PER CUI NON TROVI PARTITE GIAPPONESI:');
      print('   1. Non ci sono partite J-League programmate oggi');
      print('   2. Le partite sono finite o non ancora iniziate');
      print('   3. La J-League potrebbe essere in pausa (off-season)');
      print('   4. L\'API potrebbe non coprire tutte le leghe giapponesi');
      print('   5. I nomi delle squadre/leghe potrebbero essere diversi');
    }
    
  } catch (e) {
    print('❌ ERRORE durante il test: $e');
    exit(1);
  }
}

bool _isJapaneseTeam(String teamName) {
  final japaneseTeams = [
    'kashima', 'antlers', 'urawa', 'reds', 'gamba', 'osaka', 'yokohama',
    'marinos', 'fc tokyo', 'kawasaki', 'frontale', 'nagoya', 'grampus',
    'cerezo', 'sanfrecce', 'hiroshima', 'vissel', 'kobe', 'shonan',
    'bellmare', 'sagan', 'tosu', 'consadole', 'sapporo', 'jubilo', 'iwata',
    'shimizu', 's-pulse', 'kashiwa', 'reysol', 'avispa', 'fukuoka',
    'kyoto', 'sanga', 'machida', 'zelvia'
  ];
  
  final lowerTeamName = teamName.toLowerCase();
  return japaneseTeams.any((team) => lowerTeamName.contains(team));
}