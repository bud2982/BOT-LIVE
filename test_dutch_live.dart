import 'dart:io';
import 'lib/services/livescore_api_service.dart';

void main() async {
  print('🇳🇱 TEST: PARTITE LIVE OLANDESI');
  print('=' * 50);
  
  final liveScoreService = LiveScoreApiService();
  
  try {
    final liveMatches = await liveScoreService.getLiveMatches();
    print('✅ Totale partite live: ${liveMatches.length}');
    
    // Cerca partite olandesi nelle live
    final dutchLive = liveMatches.where((match) => 
      match.country.toLowerCase().contains('netherlands') ||
      match.league.toLowerCase().contains('eredivisie') ||
      match.league.toLowerCase().contains('eerste')
    ).toList();
    
    print('🇳🇱 Partite live olandesi: ${dutchLive.length}');
    
    if (dutchLive.isNotEmpty) {
      for (final match in dutchLive) {
        print('   ⚽ ${match.home} vs ${match.away}');
        print('      Lega: ${match.league}');
        print('      Paese: ${match.country}');
        print('      Elapsed: ${match.elapsed?.toString() ?? "null"}');
      }
    } else {
      print('❌ Nessuna partita live olandese al momento');
    }
    
    // Mostra tutte le partite live per vedere cosa c'è
    print('\n📋 TUTTE LE PARTITE LIVE:');
    for (final match in liveMatches) {
      print('   ${match.country} - ${match.league}: ${match.home} vs ${match.away}');
    }
    
  } catch (e) {
    print('❌ ERRORE: $e');
    exit(1);
  }
}