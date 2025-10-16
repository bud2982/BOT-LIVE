const axios = require('axios');

const API_KEY = 'wUOF0E1DmdetayWk';
const API_SECRET = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';

// Test con date specifiche (weekend con molte partite)
const testDates = [
  'today',
  '2025-10-18', // Sabato
  '2025-10-19', // Domenica
  '2024-10-16'  // Data passata per test
];

console.log('🔍 TEST API LIVESCORE CON DATE SPECIFICHE');
console.log('='.repeat(60));

async function testWithDate(date) {
  console.log(`\n📅 Test con data: ${date}`);
  
  try {
    const response = await axios.get('https://livescore-api.com/api-client/fixtures/list.json', {
      params: {
        key: API_KEY,
        secret: API_SECRET,
        date: date
      },
      timeout: 15000
    });
    
    const matches = response.data?.data?.fixtures || response.data?.data?.match || [];
    const matchCount = Array.isArray(matches) ? matches.length : 0;
    
    console.log(`   ✅ Risposta ricevuta`);
    console.log(`   📈 Partite trovate: ${matchCount}`);
    
    if (matchCount > 0) {
      console.log(`   🎉 SUCCESSO! Trovate ${matchCount} partite`);
      console.log(`\n   📋 Prime 5 partite:`);
      matches.slice(0, 5).forEach((match, i) => {
        const home = match.home?.name || match.home_name || 'N/A';
        const away = match.away?.name || match.away_name || 'N/A';
        const league = match.league?.name || match.competition_name || 'N/A';
        console.log(`      ${i + 1}. ${home} vs ${away}`);
        console.log(`         League: ${league}`);
      });
      return true;
    } else {
      console.log(`   ⚠️  Nessuna partita per questa data`);
      return false;
    }
    
  } catch (error) {
    console.log(`   ❌ Errore: ${error.message}`);
    return false;
  }
}

async function runTests() {
  let foundMatches = false;
  
  for (const date of testDates) {
    const result = await testWithDate(date);
    if (result) {
      foundMatches = true;
      break; // Ferma al primo successo
    }
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  console.log('\n' + '='.repeat(60));
  
  if (foundMatches) {
    console.log('✅ API LIVESCORE FUNZIONANTI E VERIFICATE!');
    console.log('   Le credenziali sono valide e le API restituiscono dati.');
    console.log('   Il problema era solo l\'assenza di partite oggi.');
  } else {
    console.log('⚠️  Nessuna partita trovata in nessuna delle date testate');
    console.log('   Possibile problema con le API o il piano sottoscritto');
  }
  
  console.log('='.repeat(60));
}

runTests();