import 'livescore_api_service.dart';
import '../models/fixture.dart';

/// HybridFootballService - Ora utilizza SOLO LiveScore API
/// 
/// NOTA: Inizialmente questo servizio coordinava multiple fonti:
/// - LiveScore API (primaria)
/// - TestProxyService (fallback)
/// - ApiFootballService (fallback secondario)
/// - SofaScore Scraper (fallback terziario)
/// 
/// ATTUALMENTE: Disabilitati tutti i fallback per usare esclusivamente LiveScore.
/// Se vuoi ripristinare altre fonti, vedi il git history.
class HybridFootballService {
  final LiveScoreApiService _liveScoreApiService;
  
  HybridFootballService({
    String? apiKey, // Manteniamo il parametro per retrocompatibilità ma lo ignoriamo
    bool useSampleData = false, // Ignorato - usiamo SOLO LiveScore API
  }) : 
    _liveScoreApiService = LiveScoreApiService();
  
  Future<List<Fixture>> getFixturesToday() async {
    print('🎯 HybridFootballService: Utilizzo SOLO LiveScore API');
    try {
      final fixtures = await _liveScoreApiService.getFixturesToday();
      print('✅ HybridFootballService: Recuperate ${fixtures.length} partite da LiveScore');
      return fixtures;
    } catch (e) {
      print('❌ HybridFootballService: ERRORE LiveScore API - $e');
      // NESSUN FALLBACK - Solo LiveScore è configurato
      throw Exception('❌ ERRORE: Non è possibile recuperare le partite da LiveScore. Verifica la configurazione API.');
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    print('🎯 HybridFootballService: Recupero partite live SOLO da LiveScore API');
    try {
      final fixtures = await _liveScoreApiService.getLiveMatches();
      print('✅ HybridFootballService: Recuperate ${fixtures.length} partite live');
      return fixtures;
    } catch (e) {
      print('❌ HybridFootballService: ERRORE LiveScore API - $e');
      throw Exception('❌ ERRORE: Non è possibile recuperare le partite live. Verifica la connessione e la configurazione API.');
    }
  }

  Future<List<Fixture>> getLiveByIds(List<int> fixtureIds) async {
    print('🎯 HybridFootballService: Recupero ${fixtureIds.length} partite per ID da LiveScore');
    try {
      final List<Fixture> matchingFixtures = [];
      
      // Cerca prima nelle partite live
      try {
        final allLive = await _liveScoreApiService.getLiveMatches();
        final liveMatches = allLive.where((f) => fixtureIds.contains(f.id)).toList();
        matchingFixtures.addAll(liveMatches);
        print('✅ Trovate ${liveMatches.length} partite live per gli ID richiesti');
      } catch (e) {
        print('❌ Errore nel recupero delle partite live: $e');
      }
      
      // Se non hai trovato tutte le partite, cerca nelle partite di oggi
      if (matchingFixtures.length < fixtureIds.length) {
        try {
          final allToday = await _liveScoreApiService.getFixturesToday();
          final todayMatches = allToday.where((f) => fixtureIds.contains(f.id)).toList();
          
          for (final match in todayMatches) {
            if (!matchingFixtures.any((m) => m.id == match.id)) {
              matchingFixtures.add(match);
            }
          }
          
          print('✅ Trovate ${todayMatches.length} partite di oggi per gli ID richiesti');
        } catch (e) {
          print('❌ Errore nel recupero delle partite di oggi: $e');
        }
      }
      
      print('✅ TOTALE: ${matchingFixtures.length}/${fixtureIds.length} partite trovate');
      return matchingFixtures;
      
    } catch (e) {
      print('❌ HybridFootballService: ERRORE durante getLiveByIds - $e');
      throw Exception('❌ ERRORE: Non è possibile recuperare le partite. Verifica la connessione.');
    }
  }

  Future<bool> testConnection() async {
    print('🧪 HybridFootballService: Test connessione a LiveScore API');
    try {
      final result = await _liveScoreApiService.testConnection();
      if (result) {
        print('✅ Connessione a LiveScore API: OK');
      } else {
        print('❌ Connessione a LiveScore API: FALLITA');
      }
      return result;
    } catch (e) {
      print('❌ ERRORE test connessione: $e');
      return false;
    }
  }
}