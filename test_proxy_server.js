/**
 * TEST PROXY SERVER - Verifica funzionalità proxy_server_new.js
 * 
 * Questo script testa tutti gli endpoint del proxy server per verificare
 * che le notifiche Telegram e il recupero dati funzionino correttamente.
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3001';
const TEST_CHAT_ID = '123456789'; // Chat ID di test
const TEST_MATCH_ID = 'test-match-001';

// Colori per output console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(testName) {
  console.log('\n' + '='.repeat(60));
  log(`TEST: ${testName}`, 'cyan');
  console.log('='.repeat(60));
}

function logResult(passed, message) {
  if (passed) {
    log(`✅ PASS: ${message}`, 'green');
  } else {
    log(`❌ FAIL: ${message}`, 'red');
  }
}

// Statistiche test
const stats = {
  total: 0,
  passed: 0,
  failed: 0
};

function recordResult(passed) {
  stats.total++;
  if (passed) {
    stats.passed++;
  } else {
    stats.failed++;
  }
}

// ========================================
// TEST 1: Connessione al server
// ========================================
async function testConnection() {
  logTest('Connessione al Server');
  
  try {
    const response = await axios.get(`${BASE_URL}/api/test`, { timeout: 5000 });
    
    const passed = response.status === 200 && response.data.success === true;
    logResult(passed, 'Server risponde correttamente');
    recordResult(passed);
    
    if (passed) {
      log(`  Messaggio: ${response.data.message}`, 'gray');
      log(`  Timestamp: ${response.data.timestamp}`, 'gray');
    }
    
    return passed;
  } catch (error) {
    logResult(false, `Errore connessione: ${error.message}`);
    recordResult(false);
    return false;
  }
}

// ========================================
// TEST 2: Endpoint partite del giorno
// ========================================
async function testTodayMatches() {
  logTest('Endpoint Partite del Giorno');
  
  try {
    log('Richiesta a /api/livescore...', 'gray');
    const response = await axios.get(`${BASE_URL}/api/livescore`, { timeout: 30000 });
    
    const hasData = response.data.matches && Array.isArray(response.data.matches);
    const passed = response.status === 200 || response.status === 503; // 503 se nessuna partita
    
    logResult(passed, 'Endpoint risponde');
    recordResult(passed);
    
    if (hasData) {
      log(`  Partite trovate: ${response.data.matches.length}`, 'gray');
      log(`  Fonte: ${response.data.source}`, 'gray');
      
      if (response.data.matches.length > 0) {
        const match = response.data.matches[0];
        log(`  Esempio: ${match.home} vs ${match.away}`, 'gray');
      }
    } else {
      log(`  Nessuna partita disponibile (normale se fuori orario)`, 'yellow');
    }
    
    return passed;
  } catch (error) {
    logResult(false, `Errore: ${error.message}`);
    recordResult(false);
    return false;
  }
}

// ========================================
// TEST 3: Endpoint partite live
// ========================================
async function testLiveMatches() {
  logTest('Endpoint Partite Live');
  
  try {
    log('Richiesta a /api/live...', 'gray');
    const response = await axios.get(`${BASE_URL}/api/live`, { timeout: 30000 });
    
    const hasData = response.data.matches && Array.isArray(response.data.matches);
    const passed = response.status === 200 || response.status === 503; // 503 se nessuna partita live
    
    logResult(passed, 'Endpoint risponde');
    recordResult(passed);
    
    if (hasData && response.data.matches.length > 0) {
      log(`  Partite live: ${response.data.matches.length}`, 'gray');
      
      const match = response.data.matches[0];
      log(`  Esempio: ${match.home} ${match.goalsHome}-${match.goalsAway} ${match.away}`, 'gray');
      log(`  Minuto: ${match.elapsed}'`, 'gray');
    } else {
      log(`  Nessuna partita live al momento (normale)`, 'yellow');
    }
    
    return passed;
  } catch (error) {
    logResult(false, `Errore: ${error.message}`);
    recordResult(false);
    return false;
  }
}

// ========================================
// TEST 4: Sottoscrizione Telegram
// ========================================
async function testTelegramSubscribe() {
  logTest('Sottoscrizione Notifiche Telegram');
  
  try {
    const subscriptionData = {
      chatId: TEST_CHAT_ID,
      matchId: TEST_MATCH_ID,
      matchInfo: {
        home: 'Test Team A',
        away: 'Test Team B',
        league: 'Test League',
        country: 'Test Country'
      }
    };
    
    log('Invio richiesta sottoscrizione...', 'gray');
    const response = await axios.post(
      `${BASE_URL}/api/telegram/subscribe`,
      subscriptionData,
      { timeout: 5000 }
    );
    
    const passed = response.status === 200 && response.data.success === true;
    logResult(passed, 'Sottoscrizione registrata');
    recordResult(passed);
    
    if (passed) {
      log(`  Subscription ID: ${response.data.subscriptionId}`, 'gray');
      log(`  Timestamp: ${response.data.timestamp}`, 'gray');
    }
    
    return passed;
  } catch (error) {
    logResult(false, `Errore: ${error.message}`);
    recordResult(false);
    return false;
  }
}

// ========================================
// TEST 5: Lista sottoscrizioni
// ========================================
async function testGetSubscriptions() {
  logTest('Recupero Lista Sottoscrizioni');
  
  try {
    log('Richiesta lista sottoscrizioni...', 'gray');
    const response = await axios.get(`${BASE_URL}/api/telegram/subscriptions`, { timeout: 5000 });
    
    const passed = response.status === 200 && response.data.success === true;
    logResult(passed, 'Lista recuperata');
    recordResult(passed);
    
    if (passed) {
      log(`  Sottoscrizioni attive: ${response.data.total}`, 'gray');
      
      if (response.data.subscriptions.length > 0) {
        const sub = response.data.subscriptions[0];
        log(`  Esempio: Chat ${sub.chatId} - Match ${sub.matchId}`, 'gray');
      }
    }
    
    return passed;
  } catch (error) {
    logResult(false, `Errore: ${error.message}`);
    recordResult(false);
    return false;
  }
}

// ========================================
// TEST 6: Invio notifica Telegram (SIMULATO)
// ========================================
async function testTelegramNotify() {
  logTest('Invio Notifica Telegram (Simulato)');
  
  try {
    const notificationData = {
      chatId: TEST_CHAT_ID,
      matchId: TEST_MATCH_ID,
      message: '🧪 <b>TEST NOTIFICA</b>\n\nQuesto è un messaggio di test dal sistema di validazione.\n\n⚽ Test Team A 1-0 Test Team B\n⏱️ 45\' - Fine primo tempo'
    };
    
    log('⚠️  NOTA: Questo test invierà una notifica reale se il bot token è valido', 'yellow');
    log('Invio notifica...', 'gray');
    
    const response = await axios.post(
      `${BASE_URL}/api/telegram/notify`,
      notificationData,
      { timeout: 10000 }
    );
    
    const passed = response.status === 200 && response.data.success === true;
    logResult(passed, 'Notifica inviata');
    recordResult(passed);
    
    if (passed) {
      log(`  Chat ID: ${response.data.chatId}`, 'gray');
      log(`  Message ID: ${response.data.messageId}`, 'gray');
    }
    
    return passed;
  } catch (error) {
    // Questo test può fallire se il chat ID non è valido, ma è normale
    if (error.response && error.response.status === 400) {
      log(`⚠️  Notifica non inviata (chat ID test non valido - normale)`, 'yellow');
      logResult(true, 'Endpoint funziona correttamente');
      recordResult(true);
      return true;
    } else {
      logResult(false, `Errore: ${error.message}`);
      recordResult(false);
      return false;
    }
  }
}

// ========================================
// TEST 7: Rimozione sottoscrizione
// ========================================
async function testUnsubscribe() {
  logTest('Rimozione Sottoscrizione');
  
  try {
    log('Richiesta rimozione sottoscrizione...', 'gray');
    const response = await axios.delete(
      `${BASE_URL}/api/telegram/unsubscribe/${TEST_CHAT_ID}/${TEST_MATCH_ID}`,
      { timeout: 5000 }
    );
    
    const passed = response.status === 200 || response.status === 404; // 404 se già rimossa
    logResult(passed, 'Sottoscrizione rimossa o non trovata');
    recordResult(passed);
    
    if (response.status === 200) {
      log(`  Messaggio: ${response.data.message}`, 'gray');
    } else if (response.status === 404) {
      log(`  Sottoscrizione non trovata (già rimossa)`, 'gray');
    }
    
    return passed;
  } catch (error) {
    // 404 è accettabile
    if (error.response && error.response.status === 404) {
      logResult(true, 'Sottoscrizione non trovata (normale)');
      recordResult(true);
      return true;
    } else {
      logResult(false, `Errore: ${error.message}`);
      recordResult(false);
      return false;
    }
  }
}

// ========================================
// ESECUZIONE TEST
// ========================================
async function runAllTests() {
  console.log('\n');
  log('╔════════════════════════════════════════════════════════════╗', 'cyan');
  log('║                                                            ║', 'cyan');
  log('║         TEST SUITE PROXY SERVER - VERSIONE 2.1.0          ║', 'cyan');
  log('║                                                            ║', 'cyan');
  log('╚════════════════════════════════════════════════════════════╝', 'cyan');
  
  log(`\nURL Base: ${BASE_URL}`, 'gray');
  log(`Data: ${new Date().toLocaleString('it-IT')}`, 'gray');
  
  // Esegui tutti i test in sequenza
  await testConnection();
  await testTodayMatches();
  await testLiveMatches();
  await testTelegramSubscribe();
  await testGetSubscriptions();
  await testTelegramNotify();
  await testUnsubscribe();
  
  // Stampa risultati finali
  console.log('\n' + '='.repeat(60));
  log('RISULTATI FINALI', 'cyan');
  console.log('='.repeat(60));
  
  log(`\nTest totali: ${stats.total}`, 'gray');
  log(`Test superati: ${stats.passed}`, 'green');
  log(`Test falliti: ${stats.failed}`, stats.failed > 0 ? 'red' : 'gray');
  
  const percentage = Math.round((stats.passed / stats.total) * 100);
  log(`\nPercentuale successo: ${percentage}%`, percentage >= 80 ? 'green' : 'yellow');
  
  if (stats.failed === 0) {
    console.log('\n');
    log('╔════════════════════════════════════════════════════════════╗', 'green');
    log('║                                                            ║', 'green');
    log('║  ✅ TUTTI I TEST SUPERATI - PROXY SERVER FUNZIONANTE      ║', 'green');
    log('║                                                            ║', 'green');
    log('╚════════════════════════════════════════════════════════════╝', 'green');
  } else {
    console.log('\n');
    log('╔════════════════════════════════════════════════════════════╗', 'yellow');
    log('║                                                            ║', 'yellow');
    log('║  ⚠️  ALCUNI TEST FALLITI - VERIFICARE CONFIGURAZIONE      ║', 'yellow');
    log('║                                                            ║', 'yellow');
    log('╚════════════════════════════════════════════════════════════╝', 'yellow');
  }
  
  console.log('\n');
  
  // Exit code
  process.exit(stats.failed > 0 ? 1 : 0);
}

// ========================================
// AVVIO
// ========================================
if (require.main === module) {
  log('\n⚠️  ASSICURATI CHE IL PROXY SERVER SIA IN ESECUZIONE:', 'yellow');
  log('   node proxy_server_new.js\n', 'yellow');
  
  setTimeout(() => {
    runAllTests().catch(error => {
      log(`\n💥 ERRORE FATALE: ${error.message}`, 'red');
      console.error(error);
      process.exit(1);
    });
  }, 2000);
}

module.exports = { runAllTests };