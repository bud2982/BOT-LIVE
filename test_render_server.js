const axios = require('axios');

const RENDER_URL = 'https://bot-live-proxy.onrender.com';

// Colori per output console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testEndpoint(name, url, method = 'GET', data = null) {
  log(`\n${'='.repeat(60)}`, 'cyan');
  log(`🧪 TEST: ${name}`, 'cyan');
  log(`📍 URL: ${url}`, 'blue');
  log(`${'='.repeat(60)}`, 'cyan');
  
  const startTime = Date.now();
  
  try {
    const config = {
      method,
      url,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    if (data) {
      config.data = data;
    }
    
    const response = await axios(config);
    const duration = Date.now() - startTime;
    
    log(`✅ SUCCESSO (${duration}ms)`, 'green');
    log(`📊 Status: ${response.status}`, 'green');
    
    // Mostra dati rilevanti
    if (response.data) {
      if (response.data.matches) {
        log(`📈 Partite trovate: ${response.data.matches.length}`, 'green');
        log(`🔍 Fonte: ${response.data.source || 'N/A'}`, 'blue');
        
        // Mostra prime 3 partite
        if (response.data.matches.length > 0) {
          log(`\n📋 Prime 3 partite:`, 'yellow');
          response.data.matches.slice(0, 3).forEach((match, i) => {
            log(`   ${i + 1}. ${match.home || match.homeTeam} vs ${match.away || match.awayTeam}`, 'yellow');
            log(`      Score: ${match.homeScore || match.goalsHome || 0} - ${match.awayScore || match.goalsAway || 0}`, 'yellow');
            log(`      League: ${match.league || match.competition || 'N/A'}`, 'yellow');
            log(`      Status: ${match.status || 'N/A'}`, 'yellow');
          });
        }
      } else if (response.data.message) {
        log(`💬 Messaggio: ${response.data.message}`, 'green');
      } else {
        log(`📦 Risposta:`, 'green');
        console.log(JSON.stringify(response.data, null, 2));
      }
    }
    
    return { success: true, duration, data: response.data };
    
  } catch (error) {
    const duration = Date.now() - startTime;
    
    log(`❌ ERRORE (${duration}ms)`, 'red');
    
    if (error.response) {
      log(`📊 Status: ${error.response.status}`, 'red');
      log(`💬 Messaggio: ${error.response.data?.message || error.response.data?.error || 'N/A'}`, 'red');
      
      if (error.response.status === 503) {
        log(`⚠️  Il server è attivo ma le API non hanno restituito dati`, 'yellow');
      }
    } else if (error.code === 'ECONNABORTED') {
      log(`⏱️  Timeout: Il server non ha risposto entro 30 secondi`, 'red');
    } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      log(`🔌 Connessione fallita: Il server potrebbe essere offline`, 'red');
    } else {
      log(`💥 Errore: ${error.message}`, 'red');
    }
    
    return { success: false, duration, error: error.message };
  }
}

async function runTests() {
  log('\n' + '='.repeat(60), 'cyan');
  log('🚀 TEST SERVER RENDER - BOT LIVE PROXY', 'cyan');
  log('='.repeat(60), 'cyan');
  log(`📍 Server: ${RENDER_URL}`, 'blue');
  log(`⏰ Inizio test: ${new Date().toLocaleString('it-IT')}`, 'blue');
  
  const results = [];
  
  // Test 1: Endpoint di test
  results.push(await testEndpoint(
    'Endpoint Test',
    `${RENDER_URL}/api/test`
  ));
  
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Test 2: Partite del giorno
  results.push(await testEndpoint(
    'Partite del Giorno (LiveScore API)',
    `${RENDER_URL}/api/livescore`
  ));
  
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Test 3: Partite LIVE
  results.push(await testEndpoint(
    'Partite LIVE',
    `${RENDER_URL}/api/live`
  ));
  
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Test 4: Sottoscrizioni Telegram
  results.push(await testEndpoint(
    'Lista Sottoscrizioni Telegram',
    `${RENDER_URL}/api/telegram/subscriptions`
  ));
  
  // Riepilogo finale
  log('\n' + '='.repeat(60), 'cyan');
  log('📊 RIEPILOGO TEST', 'cyan');
  log('='.repeat(60), 'cyan');
  
  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;
  const avgDuration = Math.round(results.reduce((sum, r) => sum + r.duration, 0) / results.length);
  
  log(`\n✅ Test superati: ${successful}/${results.length}`, successful === results.length ? 'green' : 'yellow');
  log(`❌ Test falliti: ${failed}/${results.length}`, failed > 0 ? 'red' : 'green');
  log(`⏱️  Tempo medio risposta: ${avgDuration}ms`, 'blue');
  
  // Verifica API LiveScore
  const livescoreTest = results[1]; // Test partite del giorno
  if (livescoreTest.success && livescoreTest.data?.matches?.length > 0) {
    log(`\n🎉 API LIVESCORE FUNZIONANTI!`, 'green');
    log(`   ✅ ${livescoreTest.data.matches.length} partite recuperate`, 'green');
    log(`   ✅ Fonte: ${livescoreTest.data.source}`, 'green');
  } else if (livescoreTest.success && livescoreTest.data?.matches?.length === 0) {
    log(`\n⚠️  API LIVESCORE ATTIVE ma nessuna partita oggi`, 'yellow');
  } else {
    log(`\n❌ PROBLEMA CON API LIVESCORE`, 'red');
    log(`   Verifica le credenziali API nel server`, 'red');
  }
  
  log(`\n⏰ Fine test: ${new Date().toLocaleString('it-IT')}`, 'blue');
  log('='.repeat(60) + '\n', 'cyan');
  
  // Exit code
  process.exit(failed > 0 ? 1 : 0);
}

// Esegui i test
runTests().catch(error => {
  log(`\n💥 ERRORE FATALE: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});