import 'livescore_api_service.dart';
import 'test_proxy_service.dart';
import '../models/fixture.dart';

class HybridFootballService {
  final LiveScoreApiService _liveScoreApiService;
  final TestProxyService _testProxyService;
  
  HybridFootballService({
    String? apiKey, // Manteniamo il parametro per retrocompatibilità ma lo ignoriamo
    bool useSampleData = false, // Impostiamo a false per preferire dati reali
  }) : 
    _liveScoreApiService = LiveScoreApiService(), // Usa SOLO LiveScore API ufficiali
    _testProxyService = TestProxyService();
  
  Future<List<Fixture>> getFixturesToday() async {
    print('HybridFootballService: MODALITÀ TEST - Usando dati dal proxy server...');
    try {
      final fixtures = await _testProxyService.getFixturesToday();
      print('HybridFootballService: Recuperate ${fixtures.length} partite dal proxy server');
      return fixtures;
    } catch (e) {
      print('HybridFootballService: ERRORE proxy server in getFixturesToday: $e');
      print('HybridFootballService: Fallback a LiveScore API...');
      try {
        final fixtures = await _liveScoreApiService.getFixturesToday();
        print('HybridFootballService: Recuperate ${fixtures.length} partite da LiveScore API');
        return fixtures;
      } catch (e2) {
        print('HybridFootballService: ERRORE anche con LiveScore API: $e2');
        throw Exception('Errore sia proxy che LiveScore API: $e');
      }
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    print('HybridFootballService: Recupero partite live SOLO da LiveScore API...');
    try {
      final fixtures = await _liveScoreApiService.getLiveMatches();
      print('HybridFootballService: Recuperate ${fixtures.length} partite live da LiveScore API');
      return fixtures;
    } catch (e) {
      print('HybridFootballService: ERRORE LiveScore API in getLiveMatches: $e');
      // NON utilizzare fallback - solo LiveScore API
      throw Exception('Errore LiveScore API: $e');
    }
  }

  Future<List<Fixture>> getLiveByIds(List<int> fixtureIds) async {
    print('HybridFootballService: Recupero partite live per IDs specifici da LiveScore API: $fixtureIds');
    try {
      // Recupera tutte le partite live e filtra per ID
      final allLive = await _liveScoreApiService.getLiveMatches();
      final filtered = allLive.where((f) => fixtureIds.contains(f.id)).toList();
      print('HybridFootballService: Filtrate ${filtered.length} partite live per IDs specifici da LiveScore API');
      return filtered;
    } catch (e) {
      print('HybridFootballService: ERRORE LiveScore API durante getLiveByIds: $e');
      // NON utilizzare fallback - solo LiveScore API
      throw Exception('Errore LiveScore API: $e');
    }
  }

  Future<bool> testConnection() async {
    print('HybridFootballService: Test connessione SOLO a LiveScore API...');
    try {
      return await _liveScoreApiService.testConnection();
    } catch (e) {
      print('HybridFootballService: Errore durante test connessione LiveScore API: $e');
      return false;
    }
  }
}