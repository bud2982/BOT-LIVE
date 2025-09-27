import 'dart:async';
import 'package:live_bot/services/api_football_service.dart';
import 'package:live_bot/services/local_notif_service.dart';
import 'package:live_bot/controllers/monitor_controller.dart';

void main() async {
  print('=== INIZIO TEST MONITORAGGIO ===');
  
  // Inizializza i servizi con la nuova chiave API
  print('Inizializzazione servizi...');
  final apiService = ApiFootballService('579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f', useSampleData: false);
  final notifService = LocalNotifService();
  
  // Inizializza il servizio di notifica
  await notifService.init();
  
  // Recupera le partite di oggi
  print('Recupero partite di oggi...');
  final fixtures = await apiService.getFixturesToday();
  print('Partite recuperate: ${fixtures.length}');
  
  // Seleziona le prime 3 partite (se disponibili)
  final selectedFixtures = fixtures.take(3).map((f) => f.id).toList();
  print('Partite selezionate: $selectedFixtures');
  
  // Inizializza il controller di monitoraggio
  final monitorController = MonitorController(
    api: apiService,
    notif: notifService,
    selected: selectedFixtures.toSet(),
    intervalMinutes: 1, // Usa 1 minuto per il test
  );
  
  print('Avvio monitoraggio...');
  monitorController.start();
  print('Monitoraggio avviato');
  
  // Simula l'esecuzione per 60 secondi
  print('Test in esecuzione per 60 secondi...');
  await Future.delayed(const Duration(seconds: 60));
  
  // Ferma il monitoraggio
  print('Arresto monitoraggio...');
  monitorController.stop();
  print('Monitoraggio arrestato');
  
  print('=== FINE TEST MONITORAGGIO ===');
}