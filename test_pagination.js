const axios = require('axios');

console.log('🧪 TEST PAGINAZIONE API LIVESCORE');
console.log('============================================================\n');

async function testPagination() {
  const today = new Date().toISOString().split('T')[0];
  const allMatches = [];
  
  console.log(`📅 Data: ${today}\n`);
  
  // Prova a recuperare più pagine
  for (let page = 1; page <= 5; page++) {
    console.log(`\n📄 Tentativo pagina ${page}...`);
    
    try {
      const response = await axios.get('https://livescore-api.com/api-client/fixtures/matches.json', {
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: today,
          page: page
        },
        timeout: 15000
      });
      
      if (response.status === 200 && response.data) {
        const fixtures = response.data?.data?.fixtures || [];
        console.log(`✅ Pagina ${page}: ${fixtures.length} partite`);
        
        if (fixtures.length === 0) {
          console.log(`⚠️ Nessuna partita trovata, fine paginazione`);
          break;
        }
        
        // Aggiungi le partite uniche
        fixtures.forEach(match => {
          const key = `${match.home_name || match.home?.name}-${match.away_name || match.away?.name}`;
          if (!allMatches.find(m => m.key === key)) {
            allMatches.push({
              key,
              home: match.home_name || match.home?.name,
              away: match.away_name || match.away?.name,
              league: match.competition?.name || match.competition_name,
              page: page
            });
          }
        });
        
        console.log(`📊 Totale partite uniche finora: ${allMatches.length}`);
        
        // Se la pagina ha meno di 30 partite, probabilmente è l'ultima
        if (fixtures.length < 30) {
          console.log(`⚠️ Pagina incompleta (${fixtures.length} < 30), probabilmente ultima pagina`);
          break;
        }
        
      } else {
        console.log(`❌ Pagina ${page}: Status ${response.status}`);
        break;
      }
      
      // Delay tra le richieste
      await new Promise(resolve => setTimeout(resolve, 2000));
      
    } catch (error) {
      console.log(`❌ Errore pagina ${page}: ${error.message}`);
      if (error.response?.status === 404) {
        console.log(`⚠️ Pagina non trovata, fine paginazione`);
        break;
      }
    }
  }
  
  console.log(`\n============================================================`);
  console.log(`📊 RISULTATO FINALE`);
  console.log(`============================================================`);
  console.log(`✅ Totale partite uniche: ${allMatches.length}`);
  
  if (allMatches.length > 0) {
    console.log(`\n🎯 Tutte le partite trovate:\n`);
    allMatches.forEach((match, i) => {
      console.log(`${i + 1}. ${match.home} vs ${match.away}`);
      console.log(`   League: ${match.league} | Pagina: ${match.page}`);
    });
  }
}

testPagination();