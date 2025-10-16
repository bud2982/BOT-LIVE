const axios = require('axios');

console.log('🧪 TEST TUTTI GLI ENDPOINT LIVESCORE API');
console.log('============================================================\n');

async function testAllEndpoints() {
  const today = new Date().toISOString().split('T')[0];
  
  const endpoints = [
    {
      name: 'Fixtures Matches (date)',
      url: 'https://livescore-api.com/api-client/fixtures/matches.json',
      params: { date: today }
    },
    {
      name: 'Matches Live',
      url: 'https://livescore-api.com/api-client/matches/live.json',
      params: {}
    },
    {
      name: 'Scores Live',
      url: 'https://livescore-api.com/api-client/scores/live.json',
      params: {}
    },
    {
      name: 'Scores History (today)',
      url: 'https://livescore-api.com/api-client/scores/history.json',
      params: { date: today }
    },
    {
      name: 'Fixtures List (date)',
      url: 'https://livescore-api.com/api-client/fixtures/list.json',
      params: { date: today }
    }
  ];
  
  const allMatches = new Map();
  
  for (const endpoint of endpoints) {
    console.log(`\n🔍 Test: ${endpoint.name}`);
    console.log(`📡 URL: ${endpoint.url}`);
    
    try {
      const response = await axios.get(endpoint.url, {
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          ...endpoint.params
        },
        timeout: 15000
      });
      
      if (response.status === 200 && response.data) {
        console.log(`✅ Status: ${response.status}`);
        
        // Prova diversi percorsi per i dati
        const fixtures = response.data?.data?.fixtures || 
                        response.data?.data?.match || 
                        response.data?.data?.matches ||
                        response.data?.data?.scores ||
                        [];
        
        console.log(`📊 Partite trovate: ${fixtures.length}`);
        
        // Mostra struttura della risposta
        if (response.data?.data) {
          console.log(`📋 Chiavi disponibili:`, Object.keys(response.data.data));
        }
        
        // Aggiungi partite uniche
        if (Array.isArray(fixtures) && fixtures.length > 0) {
          fixtures.forEach(match => {
            const home = match.home_name || match.home?.name || 'Unknown';
            const away = match.away_name || match.away?.name || 'Unknown';
            const key = `${home}-${away}`;
            
            if (!allMatches.has(key)) {
              allMatches.set(key, {
                home,
                away,
                league: match.competition?.name || match.competition_name || match.league?.name || 'Unknown',
                source: endpoint.name
              });
            }
          });
          
          // Mostra prime 3 partite
          console.log(`\n🎯 Prime 3 partite:`);
          fixtures.slice(0, 3).forEach((match, i) => {
            const home = match.home_name || match.home?.name || 'Unknown';
            const away = match.away_name || match.away?.name || 'Unknown';
            console.log(`   ${i + 1}. ${home} vs ${away}`);
          });
        }
        
      } else {
        console.log(`❌ Status: ${response.status}`);
      }
      
    } catch (error) {
      console.log(`❌ Errore: ${error.message}`);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
      }
    }
    
    // Delay tra le richieste
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  console.log(`\n============================================================`);
  console.log(`📊 RISULTATO FINALE`);
  console.log(`============================================================`);
  console.log(`✅ Totale partite uniche da tutti gli endpoint: ${allMatches.size}`);
  
  if (allMatches.size > 0) {
    console.log(`\n🎯 Tutte le partite trovate:\n`);
    let i = 1;
    for (const [key, match] of allMatches) {
      console.log(`${i}. ${match.home} vs ${match.away}`);
      console.log(`   League: ${match.league} | Fonte: ${match.source}`);
      i++;
    }
  }
}

testAllEndpoints();