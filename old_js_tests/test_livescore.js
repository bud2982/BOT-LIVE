const axios = require('axios');

async function testLiveScoreAPI() {
  try {
    console.log('🧪 Testando Live-Score API con endpoint corretto...');
    
    const url = 'https://livescore-api.com/api-client/fixtures/list.json';
    const params = {
      key: 'wUOF0E1DmdetayWk',
      secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
      date: 'today'
    };
    
    console.log('📡 URL:', url);
    console.log('🔑 Parametri:', params);
    
    const response = await axios.get(url, { params });
    
    console.log('✅ Status:', response.status);
    console.log('📊 Dati ricevuti:', typeof response.data);
    
    if (response.data && response.data.success) {
      console.log('🎯 API Success:', response.data.success);
      if (response.data.data && response.data.data.fixtures) {
        console.log('⚽ Partite trovate:', response.data.data.fixtures.length);
        if (response.data.data.fixtures.length > 0) {
          console.log('📝 Prima partita:', JSON.stringify(response.data.data.fixtures[0], null, 2));
        }
      }
    } else {
      console.log('📄 Risposta completa:', JSON.stringify(response.data, null, 2));
    }
    
  } catch (error) {
    console.error('❌ Errore:', error.response?.status, error.response?.statusText);
    if (error.response?.data) {
      console.error('📄 Dettagli errore:', typeof error.response.data === 'string' ? 
        error.response.data.substring(0, 500) + '...' : 
        JSON.stringify(error.response.data, null, 2));
    }
  }
}

testLiveScoreAPI();