import 'dart:io';
import 'lib/services/hybrid_football_service.dart';
import 'lib/services/telegram_service.dart';

void main() async {
  print('🔍 TEST: AGGIORNAMENTI LIVE E TELEGRAM');
  print('=' * 60);
  
  final footballService = HybridFootballService();
  final telegramService = TelegramService();
  
  try {
    // STEP 1: Test recupero partite live
    print('\n🔴 STEP 1: TEST PARTITE LIVE');
    print('-' * 40);
    
    final liveMatches = await footballService.getLiveMatches();
    print('✅ Partite live totali: ${liveMatches.length}');
    
    if (liveMatches.isEmpty) {
      print('❌ PROBLEMA: Nessuna partita live disponibile!');
      return;
    }
    
    // Mostra le prime 3 partite live
    final sampleMatches = liveMatches.take(3).toList();
    print('\n📋 Esempio partite live:');
    for (final match in sampleMatches) {
      print('   🔴 ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}');
      print('      ID: ${match.id}, Elapsed: ${match.elapsed ?? "N/A"}');
      print('      Lega: ${match.league}');
    }
    
    // STEP 2: Test getLiveByIds con IDs reali
    print('\n🔍 STEP 2: TEST getLiveByIds');
    print('-' * 40);
    
    final testIds = sampleMatches.map((m) => m.id).toList();
    print('📋 Test con IDs: $testIds');
    
    final updatedMatches = await footballService.getLiveByIds(testIds);
    print('✅ Partite aggiornate ricevute: ${updatedMatches.length}');
    
    if (updatedMatches.isEmpty) {
      print('❌ PROBLEMA: getLiveByIds non restituisce dati!');
      print('   Questo spiega perché le partite seguite non si aggiornano');
    } else {
      print('\n📊 CONFRONTO DATI:');
      for (int i = 0; i < sampleMatches.length; i++) {
        final original = sampleMatches[i];
        final updated = updatedMatches.firstWhere(
          (u) => u.id == original.id,
          orElse: () => original,
        );
        
        print('   Partita ${i + 1}:');
        print('     Originale: ${original.home} ${original.goalsHome}-${original.goalsAway} ${original.away} (${original.elapsed ?? "N/A"}\')');
        print('     Aggiornata: ${updated.home} ${updated.goalsHome}-${updated.goalsAway} ${updated.away} (${updated.elapsed ?? "N/A"}\')');
        
        if (updated.goalsHome != original.goalsHome || 
            updated.goalsAway != original.goalsAway ||
            updated.elapsed != original.elapsed) {
          print('     🔄 CAMBIAMENTO RILEVATO!');
        } else {
          print('     ℹ️ Nessun cambiamento');
        }
      }
    }
    
    // STEP 3: Test Telegram (senza SharedPreferences)
    print('\n📱 STEP 3: TEST TELEGRAM SERVICE');
    print('-' * 40);
    
    // Test con un chat ID di esempio (dovrai sostituirlo con quello reale)
    final testChatId = "123456789"; // Sostituisci con il tuo chat ID reale
    
    print('🧪 Test invio notifica Telegram...');
    print('   Chat ID di test: $testChatId');
    
    final testMessage = '''
🧪 TEST NOTIFICA BOT LIVE

Questo è un test per verificare il funzionamento delle notifiche Telegram.

⏰ ${DateTime.now()}
🤖 Sistema: Test in corso
🔧 Versione: Debug

Se ricevi questo messaggio, il sistema di notifiche funziona correttamente!
''';
    
    final success = await telegramService.sendNotification(
      chatId: testChatId,
      message: testMessage,
      matchId: 999999,
    );
    
    if (success) {
      print('✅ Test notifica completato con successo!');
      print('   Controlla il bot Telegram per vedere se hai ricevuto il messaggio');
    } else {
      print('❌ PROBLEMA: Test notifica fallito!');
      print('   Possibili cause:');
      print('   - Chat ID non valido (usa il tuo chat ID reale)');
      print('   - Bot Telegram non configurato');
      print('   - Problemi di connessione al server proxy');
    }
    
    // STEP 4: Test condizioni alert automatici
    print('\n🔔 STEP 4: TEST CONDIZIONI ALERT');
    print('-' * 40);
    
    // Cerca una partita 0-0 nelle live
    final zeroZeroMatches = liveMatches.where((m) => 
      m.goalsHome == 0 && m.goalsAway == 0 && (m.elapsed ?? 0) >= 8
    ).toList();
    
    print('🔍 Partite 0-0 dopo 8 minuti: ${zeroZeroMatches.length}');
    
    if (zeroZeroMatches.isNotEmpty) {
      final match = zeroZeroMatches.first;
      print('   ✅ CONDIZIONE ALERT SODDISFATTA:');
      print('      ${match.home} 0-0 ${match.away} (${match.elapsed}\')');
      
      final alertMessage = '''
⚽ ALERT SCOMMESSE - 0-0 dopo ${match.elapsed}'

${match.home} 0 - 0 ${match.away}
🏆 ${match.league}
🌍 ${match.country}
⏱️ ${match.elapsed}' - Ancora 0-0!

💡 Suggerimento: Over 2.5 goals

🔴 PARTITA LIVE - Situazione interessante!
''';
      
      print('📤 Invio alert di test...');
      final alertSuccess = await telegramService.sendNotification(
        chatId: testChatId,
        message: alertMessage,
        matchId: match.id,
      );
      
      if (alertSuccess) {
        print('✅ Alert inviato con successo!');
      } else {
        print('❌ Errore nell\'invio dell\'alert');
      }
    } else {
      print('   ℹ️ Nessuna partita 0-0 dopo 8 minuti al momento');
      print('   (Questo è normale, dipende dalle partite live attuali)');
    }
    
    print('\n' + '=' * 60);
    print('🎯 RIEPILOGO TEST:');
    print('   1. Partite live disponibili: ${liveMatches.length}');
    print('   2. getLiveByIds funziona: ${updatedMatches.isNotEmpty ? "SÌ" : "NO"}');
    print('   3. Telegram service: ${success ? "FUNZIONA" : "PROBLEMA"}');
    print('   4. Alert conditions: ${zeroZeroMatches.length} partite qualificate');
    print('');
    print('💡 NOTA: Per testare completamente Telegram,');
    print('   sostituisci testChatId con il tuo chat ID reale');
    print('=' * 60);
    
  } catch (e) {
    print('❌ ERRORE DURANTE IL TEST: $e');
    print('Stack trace: ${StackTrace.current}');
    exit(1);
  }
}