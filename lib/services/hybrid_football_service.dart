import 'package:live_bot/services/sofascore_scraper_service.dart';
import 'package:live_bot/models/fixture.dart';

class HybridFootballService {
  final SofaScoreScraperService _sofaScoreService;
  
  HybridFootballService({
    String? apiKey, // Manteniamo il parametro per retrocompatibilità ma lo ignoriamo
    bool useSampleData = false, // Impostiamo a false per preferire dati reali
  }) : 
    _sofaScoreService = SofaScoreScraperService(); // Modificato per preferire dati reali
  
  Future<List<Fixture>> getFixturesToday() async {
    print('HybridFootballService: Recupero partite di oggi...');
    try {
      // Prima prova con SofaScore
      print('HybridFootballService: Tentativo con SofaScore...');
      try {
        // Forziamo il recupero di dati reali
        print('HybridFootballService: Forzando recupero dati reali da SofaScore...');
        final fixtures = await _sofaScoreService.getFixturesToday();
        if (fixtures.isNotEmpty) {
          print('HybridFootballService: Recuperate ${fixtures.length} partite da SofaScore');
          return fixtures;
        } else {
          print('HybridFootballService: SofaScore non ha restituito partite');
        }
      } catch (e) {
        print('HybridFootballService: Errore durante il recupero da SofaScore: $e');
      }
      
      // Facciamo un secondo tentativo con SofaScore
      print('HybridFootballService: Secondo tentativo con SofaScore...');
      try {
        final fixtures = await _sofaScoreService.getFixturesToday();
        if (fixtures.isNotEmpty) {
          print('HybridFootballService: Recuperate ${fixtures.length} partite da SofaScore al secondo tentativo');
          return fixtures;
        }
      } catch (e) {
        print('HybridFootballService: Errore durante il secondo tentativo con SofaScore: $e');
      }
      
      // Solo come ultima risorsa, utilizziamo i dati di esempio
      print('HybridFootballService: Utilizzo dati di esempio come ultima risorsa');
      return _sofaScoreService.getSampleFixtures();
    } catch (e) {
      print('HybridFootballService: Errore generale in getFixturesToday: $e');
      // In caso di errore, usa i dati di esempio
      print('HybridFootballService: Utilizzo dati di esempio dopo errore');
      return _sofaScoreService.getSampleFixtures();
    }
  }
  
  Future<List<Fixture>> getLiveMatches() async {
    print('HybridFootballService: Recupero partite live...');
    try {
      // Prima prova con SofaScore
      print('HybridFootballService: Tentativo di recupero partite live da SofaScore...');
      try {
        // Forziamo il recupero di dati reali
        print('HybridFootballService: Forzando recupero dati live reali da SofaScore...');
        final fixtures = await _sofaScoreService.getLiveMatches();
        if (fixtures.isNotEmpty) {
          print('HybridFootballService: Recuperate ${fixtures.length} partite live da SofaScore');
          return fixtures;
        } else {
          print('HybridFootballService: SofaScore non ha restituito partite live');
        }
      } catch (e) {
        print('HybridFootballService: Errore durante il recupero partite live da SofaScore: $e');
      }
      
      // Facciamo un secondo tentativo con SofaScore
      print('HybridFootballService: Secondo tentativo di recupero partite live da SofaScore...');
      try {
        final fixtures = await _sofaScoreService.getLiveMatches();
        if (fixtures.isNotEmpty) {
          print('HybridFootballService: Recuperate ${fixtures.length} partite live da SofaScore al secondo tentativo');
          return fixtures;
        }
      } catch (e) {
        print('HybridFootballService: Errore durante il secondo tentativo di recupero partite live da SofaScore: $e');
      }
      
      // Solo come ultima risorsa, utilizziamo i dati di esempio
      print('HybridFootballService: Utilizzo dati di esempio come ultima risorsa per partite live');
      final sampleLive = _sofaScoreService.getSampleFixtures()
        .where((f) => f.elapsed != null)
        .toList();
      print('HybridFootballService: Trovate ${sampleLive.length} partite live di esempio');
      return sampleLive;
    } catch (e) {
      print('HybridFootballService: Errore generale in getLiveMatches: $e');
      // In caso di errore, usa i dati di esempio
      print('HybridFootballService: Utilizzo dati di esempio dopo errore per partite live');
      return _sofaScoreService.getSampleFixtures()
        .where((f) => f.elapsed != null)
        .toList();
    }
  }
}