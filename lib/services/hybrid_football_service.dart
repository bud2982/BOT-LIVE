import 'package:live_bot/services/sofascore_scraper_service.dart';
import 'package:live_bot/services/api_football_service.dart';
import 'package:live_bot/models/fixture.dart';

class HybridFootballService {
  final SofaScoreScraperService _sofaScoreService;
  final ApiFootballService? _apiService;
  final bool _useSampleData;
  
  HybridFootballService({
    String? apiKey,
    bool useSampleData = true,
  }) : 
    _sofaScoreService = SofaScoreScraperService(),
    _apiService = apiKey != null ? ApiFootballService(apiKey, useSampleData: false) : null,
    _useSampleData = useSampleData;
  
  Future<List<Fixture>> getFixturesToday() async {
    try {
      // Prima prova con SofaScore
      final fixtures = await _sofaScoreService.getFixturesToday();
      if (fixtures.isNotEmpty) return fixtures;
      
      // Se SofaScore fallisce e abbiamo una API key, prova con API-Football
      if (_apiService != null) {
        try {
          final apiFixtures = await _apiService!.getFixturesToday();
          if (apiFixtures.isNotEmpty) return apiFixtures;
        } catch (e) {
          print('API-Football fallback fallito: $e');
        }
      }
      
      // Se tutto fallisce e i dati di esempio sono abilitati
      if (_useSampleData) {
        return _sofaScoreService.getSampleFixtures();
      }
      
      return [];
    } catch (e) {
      print('Error in getFixturesToday: $e');
      // In caso di errore, usa i dati di esempio se abilitati
      if (_useSampleData) {
        return _sofaScoreService.getSampleFixtures();
      }
      return [];
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    try {
      // Prima prova con SofaScore
      final fixtures = await _sofaScoreService.getLiveMatches();
      if (fixtures.isNotEmpty) return fixtures;
      
      // Se SofaScore fallisce e abbiamo una API key, prova con API-Football
      if (_apiService != null) {
        try {
          // Ottieni prima tutte le partite di oggi
          final allFixtures = await _apiService!.getFixturesToday();
          // Poi ottieni i dati live per queste partite
          if (allFixtures.isNotEmpty) {
            final fixtureIds = allFixtures.map((f) => f.id).toList();
            final liveFixtures = await _apiService!.getLiveByIds(fixtureIds);
            if (liveFixtures.isNotEmpty) return liveFixtures;
          }
        } catch (e) {
          print('API-Football fallback fallito: $e');
        }
      }
      
      // Se tutto fallisce e i dati di esempio sono abilitati
      if (_useSampleData) {
        return _sofaScoreService.getSampleFixtures()
          .where((f) => f.elapsed != null)
          .toList();
      }
      
      return [];
    } catch (e) {
      print('Error in getLiveMatches: $e');
      // In caso di errore, usa i dati di esempio se abilitati
      if (_useSampleData) {
        return _sofaScoreService.getSampleFixtures()
          .where((f) => f.elapsed != null)
          .toList();
      }
      return [];
    }
  }
}