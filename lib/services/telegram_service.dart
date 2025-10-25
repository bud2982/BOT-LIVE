import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class TelegramService {
  static const String baseUrl = 'https://bot-live-proxy.onrender.com';
  
  /// Registra una sottoscrizione per le notifiche di una partita
  Future<bool> subscribeToMatch({
    required String chatId,
    required int matchId,
    required Fixture matchInfo,
  }) async {
    try {
      print('📱 Registrazione sottoscrizione Telegram per partita $matchId...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/telegram/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'chatId': chatId,
          'matchId': matchId,
          'matchInfo': {
            'home': matchInfo.home,
            'away': matchInfo.away,
            'league': matchInfo.league,
            'country': matchInfo.country,
            'start': matchInfo.start.toIso8601String(),
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Sottoscrizione registrata con successo');
          return true;
        }
      }
      
      print('❌ Errore nella registrazione sottoscrizione: ${response.statusCode}');
      return false;
      
    } catch (e) {
      print('💥 Errore TelegramService subscribe: $e');
      return false;
    }
  }
  
  /// Invia una notifica Telegram con retry automatico
  Future<bool> sendNotification({
    required String chatId,
    required String message,
    int? matchId,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📤 Invio notifica Telegram (tentativo $attempt/$maxRetries)...');
        print('   Chat ID: $chatId');
        print('   Match ID: $matchId');
        print('   Messaggio (primi 100 caratteri): ${message.substring(0, message.length > 100 ? 100 : message.length)}');
        
        final requestBody = {
          'chatId': chatId,
          'message': message,
          if (matchId != null) 'matchId': matchId,
        };
        
        // Timeout progressivo: 15s, 20s, 30s
        final timeoutDuration = Duration(seconds: 10 + (attempt * 5));
        print('   Timeout: ${timeoutDuration.inSeconds}s');
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/telegram/notify'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'BOT-LIVE-App/1.0',
          },
          body: json.encode(requestBody),
        ).timeout(timeoutDuration);

        print('   Status code risposta: ${response.statusCode}');
        print('   Body risposta: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            print('✅ Notifica inviata con successo al tentativo $attempt');
            return true;
          } else {
            print('❌ Risposta negativa dal server: ${data['error']}');
            if (attempt == maxRetries) return false;
          }
        } else if (response.statusCode >= 500) {
          // Errore server, riprova
          print('⚠️ Errore server (${response.statusCode}), riprovo...');
          if (attempt == maxRetries) return false;
        } else {
          // Errore client, non riprovare
          print('❌ Errore client (${response.statusCode}): ${response.body}');
          return false;
        }
        
      } catch (e, stackTrace) {
        print('💥 Errore TelegramService notify (tentativo $attempt): $e');
        
        if (attempt == maxRetries) {
          print('❌ Tutti i tentativi falliti. Stack trace: $stackTrace');
          return false;
        } else {
          print('⏳ Attendo prima del prossimo tentativo...');
          await Future.delayed(Duration(seconds: attempt * 2)); // 2s, 4s, 6s
        }
      }
    }
    
    return false;
  }
  
  /// Crea un messaggio di notifica per l'inizio di una partita
  String createMatchStartMessage(Fixture match) {
    return '''
🏈 PARTITA INIZIATA!

${match.home} vs ${match.away}
🏆 ${match.league}
🌍 ${match.country}
⏰ ${_formatDateTime(match.start)}

Segui la partita in diretta! ⚽
''';
  }
  
  /// Crea un messaggio di notifica per un goal
  String createGoalMessage(Fixture match, String team, String scorer) {
    return '''
⚽ GOOOOOL!

${match.home} ${match.goalsHome} - ${match.goalsAway} ${match.away}
🎯 Goal di $scorer ($team)
🏆 ${match.league}
${match.elapsed != null ? '⏱️ ${match.elapsed}\'' : ''}

Che partita! 🔥
''';
  }
  
  /// Crea un messaggio di notifica per la fine di una partita
  String createMatchEndMessage(Fixture match) {
    return '''
🏁 PARTITA TERMINATA!

${match.home} ${match.goalsHome} - ${match.goalsAway} ${match.away}
🏆 ${match.league}
🌍 ${match.country}

${_getMatchResult(match)} 🎉
''';
  }
  
  /// Crea un messaggio di promemoria pre-partita
  String createMatchReminderMessage(Fixture match, int minutesUntilStart) {
    return '''
⏰ PROMEMORIA PARTITA

${match.home} vs ${match.away}
🏆 ${match.league}
🌍 ${match.country}

⏰ Inizia tra $minutesUntilStart minuti
📅 ${_formatDateTime(match.start)}

Non perdertela! ⚽
''';
  }
  
  /// Formatta data e ora per i messaggi
  String _formatDateTime(DateTime dateTime) {
    // Converte da UTC a UTC+2 (ora italiana)
    final italianTime = dateTime.add(const Duration(hours: 2));
    return '${italianTime.day.toString().padLeft(2, '0')}/'
           '${italianTime.month.toString().padLeft(2, '0')}/'
           '${italianTime.year} '
           '${italianTime.hour.toString().padLeft(2, '0')}:'
           '${italianTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Determina il risultato della partita
  String _getMatchResult(Fixture match) {
    if (match.goalsHome > match.goalsAway) {
      return 'Vittoria ${match.home}!';
    } else if (match.goalsAway > match.goalsHome) {
      return 'Vittoria ${match.away}!';
    } else {
      return 'Pareggio!';
    }
  }
}