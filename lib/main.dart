import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/live_matches_screen.dart';
import 'pages/country_matches_page.dart';
import 'pages/telegram_config_page.dart';
import 'pages/followed_matches_page.dart';
import 'pages/live_results_page.dart';
import 'pages/favorite_matches_page.dart';
import 'services/favorites_service.dart';

// Variabile globale per il logger
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Cattura gli errori non gestiti
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inizializza il servizio dei preferiti
    await FavoritesService.instance.initialize();
    
    // Imposta l'orientamento preferito
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Imposta lo stile della status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Configura FlutterError per catturare errori di Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('ERRORE FLUTTER: ${details.exception}');
      print('Stack trace: ${details.stack}');
      
      // Mostra un messaggio di errore all'utente se possibile
      _showErrorSnackBar('Si è verificato un errore nell\'applicazione');
    };
    
    // Avvia l'app
    runApp(const LiveBotApp());
  }, (error, stack) {
    // Gestisci gli errori non catturati
    print('ERRORE NON GESTITO: $error');
    print('Stack trace: $stack');
    
    // Mostra un messaggio di errore all'utente se possibile
    _showErrorSnackBar('Si è verificato un errore imprevisto');
  });
}

// Funzione per mostrare un messaggio di errore
void _showErrorSnackBar(String message) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

class LiveBotApp extends StatelessWidget {
  const LiveBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIVE BOT',
      navigatorKey: navigatorKey, // Usa la chiave globale per il navigator
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/live_matches': (_) => const LiveMatchesScreen(),
        '/country_matches': (_) => const CountryMatchesPage(),
        '/telegram_config': (_) => const TelegramConfigPage(),
        '/followed_matches': (_) => const FollowedMatchesPage(),
        '/live_results': (_) => LiveResultsPage(),
        '/favorite_matches': (_) => FavoriteMatchesPage(),
      },
      // Gestione degli errori nell'app
      builder: (context, child) {
        // Aggiungi un error boundary
        Widget errorScreen(FlutterErrorDetails details) {
          return Scaffold(
            appBar: AppBar(title: const Text('Errore')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Si è verificato un errore nell\'applicazione',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exceptionAsString(),
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      child: const Text('Riavvia applicazione'),
                    ),
                    const SizedBox(height: 8),
                    if (Platform.isAndroid || Platform.isIOS)
                      OutlinedButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: const Text('Chiudi applicazione'),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        ErrorWidget.builder = (FlutterErrorDetails details) {
          print('Errore UI: ${details.exception}');
          print('Stack trace: ${details.stack}');
          return errorScreen(details);
        };

        // Aggiungi un handler per gli errori di piattaforma
        WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
          print('ERRORE DI PIATTAFORMA: $error');
          print('Stack trace: $stack');
          return true;
        };

        if (child == null) {
          return const SizedBox.shrink();
        }
        
        // Avvolgi l'app in un error boundary
        return Material(
          type: MaterialType.transparency,
          child: child,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
