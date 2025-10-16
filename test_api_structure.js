const axios = require('axios');

// Test per vedere la struttura esatta dell'API ufficiale
async function testAPIStructure() {
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  const today = new Date().toISOString().split('T')[0];
  
  console.log('🔍 TEST STRUTTURA API UFFICIALE LIVESCORE-API.COM');
  console.log('='.repeat(60));
  console.log(`📅 Data: ${today}`);
  console.log(`🔑 API Key: ${apiKey.substring(0, 4)}...${apiKey.substring(12)}`);
  console.log('');
  
  // Test endpoint fixtures
  try {
    console.log('📡 Test endpoint: fixtures/matches.json');
    console.log('-'.repeat(60));
    
    const response = await axios.get(`${baseUrl}/fixtures/matches.json`, {
      params: {
        key: apiKey,
        secret: apiSecret,
        date: today
      },
      timeout: 15000
    });
    
    if (response.data.success) {
      const fixtures = response.data.data.fixtures || [];
      console.log(`✅ Successo! Trovate ${fixtures.length} partite`);
      console.log('');
      
      if (fixtures.length > 0) {
        console.log('📦 STRUTTURA PRIMA PARTITA:');
        console.log('='.repeat(60));
        console.log(JSON.stringify(fixtures[0], null, 2));
        console.log('');
        
        console.log('📋 CAMPI DISPONIBILI:');
        console.log('-'.repeat(60));
        Object.keys(fixtures[0]).forEach(key => {
          const value = fixtures[0][key];
          const type = typeof value;
          const preview = type === 'object' ? JSON.stringify(value) : String(value);
          console.log(`  ${key}: (${type}) ${preview.substring(0, 50)}${preview.length > 50 ? '...' : ''}`);
        });
        console.log('');
        
        // Mostra 5 partite di esempio
        console.log('🎯 PRIME 5 PARTITE:');
        console.log('='.repeat(60));
        fixtures.slice(0, 5).forEach((match, index) => {
          console.log(`${index + 1}. ${match.home_name || 'N/A'} vs ${match.away_name || 'N/A'}`);
          console.log(`   ID: ${match.id || 'N/A'}`);
          console.log(`   Date: ${match.date || 'N/A'}`);
          console.log(`   Time: ${match.time || 'N/A'}`);
          console.log(`   Status: ${match.status || 'N/A'}`);
          console.log(`   League: ${match.competition_name || 'N/A'}`);
          console.log(`   Country: ${match.country_name || 'N/A'}`);
          console.log(`   Score: ${match.score || 'N/A'}`);
          console.log(`   Location: ${match.location || 'N/A'}`);
          console.log('');
        });
      }
    } else {
      console.log(`❌ Errore API: ${response.data.error}`);
    }
    
  } catch (error) {
    console.error('❌ Errore:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
  
  console.log('');
  console.log('🏁 Test completato');
}

testAPIStructure();