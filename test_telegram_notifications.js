/**
 * 🧪 SCRIPT DI TEST - Sistema Notifiche Telegram
 * 
 * Questo script testa tutte le funzionalità del sistema di notifiche:
 * 1. Test connessione bot Telegram
 * 2. Test sottoscrizione partita
 * 3. Test notifica 8° minuto 0-0
 * 4. Test notifica fine primo tempo 1-0/0-1
 * 5. Test notifica goal
 */

const axios = require('axios');

// ========================================
// CONFIGURAZIONE
// ========================================

const PROXY_URL = 'http://localhost:3001';
const BOT_TOKEN = '8298427630:AAFIwMJNq2qcdblAd0WNvt4J5QHK_-IgfJo';

// ⚠️ INSERISCI QUI IL TUO CHAT ID TELEGRAM
const YOUR_CHAT_ID = '430289563'; // Chat ID configurato!

// ========================================
// FUNZIONI DI TEST
// ========================================

// Test 1: Verifica connessione bot Telegram
async function testBotConnection() {
  console.log('\n🔍 TEST 1: Verifica connessione bot Telegram...');
  
  try {
    const response = await axios.get(`https://api.telegram.org/bot${BOT_TOKEN}/getMe`);
    
    if (response.data.ok) {
      console.log('✅ Bot Telegram connesso con successo!');
      console.log(`   Nome bot: ${response.data.result.first_name}`);
      console.log(`   Username: @${response.data.result.username}`);
      return true;
    } else {
      console.log('❌ Errore connessione bot:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.message);
    return false;
  }
}

// Test 2: Verifica proxy server
async function testProxyServer() {
  console.log('\n🔍 TEST 2: Verifica proxy server...');
  
  try {
    const response = await axios.get(`${PROXY_URL}/api/test`);
    
    if (response.data.success) {
      console.log('✅ Proxy server funzionante!');
      console.log(`   Timestamp: ${response.data.timestamp}`);
      return true;
    } else {
      console.log('❌ Proxy server non risponde correttamente');
      return false;
    }
  } catch (error) {
    console.log('❌ Errore connessione proxy server:', error.message);
    console.log('   Assicurati che il server sia avviato con: node proxy_server_new.js');
    return false;
  }
}

// Test 3: Test notifica semplice
async function testSimpleNotification() {
  console.log('\n🔍 TEST 3: Test notifica semplice...');
  
  try {
    const message = `🧪 <b>TEST NOTIFICA</b>\n\n` +
      `Questo è un messaggio di test dal sistema di notifiche.\n\n` +
      `⏰ Timestamp: ${new Date().toLocaleString('it-IT')}\n` +
      `✅ Se ricevi questo messaggio, il sistema funziona!`;
    
    const response = await axios.post(`${PROXY_URL}/api/telegram/notify`, {
      chatId: YOUR_CHAT_ID,
      message: message,
      botToken: BOT_TOKEN
    });
    
    if (response.data.success) {
      console.log('✅ Notifica inviata con successo!');
      console.log(`   Message ID: ${response.data.messageId}`);
      console.log('   📱 Controlla Telegram per vedere il messaggio!');
      return true;
    } else {
      console.log('❌ Errore invio notifica:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// Test 4: Test sottoscrizione partita
async function testSubscription() {
  console.log('\n🔍 TEST 4: Test sottoscrizione partita...');
  
  try {
    const testMatch = {
      id: 'test-match-12345',
      home: 'Inter',
      away: 'Milan',
      league: 'Serie A',
      country: 'Italy'
    };
    
    const response = await axios.post(`${PROXY_URL}/api/telegram/subscribe`, {
      chatId: YOUR_CHAT_ID,
      matchId: testMatch.id,
      matchInfo: testMatch
    });
    
    if (response.data.success) {
      console.log('✅ Sottoscrizione registrata con successo!');
      console.log(`   Subscription ID: ${response.data.subscriptionId}`);
      console.log(`   Partita: ${testMatch.home} vs ${testMatch.away}`);
      return true;
    } else {
      console.log('❌ Errore sottoscrizione:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// Test 5: Test notifica 8° minuto 0-0
async function testMinute8Notification() {
  console.log('\n🔍 TEST 5: Test notifica 8° minuto 0-0...');
  
  try {
    const message = `⏱️ <b>ALERT MINUTO 8</b>\n\n` +
      `<b>Inter 0-0 Milan</b>\n\n` +
      `⚠️ La partita è ancora 0-0 all'8° minuto\n` +
      `🏆 Serie A\n` +
      `🌍 Italy\n\n` +
      `🧪 <i>Questo è un test simulato</i>`;
    
    const response = await axios.post(`${PROXY_URL}/api/telegram/notify`, {
      chatId: YOUR_CHAT_ID,
      message: message,
      matchId: 'test-match-12345',
      botToken: BOT_TOKEN
    });
    
    if (response.data.success) {
      console.log('✅ Notifica 8° minuto inviata!');
      console.log('   📱 Controlla Telegram per vedere l\'alert!');
      return true;
    } else {
      console.log('❌ Errore:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// Test 6: Test notifica fine primo tempo
async function testHalfTimeNotification() {
  console.log('\n🔍 TEST 6: Test notifica fine primo tempo 1-0...');
  
  try {
    const message = `🏁 <b>ALERT FINE PRIMO TEMPO</b>\n\n` +
      `<b>Inter 1-0 Milan</b>\n\n` +
      `⚽ Fine primo tempo con risultato 1-0\n` +
      `🏆 Serie A\n` +
      `🌍 Italy\n\n` +
      `🧪 <i>Questo è un test simulato</i>`;
    
    const response = await axios.post(`${PROXY_URL}/api/telegram/notify`, {
      chatId: YOUR_CHAT_ID,
      message: message,
      matchId: 'test-match-12345',
      botToken: BOT_TOKEN
    });
    
    if (response.data.success) {
      console.log('✅ Notifica fine primo tempo inviata!');
      console.log('   📱 Controlla Telegram per vedere l\'alert!');
      return true;
    } else {
      console.log('❌ Errore:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// Test 7: Test notifica goal
async function testGoalNotification() {
  console.log('\n🔍 TEST 7: Test notifica goal...');
  
  try {
    const message = `⚽ <b>GOOOAL!</b>\n\n` +
      `<b>Inter 2-0 Milan</b>\n\n` +
      `🎯 Goal al 65° minuto!\n` +
      `🏆 Serie A\n` +
      `🌍 Italy\n\n` +
      `🧪 <i>Questo è un test simulato</i>`;
    
    const response = await axios.post(`${PROXY_URL}/api/telegram/notify`, {
      chatId: YOUR_CHAT_ID,
      message: message,
      matchId: 'test-match-12345',
      botToken: BOT_TOKEN
    });
    
    if (response.data.success) {
      console.log('✅ Notifica goal inviata!');
      console.log('   📱 Controlla Telegram per vedere l\'alert!');
      return true;
    } else {
      console.log('❌ Errore:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// Test 8: Verifica sottoscrizioni attive
async function testGetSubscriptions() {
  console.log('\n🔍 TEST 8: Verifica sottoscrizioni attive...');
  
  try {
    const response = await axios.get(`${PROXY_URL}/api/telegram/subscriptions`);
    
    if (response.data.success) {
      console.log('✅ Sottoscrizioni recuperate!');
      console.log(`   Totale sottoscrizioni attive: ${response.data.total}`);
      
      if (response.data.subscriptions.length > 0) {
        console.log('\n   📋 Lista sottoscrizioni:');
        response.data.subscriptions.forEach((sub, index) => {
          console.log(`   ${index + 1}. ${sub.matchInfo.home} vs ${sub.matchInfo.away}`);
          console.log(`      Chat ID: ${sub.chatId}`);
          console.log(`      Match ID: ${sub.matchId}`);
        });
      }
      return true;
    } else {
      console.log('❌ Errore:', response.data);
      return false;
    }
  } catch (error) {
    console.log('❌ Errore:', error.response?.data || error.message);
    return false;
  }
}

// ========================================
// ESECUZIONE TEST
// ========================================

async function runAllTests() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  🧪 TEST SISTEMA NOTIFICHE TELEGRAM - BOT LIVE           ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  
  // Verifica Chat ID
  if (YOUR_CHAT_ID === 'IL_TUO_CHAT_ID') {
    console.log('\n❌ ERRORE: Devi configurare il tuo Chat ID Telegram!');
    console.log('\n📝 Come ottenere il Chat ID:');
    console.log('   1. Apri Telegram');
    console.log('   2. Cerca il bot: @userinfobot');
    console.log('   3. Avvia il bot (clicca START)');
    console.log('   4. Il bot ti darà il tuo Chat ID (es: 123456789)');
    console.log('   5. Modifica questo file e inserisci il Chat ID alla riga 18');
    console.log('\n   const YOUR_CHAT_ID = \'123456789\'; // <-- Il tuo Chat ID qui\n');
    return;
  }
  
  console.log(`\n📱 Chat ID configurato: ${YOUR_CHAT_ID}`);
  console.log(`🤖 Bot Token: ${BOT_TOKEN.substring(0, 15)}...`);
  console.log(`🌐 Proxy URL: ${PROXY_URL}`);
  
  const results = {
    passed: 0,
    failed: 0,
    total: 0
  };
  
  // Esegui tutti i test
  const tests = [
    { name: 'Bot Connection', fn: testBotConnection },
    { name: 'Proxy Server', fn: testProxyServer },
    { name: 'Simple Notification', fn: testSimpleNotification },
    { name: 'Subscription', fn: testSubscription },
    { name: 'Minute 8 Alert', fn: testMinute8Notification },
    { name: 'Half Time Alert', fn: testHalfTimeNotification },
    { name: 'Goal Alert', fn: testGoalNotification },
    { name: 'Get Subscriptions', fn: testGetSubscriptions }
  ];
  
  for (const test of tests) {
    results.total++;
    const passed = await test.fn();
    
    if (passed) {
      results.passed++;
    } else {
      results.failed++;
    }
    
    // Pausa tra i test per non sovraccaricare Telegram
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  // Riepilogo finale
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║  📊 RIEPILOGO TEST                                        ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log(`\n✅ Test superati: ${results.passed}/${results.total}`);
  console.log(`❌ Test falliti: ${results.failed}/${results.total}`);
  
  if (results.failed === 0) {
    console.log('\n🎉 TUTTI I TEST SUPERATI! Il sistema è pronto!');
    console.log('\n📱 Controlla Telegram per vedere tutte le notifiche ricevute!');
    console.log('\n🚀 Prossimi passi:');
    console.log('   1. Implementare UI Flutter per configurare Chat ID');
    console.log('   2. Aggiungere pulsante "Segui partita" nell\'app');
    console.log('   3. Testare con partite live reali');
  } else {
    console.log('\n⚠️ Alcuni test sono falliti. Controlla i log sopra per i dettagli.');
  }
  
  console.log('\n════════════════════════════════════════════════════════════\n');
}

// Avvia i test
runAllTests().catch(error => {
  console.error('\n💥 Errore fatale durante l\'esecuzione dei test:', error);
  process.exit(1);
});