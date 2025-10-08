import 'package:live_bot/services/api_football_service.dart';

void main() async {
  print('=== TEST PARTITE LIVE ===');
  
  // Usa la chiave API predefinita dell'app
  const apiKey = '239a1e02def2d210a0829a958348c5f5';
  
  print('Inizializzazione servizio API con chiave: ${apiKey.substring(0, 5)}...');
  final apiService = ApiFootballService(
    apiKey, 
    useSampleData: false,
    useRealisticSimulation: true // Usa la simulazione realistica
  );
  
  // Test di connessione
  print('Test connessione API...');
  final isConnected = await apiService.testConnection();
  if (!isConnected) {
    print('ERRORE: Impossibile connettersi all\'API. Verifica la connessione internet e la chiave API.');
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
  
  // Stampa tutte le partite
  print('\nElenco partite di oggi:');
  for (var i = 0; i < fixtures.length; i++) {
    final f = fixtures[i];
    print('${i+1}. ${f.home} vs ${f.away} - Inizio: ${f.start.toString().substring(0, 16)}');
  }
  
  // Cerca partite che potrebbero essere in corso (iniziate nelle ultime 2 ore)
  final now = DateTime.now();
  final potentialLiveMatches = fixtures.where((f) {
    final timeDiff = now.difference(f.start);
    return timeDiff.inHours >= 0 && timeDiff.inHours < 2;
  }).toList();
  
  print('\nPartite potenzialmente in corso: ${potentialLiveMatches.length}');
  
  if (potentialLiveMatches.isEmpty) {
    print('Nessuna partita in corso al momento.');
    return;
  }
  
  // Stampa le partite potenzialmente in corso
  for (var i = 0; i < potentialLiveMatches.length; i++) {
    final f = potentialLiveMatches[i];
    print('${i+1}. ${f.home} vs ${f.away} - ID: ${f.id}');
  }
  
  // Seleziona le prime 3 partite (o meno se non ce ne sono abbastanza)
  final selectedFixtures = potentialLiveMatches.take(3).map((f) => f.id).toList();
  print('\nPartite selezionate per monitoraggio: $selectedFixtures');
  
  if (selectedFixtures.isEmpty) {
    print('Nessuna partita selezionata per il monitoraggio.');
    return;
  }
  
  // Recupera lo stato live delle partite selezionate
  print('\nRecupero stato live delle partite selezionate...');
  final liveFixtures = await apiService.getLiveByIds(selectedFixtures);
  print('Partite live recuperate: ${liveFixtures.length}');
  
  // Stampa i dettagli delle partite live
  print('\nDettagli partite live:');
  for (var f in liveFixtures) {
    print('ID: ${f.id} - ${f.home} ${f.goalsHome} - ${f.goalsAway} ${f.away} (Minuto: ${f.elapsed ?? "N/A"})');
  }
  
  print('\n=== TEST COMPLETATO ===');
}