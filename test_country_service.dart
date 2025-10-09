import 'package:live_bot/services/country_matches_service.dart';

void main() async {
  print('🌍 TEST COUNTRY MATCHES SERVICE');
  print('=' * 50);
  
  final countryService = CountryMatchesService();
  
  try {
    print('📋 Test: Recupero partite raggruppate per paese...');
    final matchesByCountry = await countryService.getMatchesByCountry();
    
    if (matchesByCountry.isEmpty) {
      print('❌ Nessuna partita trovata');
      return;
    }
    
    print('✅ Paesi catalogati: ${matchesByCountry.length}');
    print('📊 Totale partite: ${matchesByCountry.values.fold(0, (sum, matches) => sum + matches.length)}');
    
    print('\n🏆 PARTITE PER PAESE:');
    print('-' * 30);
    
    for (final entry in matchesByCountry.entries) {
      final country = entry.key;
      final matches = entry.value;
      final liveCount = matches.where((m) => m.elapsed != null).length;
      
      print('🌍 $country: ${matches.length} partite ($liveCount live)');
      
      // Mostra alcune partite di esempio per ogni paese
      for (int i = 0; i < matches.length && i < 3; i++) {
        final match = matches[i];
        final status = match.elapsed != null ? '🔴 LIVE ${match.elapsed}\'' : '⏰ ${match.start.hour}:${match.start.minute.toString().padLeft(2, '0')}';
        print('   • ${match.home} vs ${match.away} ($status)');
        print('     📍 ${match.league}');
      }
      
      if (matches.length > 3) {
        print('   ... e altre ${matches.length - 3} partite');
      }
      print('');
    }
    
    print('=' * 50);
    print('🎯 TEST COMPLETATO CON SUCCESSO!');
    
  } catch (e) {
    print('❌ Errore durante il test: $e');
  }
}