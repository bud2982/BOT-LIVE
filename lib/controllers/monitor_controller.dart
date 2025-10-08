import 'dart:async';
import '../services/hybrid_football_service.dart';
import '../services/local_notif_service.dart';
import '../models/fixture.dart';

class MonitorController {
  final HybridFootballService api;
  final LocalNotifService notif;
  final Set<int> selected; // fixture IDs
  final Set<int> notified = {};
  final int intervalMinutes;
  Timer? _timer;
  bool _isRunning = false;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 5;

  MonitorController({
    required this.api,
    required this.notif,
    required this.selected,
    this.intervalMinutes = 1,
  });

  bool get isRunning => _isRunning;
  
  Future<void> start() async {
    print('MonitorController.start() chiamato');
    
    if (_isRunning) {
      print('Il monitoraggio è già in esecuzione, nessuna azione necessaria');
      return;
    }
    
    // Ferma eventuali timer precedenti
    stop();
    
    // Inizializza il servizio di notifica
    try {
      await notif.init();
    } catch (e) {
      print('Errore durante l\'inizializzazione del servizio di notifica: $e');
      print('Il monitoraggio continuerà comunque');
    }
    
    // Esegui immediatamente il primo tick
    print('Esecuzione primo tick...');
    await _tick();
    
    // Usa l'intervallo in minuti specificato
    final interval = Duration(minutes: intervalMinutes);
    print('Impostazione timer con intervallo: $interval');
    _timer = Timer.periodic(interval, (timer) async {
      print('Timer scattato: ${timer.tick}');
      await _tick();
    });
    
    _isRunning = true;
    _consecutiveErrors = 0;
    print('Timer avviato');
  }

  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _isRunning = false;
      print('Monitoraggio fermato');
    }
  }
  
  // Metodo per aggiungere una partita al monitoraggio
  void addFixture(int fixtureId) {
    if (fixtureId <= 0) {
      print('ID partita non valido: $fixtureId');
      return;
    }
    
    selected.add(fixtureId);
    print('Partita aggiunta al monitoraggio: $fixtureId');
    print('Partite attualmente monitorate: $selected');
  }
  
  // Metodo per rimuovere una partita dal monitoraggio
  void removeFixture(int fixtureId) {
    selected.remove(fixtureId);
    print('Partita rimossa dal monitoraggio: $fixtureId');
    print('Partite attualmente monitorate: $selected');
  }
  
  // Metodo per cancellare tutte le partite dal monitoraggio
  void clearFixtures() {
    selected.clear();
    print('Tutte le partite rimosse dal monitoraggio');
  }
  
  // Metodo per reimpostare le notifiche inviate
  void resetNotifications() {
    notified.clear();
    print('Reset delle notifiche completato');
  }

  Future<void> _tick() async {
    print('=== INIZIO CICLO DI MONITORAGGIO ===');
    if (selected.isEmpty) {
      print('Nessuna partita selezionata per il monitoraggio');
      return;
    }
    
    print('Partite selezionate per il monitoraggio: $selected');
    print('Intervallo di monitoraggio: $intervalMinutes minuti');
    
    try {
      print('Richiesta partite live...');
      final fixtures = await api.getLiveByIds(selected.toList());
      print('Monitoraggio: ${fixtures.length} partite in corso');
      
      // Reset del contatore degli errori consecutivi
      _consecutiveErrors = 0;
      
      if (fixtures.isEmpty) {
        print('Nessuna partita live trovata tra quelle selezionate');
      }
      
      await _processFixtures(fixtures);
    } catch (e) {
      // Log error but continue monitoring
      print('ERRORE durante il monitoraggio: $e');
      print('Stack trace: ${e.toString()}');
      
      // Incrementa il contatore degli errori consecutivi
      _consecutiveErrors++;
      
      // Se ci sono troppi errori consecutivi, ferma il monitoraggio
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        print('Troppi errori consecutivi ($_consecutiveErrors), il monitoraggio verrà fermato');
        stop();
        
        // Invia una notifica all'utente
        try {
          await notif.showAlert(
            id: 999999, // ID speciale per errore di monitoraggio
            title: 'Errore di Monitoraggio',
            body: 'Il monitoraggio è stato fermato a causa di errori ripetuti. Riavvia l\'app.',
          );
        } catch (notifError) {
          print('Errore durante l\'invio della notifica di errore: $notifError');
        }
      }
    } finally {
      print('=== FINE CICLO DI MONITORAGGIO ===');
    }
  }
  
  Future<void> _processFixtures(List<Fixture> fixtures) async {
    for (final f in fixtures) {
      final elapsed = f.elapsed ?? 0;
      final isZeroZero = f.goalsHome == 0 && f.goalsAway == 0;
      
      print('PARTITA LIVE: ${f.home} - ${f.away}, Minuto: $elapsed, Risultato: ${f.goalsHome}-${f.goalsAway}');
      
      if (isZeroZero && elapsed >= 8) {
        if (!notified.contains(f.id)) {
          print('CONDIZIONE SODDISFATTA! Invio notifica per: ${f.home} - ${f.away}');
          try {
            await notif.showAlert(
              id: f.id,
              title: '${f.home} - ${f.away}',
              body: 'Ancora 0-0 al minuto ${f.elapsed}? Over 2.5',
            );
            notified.add(f.id);
            print('Notifica inviata con successo per ID: ${f.id}');
          } catch (notifError) {
            print('ERRORE durante l\'invio della notifica: $notifError');
            print('Stack trace notifica: ${notifError.toString()}');
            // Aggiungiamo comunque l'ID alla lista dei notificati per evitare tentativi ripetuti
            notified.add(f.id);
            print('ID ${f.id} aggiunto alla lista dei notificati nonostante l\'errore');
          }
        } else {
          print('Notifica già inviata per questa partita (ID: ${f.id})');
        }
      } else {
        print('Condizione non soddisfatta: isZeroZero=$isZeroZero, elapsed=$elapsed, notified=${notified.contains(f.id)}');
      }
    }
  }
  
  // Metodo per ottenere lo stato attuale del monitoraggio
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'selectedFixtures': selected.toList(),
      'notifiedFixtures': notified.toList(),
      'intervalMinutes': intervalMinutes,
      'consecutiveErrors': _consecutiveErrors,
    };
  }
}
