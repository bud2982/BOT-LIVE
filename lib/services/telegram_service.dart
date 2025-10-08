import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class TelegramService {
  static const String baseUrl = 'http://localhost:3001';
  
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
  
  /// Invia una notifica Telegram
  Future<bool> sendNotification({
    required String chatId,
    required String message,
    int? matchId,
  }) async {
    try {
      print('📤 Invio notifica Telegram...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/telegram/notify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'chatId': chatId,
          'message': message,
          'matchId': matchId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Notifica inviata con successo');
          return true;
        }
      }
      
      print('❌ Errore nell\'invio notifica: ${response.statusCode}');
      return false;
      
    } catch (e) {
      print('💥 Errore TelegramService notify: $e');
      return false;
    }
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
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
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