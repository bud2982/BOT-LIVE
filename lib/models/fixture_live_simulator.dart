import 'dart:math';
import 'fixture.dart';

/// Classe per simulare partite live con dati più realistici
class FixtureLiveSimulator {
  // Mappa per tenere traccia dello stato delle partite
  static final Map<int, _LiveMatchState> _matchStates = {};
  
  /// Genera partite live simulate con dati realistici
  static List<Fixture> getRealisticLiveFixtures(List<int> ids, List<Fixture> baseFixtures) {
    print('Generazione partite live realistiche per IDs: $ids');
    
    // Inizializza gli stati delle partite se non esistono
    for (final id in ids) {
      if (!_matchStates.containsKey(id)) {
        // Trova la fixture base corrispondente
        final baseFixture = baseFixtures.firstWhere(
          (f) => f.id == id,
          orElse: () => Fixture(
            id: id,
            home: 'Squadra $id-A',
            away: 'Squadra $id-B',
            start: DateTime.now().subtract(const Duration(minutes: 30)),
            goalsHome: 0,
            goalsAway: 0,
          ),
        );
        
        _matchStates[id] = _LiveMatchState(
          id: id,
          home: baseFixture.home,
          away: baseFixture.away,
          start: baseFixture.start,
          elapsed: 0,
          goalsHome: 0,
          goalsAway: 0,
          lastUpdate: DateTime.now(),
        );
      }
    }
    
    // Aggiorna gli stati delle partite
    _updateMatchStates();
    
    // Converti gli stati in oggetti Fixture
    final result = ids
        .where((id) => _matchStates.containsKey(id))
        .map((id) {
          final state = _matchStates[id]!;
          print('Partita live simulata: ${state.home} ${state.goalsHome}-${state.goalsAway} ${state.away} (Minuto: ${state.elapsed})');
          
          return Fixture(
            id: state.id,
            home: state.home,
            away: state.away,
            start: state.start,
            elapsed: state.elapsed,
            goalsHome: state.goalsHome,
            goalsAway: state.goalsAway,
          );
        })
        .toList();
    
    print('Partite live simulate generate: ${result.length}');
    return result;
  }
  
  /// Aggiorna gli stati delle partite in base al tempo trascorso
  static void _updateMatchStates() {
    final now = DateTime.now();
    final random = Random();
    
    for (final id in _matchStates.keys) {
      final state = _matchStates[id]!;
      
      // Calcola il tempo trascorso dall'ultimo aggiornamento
      final timeSinceLastUpdate = now.difference(state.lastUpdate).inSeconds;
      
      // Aggiorna i minuti trascorsi (1 minuto ogni 3 secondi per accelerare la simulazione)
      final minutesToAdd = timeSinceLastUpdate ~/ 3;
      if (minutesToAdd > 0) {
        state.elapsed += minutesToAdd;
        state.lastUpdate = now;
        
        // Limita i minuti a 90
        if (state.elapsed > 90) {
          state.elapsed = 90;
        }
        
        // Possibilità di gol in base ai minuti trascorsi
        if (state.elapsed >= 8) {
          // Dopo 8 minuti, c'è una possibilità di gol ad ogni aggiornamento
          if (random.nextInt(100) < 10) { // 10% di possibilità di gol
            // Decide quale squadra segna
            if (random.nextBool()) {
              state.goalsHome += 1;
              print('GOL! ${state.home} segna al minuto ${state.elapsed}');
            } else {
              state.goalsAway += 1;
              print('GOL! ${state.away} segna al minuto ${state.elapsed}');
            }
          }
        }
      }
    }
  }
  
  /// Resetta tutti gli stati delle partite
  static void resetAllMatches() {
    _matchStates.clear();
    print('Stati delle partite resettati');
  }
}

/// Classe interna per tenere traccia dello stato di una partita live
class _LiveMatchState {
  final int id;
  final String home;
  final String away;
  final DateTime start;
  int elapsed;
  int goalsHome;
  int goalsAway;
  DateTime lastUpdate;
  
  _LiveMatchState({
    required this.id,
    required this.home,
    required this.away,
    required this.start,
    required this.elapsed,
    required this.goalsHome,
    required this.goalsAway,
    required this.lastUpdate,
  });
}