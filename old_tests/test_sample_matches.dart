import 'dart:async';
import 'package:live_bot/services/api_football_service.dart';
import 'package:live_bot/services/local_notif_service.dart';
import 'package:live_bot/controllers/monitor_controller.dart';

void main() async {
  print('=== TEST PARTITE DI ESEMPIO ===');
  
  // Usa la chiave API predefinita dell'app
  const apiKey = '239a1e02def2d210a0829a958348c5f5';
  
  print('Inizializzazione servizio API con dati di esempio...');
  final apiService = ApiFootballService(apiKey, useSampleData: true);
  
  // Recupera le partite di esempio
  print('Recupero partite di esempio...');
  final fixtures = await apiService.getFixturesToday();
  print('Partite recuperate: ${fixtures.length}');
  
  if (fixtures.isEmpty) {
    print('Nessuna partita trovata.');
    return;
  }
  
  // Stampa tutte le partite
  print('\nElenco partite di esempio:');
  for (var i = 0; i < fixtures.length; i++) {
    final f = fixtures[i];
    print('${i+1}. ${f.home} vs ${f.away} - ID: ${f.id}');
  }
  
  // Seleziona tutte le partite per il monitoraggio
  final selectedFixtures = fixtures.map((f) => f.id).toList();
  print('\nPartite selezionate per monitoraggio: $selectedFixtures');
  
  // Inizializza il servizio di notifica
  print('\nInizializzazione servizio notifiche...');
  final notifService = LocalNotifService();
  await notifService.init();
  print('Servizio notifiche inizializzato');
  
  // Inizializza il controller di monitoraggio
  final monitorController = MonitorController(
    api: apiService, 
    notif: notifService, 
    selected: selectedFixtures.toSet(),
    intervalMinutes: 1, // Usa 1 minuto per il test
  );
  
  print('\nAvvio monitoraggio...');
  await monitorController.start();
  print('Monitoraggio avviato');
  
  // Recupera lo stato live delle partite selezionate
  print('\nRecupero stato live delle partite selezionate...');
  final liveFixtures = await apiService.getLiveByIds(selectedFixtures);
  print('Partite live recuperate: ${liveFixtures.length}');
  
  // Stampa i dettagli delle partite live
  print('\nDettagli partite live:');
  for (var f in liveFixtures) {
    print('ID: ${f.id} - ${f.home} ${f.goalsHome} - ${f.goalsAway} ${f.away} (Minuto: ${f.elapsed ?? "N/A"})');
  }
  
  // Simula l'esecuzione per 60 secondi
  print('\nTest in esecuzione per 60 secondi...');
  print('Durante questo periodo, dovresti ricevere notifiche per le partite che sono 0-0 all\'8° minuto');
  await Future.delayed(const Duration(seconds: 60));
  
  // Ferma il monitoraggio
  print('Arresto monitoraggio...');
  monitorController.stop();
  print('Monitoraggio arrestato');
  
  print('\n=== TEST COMPLETATO ===');
}