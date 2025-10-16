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
    print('HybridFootballService: Usando LiveScore API diretta...');
    try {
      // USA DIRETTAMENTE LIVESCORE API (il proxy restituisce solo 1 partita)
      final fixtures = await _liveScoreApiService.getFixturesToday();
      print('HybridFootballService: Recuperate ${fixtures.length} partite da LiveScore API');
      
      // Se LiveScore API non restituisce abbastanza partite, prova il proxy come fallback
      if (fixtures.length < 5) {
        print('HybridFootballService: Poche partite da LiveScore API, provo il proxy...');
        try {
          final proxyFixtures = await _testProxyService.getFixturesToday();
          if (proxyFixtures.length > fixtures.length) {
            print('HybridFootballService: Proxy ha più partite (${proxyFixtures.length}), uso quelle');
            return proxyFixtures;
          }
        } catch (proxyError) {
          print('HybridFootballService: Proxy fallito: $proxyError');
        }
      }
      
      return fixtures;
    } catch (e) {
      print('HybridFootballService: ERRORE LiveScore API in getFixturesToday: $e');
      print('HybridFootballService: Fallback a proxy server...');
      try {
        final fixtures = await _testProxyService.getFixturesToday();
        print('HybridFootballService: Recuperate ${fixtures.length} partite dal proxy server');
        return fixtures;
      } catch (e2) {
        print('HybridFootballService: ERRORE anche con proxy server: $e2');
        throw Exception('Errore sia LiveScore API che proxy: $e');
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
    print('HybridFootballService: Recupero partite per IDs specifici: $fixtureIds');
    try {
      // STRATEGIA DOPPIA: Cerca sia nelle partite live che in tutte le partite di oggi
      final List<Fixture> matchingFixtures = [];
      
      // TENTATIVO 1: Cerca nelle partite live
      try {
        final allLive = await _liveScoreApiService.getLiveMatches();
        final liveMatches = allLive.where((f) => fixtureIds.contains(f.id)).toList();
        matchingFixtures.addAll(liveMatches);
        print('HybridFootballService: Trovate ${liveMatches.length} partite live per IDs specifici');
      } catch (e) {
        print('HybridFootballService: Errore recupero partite live: $e');
      }
      
      // TENTATIVO 2: Cerca nelle partite di oggi (per quelle non ancora live o appena finite)
      try {
        final allToday = await _liveScoreApiService.getFixturesToday();
        final todayMatches = allToday.where((f) => fixtureIds.contains(f.id)).toList();
        
        // Aggiungi solo le partite che non sono già state trovate nelle live
        for (final match in todayMatches) {
          if (!matchingFixtures.any((m) => m.id == match.id)) {
            matchingFixtures.add(match);
          }
        }
        
        print('HybridFootballService: Trovate ${todayMatches.length} partite di oggi per IDs specifici');
      } catch (e) {
        print('HybridFootballService: Errore recupero partite di oggi: $e');
      }
      
      print('HybridFootballService: ✅ TOTALE partite trovate per IDs: ${matchingFixtures.length}');
      return matchingFixtures;
      
    } catch (e) {
      print('HybridFootballService: ERRORE durante getLiveByIds: $e');
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