const axios = require('axios');

console.log('🧪 TEST COMPLETO - TUTTE LE PARTITE DI OGGI');
console.log('============================================================');
console.log(`⏰ Data: ${new Date().toLocaleDateString('it-IT')}\n`);

async function testAllMatches() {
  const today = new Date().toISOString().split('T')[0];
  
  console.log(`📅 Ricerca partite per: ${today}\n`);
  
  try {
    // Test endpoint fixtures con parametri diversi
    const endpoints = [
      {
        name: 'Fixtures Today (default)',
        url: 'https://livescore-api.com/api-client/fixtures/matches.json',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: today
        }
      },
      {
        name: 'Fixtures Today (con limit)',
        url: 'https://livescore-api.com/api-client/fixtures/matches.json',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: today,
          limit: 100
        }
      },
      {
        name: 'Fixtures Today (con page)',
        url: 'https://livescore-api.com/api-client/fixtures/matches.json',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: today,
          page: 1
        }
      }
    ];
    
    for (const endpoint of endpoints) {
      console.log(`\n🔍 Test: ${endpoint.name}`);
      console.log(`📡 URL: ${endpoint.url}`);
      console.log(`📋 Parametri:`, JSON.stringify(endpoint.params, null, 2));
      
      try {
        const response = await axios.get(endpoint.url, {
          params: endpoint.params,
          timeout: 15000
        });
        
        if (response.status === 200 && response.data) {
          const fixtures = response.data?.data?.fixtures || [];
          console.log(`✅ Status: ${response.status}`);
          console.log(`📊 Partite trovate: ${fixtures.length}`);
          
          // Mostra info sulla paginazione se presente
          if (response.data?.data?.pagination) {
            console.log(`📄 Paginazione:`, JSON.stringify(response.data.data.pagination, null, 2));
          }
          
          // Mostra le prime 3 partite
          if (fixtures.length > 0) {
            console.log(`\n🎯 Prime 3 partite:`);
            fixtures.slice(0, 3).forEach((match, i) => {
              console.log(`   ${i + 1}. ${match.home_name || match.home?.name} vs ${match.away_name || match.away?.name}`);
              console.log(`      League: ${match.competition?.name || match.competition_name}`);
            });
          }
        }
      } catch (error) {
        console.log(`❌ Errore: ${error.message}`);
        if (error.response) {
          console.log(`   Status: ${error.response.status}`);
          console.log(`   Data:`, JSON.stringify(error.response.data, null, 2));
        }
      }
      
      // Delay tra le richieste
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
  } catch (error) {
    console.error('💥 Errore generale:', error.message);
  }
}

testAllMatches();