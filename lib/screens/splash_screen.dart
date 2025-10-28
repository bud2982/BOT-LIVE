import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notif_service.dart';
import '../services/followed_matches_updater.dart';
import '../services/followed_matches_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isInitializing = true;
  String _statusMessage = 'Inizializzazione...';
  bool _hasError = false;
  late FollowedMatchesUpdater _followedMatchesUpdater;
  
  @override
  void initState() {
    super.initState();
    
    // Configura l'animazione
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.repeat(reverse: true);
    
    // Inizializza l'app
    _init();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    // Ferma il servizio di aggiornamento quando l'app viene chiusa
    try {
      _followedMatchesUpdater.dispose();
      print('✅ Servizio aggiornamento partite seguite fermato');
    } catch (e) {
      print('⚠️ Errore nel fermo del servizio aggiornamento: $e');
    }
    super.dispose();
  }

  Future<void> _init() async {
    print('SplashScreen._init() chiamato');
    
    try {
      // Inizializza il servizio di notifica
      _updateStatus('Inizializzazione notifiche...');
      final notifService = LocalNotifService();
      await notifService.init();
      
      // Carica le preferenze
      _updateStatus('Caricamento preferenze...');
      final prefs = await SharedPreferences.getInstance();
      
      // Imposta l'intervallo predefinito se non è già impostato
      final intervalMin = prefs.getInt('interval_min');
      if (intervalMin == null) {
        print('Impostazione intervallo predefinito: 1 minuto');
        await prefs.setInt('interval_min', 1);
        print('Intervallo predefinito salvato nelle preferenze');
      } else {
        print('Intervallo dalle preferenze: $intervalMin minuti');
      }
      
      // Forza l'uso di dati reali (scraping)
      print('Configurazione per uso dati reali tramite scraping');
      await prefs.setBool('use_sample_data', false);
      print('Flag per dati di esempio impostato a false');
      
      // Migra i vecchi timestamp salvati in locale
      print('Esecuzione migrazione dati timestamp...');
      final followedService = FollowedMatchesService();
      await followedService.migrateOldData();
      
      // Inizializza il servizio di aggiornamento automatico delle partite seguite
      print('Inizializzazione servizio aggiornamento partite seguite...');
      _followedMatchesUpdater = FollowedMatchesUpdater();
      _followedMatchesUpdater.startAutoUpdate(intervalSeconds: 30); // Aggiorna ogni 30 secondi
      print('✅ Servizio aggiornamento partite seguite avviato (ogni 30 secondi)');
      
      // Breve ritardo per mostrare l'animazione
      _updateStatus('Avvio applicazione...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Inizializzazione completata, navigazione alla home screen...');
      if (!mounted) {
        print('Widget non più montato, navigazione annullata');
        return;
      }
      
      Navigator.of(context).pushReplacementNamed('/home');
      print('Navigazione alla home screen completata');
    } catch (e) {
      print('Errore durante l\'inizializzazione: $e');
      print('Stack trace: ${e.toString()}');
      
      // Mostra l'errore all'utente
      _setError('Errore: ${e.toString()}');
      
      // Attendi che l'utente veda l'errore
      await Future.delayed(const Duration(seconds: 3));
      
      // In caso di errore, tenta comunque di navigare alla home screen
      if (!mounted) {
        print('Widget non più montato dopo errore, navigazione annullata');
        return;
      }
      
      print('Tentativo di navigazione alla home screen dopo errore...');
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  
  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
    print('Stato: $message');
  }
  
  void _setError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _statusMessage = message;
        _isInitializing = false;
      });
    }
    print('ERRORE: $message');
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icona
              ScaleTransition(
                scale: _animation,
                child: const Icon(
                  Icons.sports_soccer,
                  size: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Titolo
              const Text(
                'LIVE BOT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sottotitolo
              const Text(
                'Football Alerts',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              
              // Indicatore di caricamento
              if (_isInitializing)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              
              const SizedBox(height: 16),
              
              // Messaggio di stato
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: _hasError ? Colors.red.shade300 : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Pulsante di riavvio in caso di errore
              if (_hasError) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isInitializing = true;
                      _statusMessage = 'Riavvio in corso...';
                    });
                    _init();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade900,
                  ),
                  child: const Text('Riprova'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
