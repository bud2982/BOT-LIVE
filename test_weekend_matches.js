const axios = require('axios');

console.log('📅 TEST PARTITE WEEKEND');
console.log('============================================================');
console.log(`⏰ Ora attuale: ${new Date().toLocaleString('it-IT')}`);
console.log('');

async function testWeekendMatches() {
  // Test con diverse date
  const dates = [
    { label: 'Oggi (16 Ottobre)', value: '2025-10-16' },
    { label: 'Domani (17 Ottobre)', value: '2025-10-17' },
    { label: 'Sabato (18 Ottobre)', value: '2025-10-18' },
    { label: 'Domenica (19 Ottobre)', value: '2025-10-19' }
  ];

  for (const date of dates) {
    console.log(`\n📅 Test: ${date.label}`);
    console.log('─'.repeat(60));
    
    try {
      const response = await axios.get('https://livescore-api.com/api-client/fixtures/matches.json', {
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: date.value
        },
        timeout: 10000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json'
        }
      });
      
      console.log(`✅ Status: ${response.status}`);
      
      const data = response.data;
      const matches = data?.data?.match || data?.data?.fixtures || [];
      
      console.log(`📈 Partite trovate: ${matches.length}`);
      
      if (matches.length > 0) {
        console.log('\n🎉 PARTITE TROVATE!\n');
        
        // Mostra le prime 5 partite
        const displayMatches = matches.slice(0, 5);
        displayMatches.forEach((match, index) => {
          const home = match.home?.name || match.home_name || 'N/A';
          const away = match.away?.name || match.away_name || 'N/A';
          const time = match.time || match.fixture_time || 'N/A';
          const league = match.league?.name || match.competition?.name || match.competition_name || 'N/A';
          
          console.log(`   ${index + 1}. ${home} vs ${away}`);
          console.log(`      Ora: ${time} | League: ${league}`);
        });
        
        if (matches.length > 5) {
          console.log(`\n   ... e altre ${matches.length - 5} partite`);
        }
      } else {
        console.log('⚠️  Nessuna partita programmata');
      }
      
    } catch (error) {
      console.log(`❌ Errore: ${error.message}`);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
      }
    }
  }
  
  console.log('\n============================================================');
  console.log('🏁 Test completato');
}

testWeekendMatches();