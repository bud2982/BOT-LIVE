import 'package:live_bot/services/api_football_service.dart';

void main() async {
  print('=== INIZIO RECUPERO PARTITE LIVE ===');
  
  // Inizializza i servizi con la chiave API e usa dati reali
  print('Inizializzazione servizi...');
  final apiService = ApiFootballService(
    '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f', 
    useSampleData: false,
    useRealisticSimulation: false
  );
  
  // Test connessione API
  print('Test connessione API...');
  final isConnected = await apiService.testConnection();
  if (!isConnected) {
    print('ERRORE: Impossibile connettersi all\'API. Verifica la tua connessione internet e la chiave API.');
    return;
  }
  print('Connessione API riuscita!');
  
  // Recupera le partite di oggi
  print('Recupero partite di oggi...');
  final fixtures = await apiService.getFixturesToday();
  print('Partite recuperate: ${fixtures.length}');
  
  if (fixtures.isEmpty) {
    print('Nessuna partita trovata per oggi.');
    return;
  }
  
  // Ottieni gli ID di tutte le partite
  final allFixtureIds = fixtures.map((f) => f.id).toList();
  print('ID partite di oggi: $allFixtureIds');
  
  // Recupera i dati live per tutte le partite
  print('Recupero dati live per tutte le partite...');
  final liveFixtures = await apiService.getLiveByIds(allFixtureIds);
  print('Partite live recuperate: ${liveFixtures.length}');
  
  // Mostra dettagli delle partite live
  print('\n=== DETTAGLI PARTITE LIVE ===');
  if (liveFixtures.isEmpty) {
    print('Nessuna partita live al momento.');
  } else {
    for (final fixture in liveFixtures) {
      print('ID: ${fixture.id}');
      print('Partita: ${fixture.home} - ${fixture.away}');
      print('Minuto: ${fixture.elapsed ?? "N/A"}');
      print('Risultato: ${fixture.goalsHome}-${fixture.goalsAway}');
      print('Orario inizio: ${fixture.start}');
      print('----------------------------');
    }
  }
  
  // Mostra anche tutte le partite di oggi (non solo quelle live)
  print('\n=== TUTTE LE PARTITE DI OGGI ===');
  for (final fixture in fixtures) {
    print('ID: ${fixture.id}');
    print('Partita: ${fixture.home} - ${fixture.away}');
    print('Orario inizio: ${fixture.start}');
    print('----------------------------');
  }
  
  print('=== FINE RECUPERO PARTITE LIVE ===');
}