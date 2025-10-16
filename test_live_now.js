const axios = require('axios');

console.log('🔴 TEST PARTITE LIVE ADESSO');
console.log('============================================================');
console.log(`⏰ Ora attuale: ${new Date().toLocaleString('it-IT')}`);
console.log('🔑 API Key: wUOF0E1DmdetayWk');
console.log('🔐 API Secret: Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl');
console.log('');

async function testLiveMatches() {
  const endpoints = [
    {
      name: 'Live Matches',
      url: 'http://livescore-api.com/api-client/matches/live.json',
      params: {
        key: 'wUOF0E1DmdetayWk',
        secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl'
      }
    },
    {
      name: 'Live Scores',
      url: 'https://livescore-api.com/api-client/scores/live.json',
      params: {
        key: 'wUOF0E1DmdetayWk',
        secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl'
      }
    },
    {
      name: 'Fixtures Today',
      url: 'https://livescore-api.com/api-client/fixtures/list.json',
      params: {
        key: 'wUOF0E1DmdetayWk',
        secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
        date: 'today'
      }
    }
  ];

  for (const endpoint of endpoints) {
    console.log(`\n🧪 Test: ${endpoint.name}`);
    console.log(`📍 URL: ${endpoint.url}`);
    
    try {
      const startTime = Date.now();
      const response = await axios.get(endpoint.url, {
        params: endpoint.params,
        timeout: 10000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json'
        }
      });
      const elapsed = Date.now() - startTime;
      
      console.log(`✅ Risposta ricevuta in ${elapsed}ms`);
      console.log(`📊 Status: ${response.status}`);
      
      // Analizza la risposta
      const data = response.data;
      
      if (data.success === false) {
        console.log(`❌ API Error: ${data.error?.message || 'Unknown error'}`);
        continue;
      }
      
      // Cerca i match nella risposta
      const matches = data?.data?.match || data?.data?.fixtures || [];
      console.log(`📈 Partite trovate: ${matches.length}`);
      
      if (matches.length > 0) {
        console.log('\n🎉 PARTITE TROVATE!\n');
        
        // Mostra le prime 10 partite
        const displayMatches = matches.slice(0, 10);
        displayMatches.forEach((match, index) => {
          const home = match.home?.name || match.home_name || 'N/A';
          const away = match.away?.name || match.away_name || 'N/A';
          const homeScore = match.home?.goals || match.home_goals || match.score?.split('-')[0]?.trim() || '0';
          const awayScore = match.away?.goals || match.away_goals || match.score?.split('-')[1]?.trim() || '0';
          const status = match.status || match.time || 'N/A';
          const league = match.league?.name || match.competition?.name || match.competition_name || 'N/A';
          const elapsed = match.elapsed !== null && match.elapsed !== undefined ? `${match.elapsed}'` : '';
          
          console.log(`   ${index + 1}. ${home} ${homeScore}-${awayScore} ${away} ${elapsed}`);
          console.log(`      League: ${league}`);
          console.log(`      Status: ${status}`);
          console.log('');
        });
        
        if (matches.length > 10) {
          console.log(`   ... e altre ${matches.length - 10} partite\n`);
        }
        
        // Filtra partite LIVE
        const liveMatches = matches.filter(match => {
          return match.elapsed !== null && match.elapsed !== undefined ||
                 (match.status && (
                   match.status.includes('LIVE') || 
                   match.status.includes('IN_PLAY') || 
                   match.status.includes('1H') || 
                   match.status.includes('2H') ||
                   match.status.includes('HT')
                 ));
        });
        
        if (liveMatches.length > 0) {
          console.log(`🔴 PARTITE LIVE ADESSO: ${liveMatches.length}`);
          liveMatches.slice(0, 5).forEach((match, index) => {
            const home = match.home?.name || match.home_name || 'N/A';
            const away = match.away?.name || match.away_name || 'N/A';
            const homeScore = match.home?.goals || match.home_goals || '0';
            const awayScore = match.away?.goals || match.away_goals || '0';
            const elapsed = match.elapsed || '?';
            console.log(`   ${index + 1}. ${home} ${homeScore}-${awayScore} ${away} (${elapsed}')`);
          });
        } else {
          console.log('⏸️  Nessuna partita LIVE al momento (potrebbero essere programmate per più tardi)');
        }
      } else {
        console.log('⚠️  Nessuna partita trovata per oggi');
      }
      
    } catch (error) {
      console.log(`❌ Errore: ${error.message}`);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Data:`, error.response.data);
      }
    }
  }
  
  console.log('\n============================================================');
  console.log('🏁 Test completato');
}

testLiveMatches();