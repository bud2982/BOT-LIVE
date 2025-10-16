const axios = require('axios');

// Test DIRETTO alle API LiveScore (senza proxy)
const API_KEY = 'wUOF0E1DmdetayWk';
const API_SECRET = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';

console.log('🔍 TEST DIRETTO API LIVESCORE');
console.log('=' .repeat(60));
console.log('📅 Data di oggi:', new Date().toISOString().split('T')[0]);
console.log('🔑 API Key:', API_KEY.substring(0, 10) + '...');
console.log('🔐 API Secret:', API_SECRET.substring(0, 10) + '...');
console.log('');

async function testLiveScoreAPI() {
  const endpoints = [
    {
      name: 'Live Matches',
      url: 'http://livescore-api.com/api-client/matches/live.json',
      params: { key: API_KEY, secret: API_SECRET }
    },
    {
      name: 'Live Scores',
      url: 'https://livescore-api.com/api-client/scores/live.json',
      params: { key: API_KEY, secret: API_SECRET }
    },
    {
      name: 'Fixtures Today',
      url: 'https://livescore-api.com/api-client/fixtures/list.json',
      params: { key: API_KEY, secret: API_SECRET, date: 'today' }
    }
  ];

  for (const endpoint of endpoints) {
    console.log(`\n🧪 Test: ${endpoint.name}`);
    console.log(`📍 URL: ${endpoint.url}`);
    
    const startTime = Date.now();
    
    try {
      const response = await axios.get(endpoint.url, {
        params: endpoint.params,
        timeout: 15000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json'
        }
      });
      
      const duration = Date.now() - startTime;
      
      console.log(`✅ Risposta ricevuta in ${duration}ms`);
      console.log(`📊 Status: ${response.status}`);
      
      // Analizza la risposta
      const data = response.data;
      
      if (data.success === false) {
        console.log(`❌ API Error: ${data.error || 'Unknown error'}`);
        if (data.message) console.log(`💬 Message: ${data.message}`);
      } else if (data.data) {
        const matches = data.data.match || data.data.fixtures || [];
        console.log(`📈 Partite trovate: ${Array.isArray(matches) ? matches.length : 0}`);
        
        if (Array.isArray(matches) && matches.length > 0) {
          console.log(`\n📋 Prime 3 partite:`);
          matches.slice(0, 3).forEach((match, i) => {
            const home = match.home?.name || match.home_name || 'N/A';
            const away = match.away?.name || match.away_name || 'N/A';
            const score = match.score || `${match.home_goals || 0}-${match.away_goals || 0}`;
            console.log(`   ${i + 1}. ${home} vs ${away} (${score})`);
          });
        }
      } else {
        console.log(`⚠️  Struttura risposta inaspettata:`);
        console.log(JSON.stringify(data, null, 2).substring(0, 500));
      }
      
    } catch (error) {
      const duration = Date.now() - startTime;
      console.log(`❌ ERRORE dopo ${duration}ms`);
      
      if (error.response) {
        console.log(`📊 Status: ${error.response.status}`);
        console.log(`💬 Errore: ${error.response.data?.error || error.response.statusText}`);
        
        if (error.response.status === 401) {
          console.log(`🔑 CREDENZIALI NON VALIDE!`);
        } else if (error.response.status === 429) {
          console.log(`⏱️  LIMITE RICHIESTE RAGGIUNTO!`);
        } else if (error.response.status === 403) {
          console.log(`🚫 ACCESSO NEGATO - Verifica il piano API`);
        }
      } else if (error.code === 'ECONNABORTED') {
        console.log(`⏱️  Timeout dopo 15 secondi`);
      } else {
        console.log(`💥 ${error.message}`);
      }
    }
    
    // Pausa tra le richieste
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('🏁 Test completato');
}

testLiveScoreAPI();