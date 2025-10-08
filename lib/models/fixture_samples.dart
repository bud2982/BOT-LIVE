import 'fixture.dart';

class FixtureSamples {
  static List<Fixture> getSampleFixtures() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Fixture(
        id: 1001,
        home: 'Real Madrid',
        away: 'Barcelona',
        start: today.add(const Duration(hours: 20, minutes: 45)),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
      ),
      Fixture(
        id: 1002,
        home: 'Manchester United',
        away: 'Liverpool',
        start: today.add(const Duration(hours: 16, minutes: 30)),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
      ),
      Fixture(
        id: 1003,
        home: 'Bayern Munich',
        away: 'Borussia Dortmund',
        start: today.add(const Duration(hours: 18, minutes: 15)),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
      ),
      Fixture(
        id: 1004,
        home: 'Juventus',
        away: 'AC Milan',
        start: today.add(const Duration(hours: 20, minutes: 45)),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
      ),
      Fixture(
        id: 1005,
        home: 'PSG',
        away: 'Marseille',
        start: today.add(const Duration(hours: 21, minutes: 0)),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
      ),
    ];
  }

  static List<Fixture> getSampleLiveFixtures(List<int> ids) {
    // Rimuovo la variabile 'now' non utilizzata
    final fixtures = getSampleFixtures();
    
    print('Generazione partite live di esempio per IDs: $ids');
    
    // Simula partite in corso con minuti casuali e risultati
    final result = fixtures
        .where((f) => ids.contains(f.id))
        .map((f) {
          print('Creazione partita live di esempio: ${f.home} vs ${f.away}');
          // Simula una partita in corso
          return Fixture(
            id: f.id,
            home: f.home,
            away: f.away,
            start: f.start,
            elapsed: 8, // Imposta a 8 minuti per testare la notifica
            goalsHome: 0, // Mantiene 0-0 per testare la notifica
            goalsAway: 0,
          );
        })
        .toList();
        
    print('Partite live generate: ${result.length}');
    return result;
  }
}