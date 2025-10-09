import '../models/fixture.dart';
import 'hybrid_football_service.dart';

class CountryMatchesService {
  final HybridFootballService _hybridService = HybridFootballService();
  
  /// Ottiene le partite raggruppate per paese
  Future<Map<String, List<Fixture>>> getMatchesByCountry() async {
    try {
      print('🌍 Recupero partite raggruppate per paese da LiveScore API...');
      
      // Recupera tutte le partite da LiveScore API tramite HybridFootballService
      final allFixtures = await _hybridService.getFixturesToday();
      
      if (allFixtures.isEmpty) {
        print('❌ Nessuna partita trovata da LiveScore API');
        return {};
      }
      
      // Raggruppa le partite per paese
      final Map<String, List<Fixture>> matchesByCountry = {};
      
      for (final fixture in allFixtures) {
        final country = fixture.country;
        if (!matchesByCountry.containsKey(country)) {
          matchesByCountry[country] = [];
        }
        matchesByCountry[country]!.add(fixture);
      }
      
      // Ordina i paesi per numero di partite (decrescente)
      final sortedCountries = matchesByCountry.keys.toList()
        ..sort((a, b) => matchesByCountry[b]!.length.compareTo(matchesByCountry[a]!.length));
      
      final sortedMatchesByCountry = <String, List<Fixture>>{};
      for (final country in sortedCountries) {
        sortedMatchesByCountry[country] = matchesByCountry[country]!;
      }
      
      print('🎯 Partite raggruppate per ${sortedMatchesByCountry.length} paesi');
      final totalMatches = allFixtures.length;
      print('📊 Totale partite: $totalMatches');
      
      // Stampa statistiche per paese
      for (final entry in sortedMatchesByCountry.entries) {
        final liveCount = entry.value.where((f) => f.elapsed != null).length;
        print('   ${entry.key}: ${entry.value.length} partite ($liveCount live)');
      }
      
      return sortedMatchesByCountry;
      
    } catch (e) {
      print('💥 Errore CountryMatchesService: $e');
      return {};
    }
  }
  
  /// Ottiene le partite per un paese specifico
  Future<List<Fixture>> getMatchesForCountry(String country) async {
    final allMatches = await getMatchesByCountry();
    return allMatches[country] ?? [];
  }
  
  /// Ottiene la lista dei paesi disponibili
  Future<List<String>> getAvailableCountries() async {
    final allMatches = await getMatchesByCountry();
    return allMatches.keys.toList();
  }
  
  /// Ottiene statistiche per paese
  Future<Map<String, int>> getCountryStatistics() async {
    final allMatches = await getMatchesByCountry();
    final Map<String, int> stats = {};
    
    for (final entry in allMatches.entries) {
      stats[entry.key] = entry.value.length;
    }
    
    return stats;
  }
}