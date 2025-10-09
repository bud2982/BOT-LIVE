import 'package:live_bot/models/fixture.dart';

void main() {
  print('Test parsing Fixture con formato LiveScore...');
  
  // Simula i dati che arrivano dal proxy server
  final testData = {
    "id": 1,
    "home": "AC Milan",
    "away": "Juventus",
    "goalsHome": 1,
    "goalsAway": 2,
    "start": "2025-10-06T15:00:00Z",
    "elapsed": 45,
    "league": "Serie A",
    "country": "Italy"
  };
  
  try {
    final fixture = Fixture.fromJson(testData);
    print('✅ Parsing riuscito!');
    print('   ID: ${fixture.id}');
    print('   Casa: ${fixture.home}');
    print('   Ospite: ${fixture.away}');
    print('   Gol: ${fixture.goalsHome}-${fixture.goalsAway}');
    print('   Inizio: ${fixture.start}');
    print('   Minuti: ${fixture.elapsed}');
    print('   Lega: ${fixture.league}');
    print('   Paese: ${fixture.country}');
  } catch (e) {
    print('❌ Errore durante il parsing: $e');
  }
  
  print('\nTest con dati problematici dal proxy server...');
  
  // Simula i dati problematici che abbiamo visto
  final problematicData = {
    "id": 1,
    "home": "AC Milan drew",
    "away": "with Juventus on",
    "goalsHome": 0,
    "goalsAway": 0,
    "start": "2025-10-06T15:26:13.813Z",
    "elapsed": null,
    "league": "Various",
    "country": "Other"
  };
  
  try {
    final fixture = Fixture.fromJson(problematicData);
    print('✅ Parsing riuscito anche con dati problematici!');
    print('   Casa: "${fixture.home}"');
    print('   Ospite: "${fixture.away}"');
    print('   Lega: "${fixture.league}"');
  } catch (e) {
    print('❌ Errore con dati problematici: $e');
  }
}