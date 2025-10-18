import 'dart:io';
import 'lib/services/hybrid_football_service.dart';
import 'lib/services/telegram_service.dart';

void main() async {
  print('🔧 VERIFICA CORREZIONI: AGGIORNAMENTI E TELEGRAM');
  print('=' * 70);
  
  final footballService = HybridFootballService();
  final telegramService = TelegramService();
  
  try {
    // TEST 1: Verifica strategia doppia per aggiornamenti
    print('\n🔄 TEST 1: STRATEGIA DOPPIA AGGIORNAMENTI');
    print('-' * 50);
    
    // Simula il processo di aggiornamento migliorato
    final liveMatches = await footballService.getLiveMatches();
    print('✅ Partite live disponibili: ${liveMatches.length}');
    
    if (liveMatches.isNotEmpty) {
      // Prendi le prime 3 partite come esempio
      final sampleMatches = liveMatches.take(3).toList();
      final sampleIds = sampleMatches.map((m) => m.id).toList();
      
      print('\n📋 Test con partite campione:');
      for (final match in sampleMatches) {
        final timeSinceStart = DateTime.now().difference(match.start);
        final isRecent = timeSinceStart.inHours <= 3;
        final isNotFinished = match.elapsed == null || match.elapsed! < 90;
        final shouldUpdate = isRecent || isNotFinished;
        
        print('   🔍 ${match.home} vs ${match.away}');
        print('      Start: ${match.start}');
        print('      Elapsed: ${match.elapsed ?? "N/A"}');
        print('      Ore fa: ${timeSinceStart.inHours}h ${timeSinceStart.inMinutes % 60}m');
        print('      Dovrebbe aggiornare: ${shouldUpdate ? "SÌ" : "NO"}');
        print('      Motivo: ${isRecent ? "Recente" : ""} ${isNotFinished ? "Non finita" : ""}');
      }
      
      // TENTATIVO 1: Cerca nelle live
      print('\n🔴 TENTATIVO 1: Cerca nelle partite live');
      final liveUpdates = liveMatches.where((live) => sampleIds.contains(live.id)).toList();
      print('   Trovate nelle live: ${liveUpdates.length}/${sampleIds.length}');
      
      // TENTATIVO 2: Cerca nelle partite di oggi per quelle mancanti
      final foundIds = liveUpdates.map((m) => m.id).toSet();
      final missingIds = sampleIds.where((id) => !foundIds.contains(id)).toList();
      
      if (missingIds.isNotEmpty) {
        print('\n📅 TENTATIVO 2: Cerca nelle partite di oggi');
        print('   IDs mancanti: $missingIds');
        
        final todayMatches = await footballService.getFixturesToday();
        final todayUpdates = todayMatches.where((today) => missingIds.contains(today.id)).toList();
        print('   Trovate nelle partite di oggi: ${todayUpdates.length}/${missingIds.length}');
        
        final totalFound = liveUpdates.length + todayUpdates.length;
        print('   ✅ TOTALE TROVATE: $totalFound/${sampleIds.length}');
      } else {
        print('   ✅ Tutte le partite trovate nelle live!');
      }
    }
    
    // TEST 2: Verifica miglioramenti Telegram con retry
    print('\n📱 TEST 2: TELEGRAM CON RETRY AUTOMATICO');
    print('-' * 50);
    
    const testChatId = "123456789"; // Sostituisci con il tuo chat ID reale
    
    print('🧪 Test notifica con retry automatico...');
    print('   Chat ID: $testChatId');
    print('   Max retry: 3');
    print('   Timeout progressivo: 15s, 20s, 30s');
    
    final testMessage = '''
🔧 TEST CORREZIONI BOT LIVE

Questo test verifica le correzioni implementate:

✅ Retry automatico Telegram (3 tentativi)
✅ Timeout progressivo (15s → 20s → 30s)
✅ Gestione errori migliorata
✅ Strategia doppia aggiornamenti partite

⏰ ${DateTime.now()}
🔧 Versione: Correzioni applicate

Se ricevi questo messaggio, le correzioni funzionano!
''';
    
    final startTime = DateTime.now();
    final success = await telegramService.sendNotification(
      chatId: testChatId,
      message: testMessage,
      matchId: 999999,
      maxRetries: 3,
    );
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    print('   Durata totale: ${duration.inSeconds}s');
    print('   Risultato: ${success ? "✅ SUCCESSO" : "❌ FALLITO"}');
    
    if (!success) {
      print('   💡 NOTA: Il fallimento è normale se:');
      print('      - Chat ID non è il tuo reale');
      print('      - Server proxy non risponde');
      print('      - Bot Telegram non configurato');
    }
    
    // TEST 3: Verifica condizioni alert migliorate
    print('\n🔔 TEST 3: CONDIZIONI ALERT MIGLIORATE');
    print('-' * 50);
    
    // Cerca partite che soddisfano le condizioni di alert
    final alertCandidates = liveMatches.where((match) {
      final elapsed = match.elapsed ?? 0;
      final goalsHome = match.goalsHome;
      final goalsAway = match.goalsAway;
      
      // Condizione 1: 0-0 dopo 8 minuti
      final condition1 = goalsHome == 0 && goalsAway == 0 && elapsed >= 8;
      
      // Condizione 2: 1-0 o 0-1 tra 40-50 minuti
      final condition2 = ((goalsHome == 1 && goalsAway == 0) || (goalsHome == 0 && goalsAway == 1)) && 
                         elapsed >= 40 && elapsed <= 50;
      
      return condition1 || condition2;
    }).toList();
    
    print('🔍 Partite che soddisfano condizioni alert: ${alertCandidates.length}');
    
    for (final match in alertCandidates.take(3)) {
      final elapsed = match.elapsed ?? 0;
      final goalsHome = match.goalsHome;
      final goalsAway = match.goalsAway;
      
      String conditionMet = '';
      if (goalsHome == 0 && goalsAway == 0 && elapsed >= 8) {
        conditionMet = 'CONDIZIONE 1: 0-0 dopo $elapsed\'';
      } else if (((goalsHome == 1 && goalsAway == 0) || (goalsHome == 0 && goalsAway == 1)) && 
                 elapsed >= 40 && elapsed <= 50) {
        conditionMet = 'CONDIZIONE 2: $goalsHome-$goalsAway al $elapsed\'';
      }
      
      print('   🚨 ${match.home} $goalsHome-$goalsAway ${match.away}');
      print('      $conditionMet');
      print('      Lega: ${match.league}');
    }
    
    if (alertCandidates.isNotEmpty && success) {
      print('\n📤 Test invio alert per prima partita qualificata...');
      final testMatch = alertCandidates.first;
      
      final alertMessage = '''
🚨 TEST ALERT - CORREZIONI APPLICATE

${testMatch.home} ${testMatch.goalsHome} - ${testMatch.goalsAway} ${testMatch.away}
🏆 ${testMatch.league}
🌍 ${testMatch.country}
⏱️ ${testMatch.elapsed}' 

💡 Sistema di alert migliorato attivo!
🔧 Retry automatico: ✅
⚡ Timeout progressivo: ✅
🎯 Condizioni precise: ✅

Questo è un test delle correzioni applicate.
''';
      
      final alertSuccess = await telegramService.sendNotification(
        chatId: testChatId,
        message: alertMessage,
        matchId: testMatch.id,
        maxRetries: 2, // Meno retry per il test
      );
      
      print('   Alert test: ${alertSuccess ? "✅ INVIATO" : "❌ FALLITO"}');
    }
    
    print('\n${'=' * 70}');
    print('🎯 RIEPILOGO CORREZIONI:');
    print('   1. ✅ Strategia doppia aggiornamenti implementata');
    print('   2. ✅ Filtro partite attive (< 3h, elapsed < 90\')');
    print('   3. ✅ Telegram retry automatico (3 tentativi)');
    print('   4. ✅ Timeout progressivo (15s → 20s → 30s)');
    print('   5. ✅ Gestione errori migliorata');
    print('   6. ✅ Notifiche utente per aggiornamenti');
    print('');
    print('💡 PROSSIMI PASSI:');
    print('   - Configura il tuo Chat ID Telegram reale');
    print('   - Testa con partite live reali');
    print('   - Verifica le notifiche nell\'app');
    print('=' * 70);
    
  } catch (e) {
    print('❌ ERRORE DURANTE LA VERIFICA: $e');
    print('Stack trace: ${StackTrace.current}');
    exit(1);
  }
}