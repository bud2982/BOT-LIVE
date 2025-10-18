import 'dart:io';
import 'lib/services/followed_matches_service.dart';
import 'lib/services/hybrid_football_service.dart';
import 'lib/services/telegram_service.dart';
import 'lib/models/fixture.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🔍 DEBUG: PARTITE SEGUITE E NOTIFICHE TELEGRAM');
  print('=' * 80);
  
  final followedService = FollowedMatchesService();
  final footballService = HybridFootballService();
  final telegramService = TelegramService();
  
  try {
    // STEP 1: Verifica partite seguite
    print('\n📋 STEP 1: VERIFICA PARTITE SEGUITE');
    print('-' * 50);
    
    final followedMatches = await followedService.getFollowedMatches();
    print('✅ Partite seguite trovate: ${followedMatches.length}');
    
    if (followedMatches.isEmpty) {
      print('❌ PROBLEMA: Nessuna partita seguita!');
      print('   Soluzione: Aggiungi alcune partite dalla home screen');
      
      // Aggiungiamo una partita live per test
      print('\n🔧 Aggiunta partita live per test...');
      final liveMatches = await footballService.getLiveMatches();
      if (liveMatches.isNotEmpty) {
        final testMatch = liveMatches.first;
        await followedService.followMatch(testMatch);
        print('✅ Aggiunta partita di test: ${testMatch.home} vs ${testMatch.away}');
        
        // Ricarica le partite seguite
        final updatedFollowed = await followedService.getFollowedMatches();
        print('✅ Partite seguite aggiornate: ${updatedFollowed.length}');
      }
    } else {
      for (final match in followedMatches) {
        print('   📍 ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}');
        print('      Lega: ${match.league}');
        print('      Elapsed: ${match.elapsed ?? "N/A"}');
        print('      Start: ${match.start}');
        print('      ID: ${match.id}');
      }
    }
    
    // STEP 2: Test aggiornamento risultati live
    print('\n🔄 STEP 2: TEST AGGIORNAMENTO RISULTATI LIVE');
    print('-' * 50);
    
    final currentFollowed = await followedService.getFollowedMatches();
    List<Fixture> updatedMatches = [];
    if (currentFollowed.isNotEmpty) {
      final followedIds = currentFollowed.map((m) => m.id).toList();
      print('📋 IDs partite da aggiornare: $followedIds');
      
      // Test del metodo getLiveByIds
      print('\n🔍 Test getLiveByIds...');
      updatedMatches = await footballService.getLiveByIds(followedIds);
      print('✅ Partite aggiornate ricevute: ${updatedMatches.length}');
      
      if (updatedMatches.isEmpty) {
        print('❌ PROBLEMA: getLiveByIds non restituisce dati!');
        print('   Possibili cause:');
        print('   - Le partite seguite non sono più live');
        print('   - Problema con l\'API LiveScore');
        print('   - IDs non validi');
        
        // Test alternativo: cerca nelle partite live generali
        print('\n🔍 Test alternativo: cerca nelle partite live generali...');
        final allLive = await footballService.getLiveMatches();
        print('✅ Partite live totali: ${allLive.length}');
        
        final matchingLive = allLive.where((live) => followedIds.contains(live.id)).toList();
        print('✅ Partite seguite che sono live: ${matchingLive.length}');
        
        for (final match in matchingLive) {
          print('   🔴 LIVE: ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away} (${match.elapsed ?? "N/A"}\')');
        }
      } else {
        print('\n📊 RISULTATI AGGIORNATI:');
        for (final match in updatedMatches) {
          print('   ✅ ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}');
          print('      Elapsed: ${match.elapsed ?? "N/A"}');
          print('      ID: ${match.id}');
        }
        
        // Confronta con i dati originali
        print('\n🔍 CONFRONTO CON DATI ORIGINALI:');
        for (final original in currentFollowed) {
          final updated = updatedMatches.firstWhere(
            (u) => u.id == original.id,
            orElse: () => original,
          );
          
          if (updated.goalsHome != original.goalsHome || 
              updated.goalsAway != original.goalsAway ||
              updated.elapsed != original.elapsed) {
            print('   🔄 CAMBIAMENTO RILEVATO:');
            print('      Originale: ${original.home} ${original.goalsHome}-${original.goalsAway} ${original.away} (${original.elapsed ?? "N/A"}\')');
            print('      Aggiornato: ${updated.home} ${updated.goalsHome}-${updated.goalsAway} ${updated.away} (${updated.elapsed ?? "N/A"}\')');
          } else {
            print('   ℹ️ Nessun cambiamento: ${original.home} vs ${original.away}');
          }
        }
      }
    }
    
    // STEP 3: Test configurazione Telegram
    print('\n📱 STEP 3: TEST CONFIGURAZIONE TELEGRAM');
    print('-' * 50);
    
    final prefs = await SharedPreferences.getInstance();
    final chatId = prefs.getString('telegram_chat_id');
    final botToken = prefs.getString('telegram_bot_token');
    
    print('Chat ID configurato: ${chatId ?? "NON CONFIGURATO"}');
    print('Bot Token configurato: ${botToken != null ? "SÌ (${botToken.substring(0, 10)}...)" : "NON CONFIGURATO"}');
    
    if (chatId == null || chatId.isEmpty) {
      print('❌ PROBLEMA: Chat ID Telegram non configurato!');
      print('   Soluzione: Vai in Impostazioni > Configura Telegram');
    } else {
      // Test invio notifica
      print('\n📤 Test invio notifica Telegram...');
      
      final testMessage = '''
🧪 TEST NOTIFICA BOT LIVE

Questo è un messaggio di test per verificare che le notifiche Telegram funzionino correttamente.

⏰ ${DateTime.now()}
🤖 Sistema: Operativo
''';
      
      final success = await telegramService.sendNotification(
        chatId: chatId,
        message: testMessage,
        matchId: 999999, // ID di test
      );
      
      if (success) {
        print('✅ Notifica di test inviata con successo!');
        print('   Controlla il tuo bot Telegram per vedere il messaggio');
      } else {
        print('❌ PROBLEMA: Invio notifica fallito!');
        print('   Possibili cause:');
        print('   - Chat ID non valido');
        print('   - Bot non configurato correttamente');
        print('   - Problemi di connessione al server proxy');
      }
    }
    
    // STEP 4: Test condizioni notifiche automatiche
    print('\n🔔 STEP 4: TEST CONDIZIONI NOTIFICHE AUTOMATICHE');
    print('-' * 50);
    
    if (chatId != null && chatId.isNotEmpty) {
      // Simula una partita 0-0 dopo 8 minuti
      final testMatch = Fixture(
        id: 999999,
        home: 'Test Team A',
        away: 'Test Team B',
        league: 'Test League',
        country: 'Test Country',
        start: DateTime.now().subtract(const Duration(minutes: 10)),
        goalsHome: 0,
        goalsAway: 0,
        elapsed: 8,
      );
      
      print('🧪 Simulazione partita 0-0 dopo 8 minuti...');
      print('   ${testMatch.home} ${testMatch.goalsHome}-${testMatch.goalsAway} ${testMatch.away}');
      print('   Elapsed: ${testMatch.elapsed}');
      
      // Test condizione 1: 0-0 dopo 8 minuti
      if (testMatch.goalsHome == 0 && testMatch.goalsAway == 0 && testMatch.elapsed! >= 8) {
        print('✅ CONDIZIONE 1 SODDISFATTA: 0-0 dopo 8 minuti');
        
        final alertMessage = '''
⚽ ALERT SCOMMESSE - 0-0 dopo 8' (TEST)

${testMatch.home} 0 - 0 ${testMatch.away}
🏆 ${testMatch.league}
🌍 ${testMatch.country}
⏱️ ${testMatch.elapsed}' - Ancora 0-0!

💡 Suggerimento: Over 2.5 goals

🧪 Questo è un messaggio di test
''';
        
        final alertSuccess = await telegramService.sendNotification(
          chatId: chatId,
          message: alertMessage,
          matchId: testMatch.id,
        );
        
        if (alertSuccess) {
          print('✅ Alert di test inviato con successo!');
        } else {
          print('❌ Errore nell\'invio dell\'alert di test');
        }
      }
    }
    
    print('\n${'=' * 80}');
    print('🎯 RIEPILOGO DIAGNOSI:');
    print('   1. Partite seguite: ${currentFollowed.length}');
    print('   2. Aggiornamento live: ${updatedMatches.isNotEmpty ? "FUNZIONA" : "PROBLEMA"}');
    print('   3. Telegram configurato: ${chatId != null ? "SÌ" : "NO"}');
    print('   4. Test notifica: Controlla Telegram per i messaggi di test');
    print('=' * 80);
    
  } catch (e) {
    print('❌ ERRORE DURANTE IL DEBUG: $e');
    print('Stack trace: ${StackTrace.current}');
    exit(1);
  }
}