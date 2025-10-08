const axios = require('axios');

async function testLiveScoreAPILive() {
  console.log('🧪 Testando Live-Score API Live Scores endpoint (formato ufficiale)...');
  
  const url = 'https://livescore-api.com/api-client/scores/live.json';
  const params = {
    key: 'wUOF0E1DmdetayWk',
    secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl'
  };
  
  console.log('📡 URL:', url);
  console.log('🔑 Parametri:', JSON.stringify(params, null, 2));
  
  try {
    const response = await axios.get(url, { params });
    
    console.log('✅ Status:', response.status);
    console.log('📊 Dati ricevuti:', typeof response.data);
    
    if (response.data) {
      console.log('🎯 API Success:', response.data.success);
      
      if (response.data.success && response.data.data) {
        const matches = response.data.data.match || [];
        console.log('⚽ Partite live trovate:', matches.length);
        
        if (matches.length > 0) {
          console.log('\n📋 Prime 3 partite live (formato ufficiale):');
          matches.slice(0, 3).forEach((match, i) => {
            console.log(`  ${i+1}. ${match.home_name || 'N/A'} vs ${match.away_name || 'N/A'}`);
            console.log(`     Score: ${match.score || '0 - 0'}`);
            console.log(`     Status: ${match.status || 'N/A'}, Time: ${match.time || 'N/A'}`);
            console.log(`     League: ${match.league_name || 'N/A'}`);
          });
        }
      } else {
        console.log('❌ API returned success: false');
        console.log('📄 Response:', JSON.stringify(response.data, null, 2));
      }
    }
    
  } catch (error) {
    console.error('❌ Errore:', error.message);
    if (error.response) {
      console.error('📄 Status:', error.response.status);
      console.error('📄 Response:', error.response.data);
    }
  }
}

testLiveScoreAPILive();