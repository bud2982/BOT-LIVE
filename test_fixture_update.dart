import 'lib/models/fixture.dart';

void main() {
  print('🧪 Test 1: Verifica parsing data da JSON LiveScore format');
  testDateParsing();
  
  print('\n🧪 Test 2: Verifica copyWith preserva campo start');
  testCopyWithPreservesStart();
  
  print('\n🧪 Test 3: Simula aggiornamento live score');
  testLiveScoreUpdate();
}

void testDateParsing() {
  // Simula JSON dal server proxy LiveScore
  final json = {
    'id': 12345,
    'home': 'Inter',
    'away': 'Milan',
    'start': '2025-10-15T18:30:00Z', // UTC time
    'elapsed': null,
    'goalsHome': 0,
    'goalsAway': 0,
    'league': 'Serie A',
    'country': 'Italy',
  };
  
  final fixture = Fixture.fromJson(json);
  
  print('  📅 Data originale JSON: ${json['start']}');
  print('  📅 Data parsata: ${fixture.start}');
  print('  🕐 Ora: ${fixture.start.hour}:${fixture.start.minute.toString().padLeft(2, '0')}');
  
  if (fixture.start.hour == 0 && fixture.start.minute == 0) {
    print('  ❌ ERRORE: L\'orario è 00:00 - parsing fallito!');
  } else {
    print('  ✅ OK: L\'orario è stato parsato correttamente');
  }
}

void testCopyWithPreservesStart() {
  // Crea una partita con orario specifico
  final originalStart = DateTime(2025, 10, 15, 18, 30);
  final originalMatch = Fixture(
    id: 12345,
    home: 'Inter',
    away: 'Milan',
    start: originalStart,
    elapsed: null,
    goalsHome: 0,
    goalsAway: 0,
    league: 'Serie A',
    country: 'Italy',
  );
  
  print('  📅 Orario originale: ${originalMatch.start.hour}:${originalMatch.start.minute.toString().padLeft(2, '0')}');
  
  // Simula aggiornamento punteggio usando copyWith
  final updatedMatch = originalMatch.copyWith(
    goalsHome: 2,
    goalsAway: 1,
    elapsed: 45,
  );
  
  print('  📅 Orario dopo copyWith: ${updatedMatch.start.hour}:${updatedMatch.start.minute.toString().padLeft(2, '0')}');
  print('  ⚽ Punteggio aggiornato: ${updatedMatch.goalsHome}-${updatedMatch.goalsAway}');
  print('  ⏱️  Tempo: ${updatedMatch.elapsed}\'');
  
  if (updatedMatch.start == originalStart) {
    print('  ✅ OK: L\'orario è stato preservato correttamente');
  } else {
    print('  ❌ ERRORE: L\'orario è cambiato dopo copyWith!');
  }
}

void testLiveScoreUpdate() {
  // Simula partita seguita salvata in SharedPreferences
  final followedMatch = Fixture(
    id: 12345,
    home: 'Inter',
    away: 'Milan',
    start: DateTime(2025, 10, 15, 18, 30), // 18:30
    elapsed: null,
    goalsHome: 0,
    goalsAway: 0,
    league: 'Serie A',
    country: 'Italy',
  );
  
  print('  📅 Partita seguita - Orario: ${followedMatch.start.hour}:${followedMatch.start.minute.toString().padLeft(2, '0')}');
  print('  ⚽ Punteggio iniziale: ${followedMatch.goalsHome}-${followedMatch.goalsAway}');
  
  // Simula dati aggiornati dal server (potrebbe avere start errato o null)
  final serverJson = {
    'id': 12345,
    'home': 'Inter',
    'away': 'Milan',
    'start': '2025-10-15T00:00:00Z', // Server restituisce mezzanotte (ERRORE)
    'elapsed': 23,
    'goalsHome': 1,
    'goalsAway': 0,
    'league': 'Serie A',
    'country': 'Italy',
  };
  
  final updatedFromServer = Fixture.fromJson(serverJson);
  print('\n  🌐 Dati dal server - Orario: ${updatedFromServer.start.hour}:${updatedFromServer.start.minute.toString().padLeft(2, '0')}');
  print('  ⚽ Punteggio aggiornato: ${updatedFromServer.goalsHome}-${updatedFromServer.goalsAway}');
  print('  ⏱️  Tempo: ${updatedFromServer.elapsed}\'');
  
  // Applica la nostra soluzione: usa copyWith per preservare start
  final mergedMatch = followedMatch.copyWith(
    goalsHome: updatedFromServer.goalsHome,
    goalsAway: updatedFromServer.goalsAway,
    elapsed: updatedFromServer.elapsed,
  );
  
  print('\n  🔄 Dopo merge con copyWith:');
  print('  📅 Orario finale: ${mergedMatch.start.hour}:${mergedMatch.start.minute.toString().padLeft(2, '0')}');
  print('  ⚽ Punteggio finale: ${mergedMatch.goalsHome}-${mergedMatch.goalsAway}');
  print('  ⏱️  Tempo finale: ${mergedMatch.elapsed}\'');
  
  if (mergedMatch.start == followedMatch.start && 
      mergedMatch.goalsHome == updatedFromServer.goalsHome &&
      mergedMatch.elapsed == updatedFromServer.elapsed) {
    print('\n  ✅ OK: Orario preservato E punteggi aggiornati correttamente!');
  } else {
    print('\n  ❌ ERRORE: Qualcosa non ha funzionato nel merge');
  }
}