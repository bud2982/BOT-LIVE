import 'package:live_bot/services/official_livescore_service.dart';
import 'package:live_bot/services/hybrid_football_service.dart';
import 'package:live_bot/services/country_matches_service.dart';

void main() async {
  print('🧪 Test dei nuovi servizi...\n');
  
  // Test 1: Servizio ufficiale LiveScore
  print('1️⃣ Test OfficialLiveScoreService...');
  final officialService = OfficialLiveScoreService();
  
  try {
    final fixtures = await officialService.getFixturesToday();
    print('✅ Partite trovate: ${fixtures.length}');
    
    if (fixtures.isNotEmpty) {
      print('📋 Prime 3 partite:');
      for (int i = 0; i < fixtures.length && i < 3; i++) {
        final f = fixtures[i];
        print('   ${f.home} vs ${f.away} (${f.league}, ${f.country})');
      }
    }
    
    // Test partite live
    final liveFixtures = await officialService.getLiveMatches();
    print('🔴 Partite live: ${liveFixtures.length}');
    
  } catch (e) {
    print('❌ Errore OfficialLiveScoreService: $e');
  }
  
  print('\n${'=' * 50}\n');
  
  // Test 2: Servizio ibrido aggiornato
  print('2️⃣ Test HybridFootballService aggiornato...');
  final hybridService = HybridFootballService();
  
  try {
    final fixtures = await hybridService.getFixturesToday();
    print('✅ Partite trovate: ${fixtures.length}');
    
    final liveFixtures = await hybridService.getLiveMatches();
    print('🔴 Partite live: ${liveFixtures.length}');
    
    final connectionTest = await hybridService.testConnection();
    print('🌐 Test connessione: ${connectionTest ? "OK" : "FALLITO"}');
    
  } catch (e) {
    print('❌ Errore HybridFootballService: $e');
  }
  
  print('\n${'=' * 50}\n');
  
  // Test 3: Servizio per paese
  print('3️⃣ Test CountryMatchesService...');
  final countryService = CountryMatchesService();
  
  try {
    final matchesByCountry = await countryService.getMatchesByCountry();
    print('✅ Paesi trovati: ${matchesByCountry.length}');
    
    if (matchesByCountry.isNotEmpty) {
      print('🌍 Paesi con partite:');
      for (final entry in matchesByCountry.entries) {
        final liveCount = entry.value.where((f) => f.elapsed != null).length;
        print('   ${entry.key}: ${entry.value.length} partite ($liveCount live)');
      }
    }
    
    final countries = await countryService.getAvailableCountries();
    print('📍 Paesi disponibili: ${countries.join(", ")}');
    
  } catch (e) {
    print('❌ Errore CountryMatchesService: $e');
  }
  
  print('\n🎯 Test completati!');
}