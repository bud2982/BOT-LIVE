import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class LocalNotifService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    print('LocalNotifService.init() chiamato');
    if (_initialized) {
      print('Servizio notifiche già inizializzato, skip');
      return;
    }
    
    try {
      // Usa un'icona generica per evitare problemi con ic_launcher
      const android = AndroidInitializationSettings('@drawable/notification_icon');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: android, iOS: ios);
      
      print('Inizializzazione plugin notifiche...');
      final success = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('Notifica ricevuta: ${details.payload}');
        },
      );
      
      if (success != null && success) {
        print('Plugin notifiche inizializzato con successo');
        _initialized = true;
      } else {
        print('Plugin notifiche inizializzato ma ha restituito null o false');
        // Consideriamo comunque inizializzato per evitare tentativi ripetuti
        _initialized = true;
      }

      // Su web, non possiamo richiedere permessi come su Android/iOS
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          print('Richiesta permessi Android...');
          try {
            final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
            final permissionGranted = await androidPlugin?.requestNotificationsPermission();
            print('Permessi Android richiesti, risultato: $permissionGranted');
            
            // Verifica se il canale di notifica esiste già
            await _createNotificationChannel();
          } catch (permissionError) {
            print('Errore durante la richiesta dei permessi Android: $permissionError');
            print('Continuazione dell\'esecuzione nonostante l\'errore dei permessi');
          }
        } else if (Platform.isIOS) {
          print('Verifica permessi iOS...');
          try {
            final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
            final permissionGranted = await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
            print('Permessi iOS richiesti, risultato: $permissionGranted');
          } catch (permissionError) {
            print('Errore durante la richiesta dei permessi iOS: $permissionError');
          }
        }
      }
    } catch (e) {
      print('Errore durante l\'inizializzazione delle notifiche: $e');
      print('Stack trace: ${e.toString()}');
      // Nonostante l'errore, impostiamo come inizializzato per evitare tentativi ripetuti
      _initialized = true;
    }
  }
  
  Future<void> _createNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
          
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'alerts_channel',
          'Football Alerts',
          description: 'Notifiche per partite di calcio',
          importance: Importance.high,
        ),
      );
      print('Canale di notifica creato con successo');
    } catch (e) {
      print('Errore durante la creazione del canale di notifica: $e');
    }
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    print('=== NOTIFICA ALERT ===');
    print('LocalNotifService.showAlert() chiamato: $title - $body');
    
    // Se non è stato inizializzato, inizializza prima
    if (!_initialized) {
      print('Servizio notifiche non inizializzato, inizializzazione on-demand');
      await init();
    }
    
    try {
      // Su web, le notifiche potrebbero non funzionare, quindi mostriamo un alert nella console
      if (kIsWeb) {
        print('');
        print('***************************************');
        print('*  NOTIFICA WEB: $title  *');
        print('*  $body  *');
        print('***************************************');
        print('');
        
        // Tentiamo comunque di mostrare la notifica
        try {
          const androidDetails = AndroidNotificationDetails(
            'alerts_channel',
            'Football Alerts',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@drawable/notification_icon',
          );
          const iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
          const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
          
          await _plugin.show(id, title, body, details, payload: 'fixture:$id');
        } catch (webError) {
          print('Errore specifico per web durante l\'invio della notifica: $webError');
          print('Questo è normale su piattaforma web a causa delle restrizioni del browser');
        }
      } else {
        // Per dispositivi mobili
        const androidDetails = AndroidNotificationDetails(
          'alerts_channel',
          'Football Alerts',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@drawable/notification_icon',
          channelShowBadge: true,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
        
        print('Invio notifica su dispositivo mobile...');
        await _plugin.show(id, title, body, details, payload: 'fixture:$id');
        print('Notifica inviata con ID: $id');
      }
    } catch (e) {
      print('Errore durante l\'invio della notifica: $e');
      print('Stack trace: ${e.toString()}');
    }
    print('=== FINE NOTIFICA ALERT ===');
  }
  
  // Metodo per cancellare tutte le notifiche
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      print('Tutte le notifiche cancellate');
    } catch (e) {
      print('Errore durante la cancellazione delle notifiche: $e');
    }
  }
  
  // Metodo per cancellare una notifica specifica
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      print('Notifica con ID $id cancellata');
    } catch (e) {
      print('Errore durante la cancellazione della notifica $id: $e');
    }
  }
}
