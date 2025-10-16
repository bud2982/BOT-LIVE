const axios = require('axios');

async function testServerResponse() {
  console.log('🔍 Test risposta server Render.com...\n');
  
  try {
    const response = await axios.get('https://bot-live-proxy.onrender.com/api/livescore', {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      timeout: 30000
    });
    
    console.log('✅ Status:', response.status);
    console.log('✅ Success:', response.data.success);
    console.log('✅ Source:', response.data.source);
    console.log('✅ Total matches:', response.data.matches?.length || 0);
    
    if (response.data.matches && response.data.matches.length > 0) {
      console.log('\n📊 Esempio prima partita:');
      const firstMatch = response.data.matches[0];
      console.log('   ID:', firstMatch.id);
      console.log('   Home:', firstMatch.home);
      console.log('   Away:', firstMatch.away);
      console.log('   Start:', firstMatch.start);
      console.log('   League:', firstMatch.league);
      console.log('   Country:', firstMatch.country);
      console.log('   Goals:', `${firstMatch.goalsHome}-${firstMatch.goalsAway}`);
      
      // Verifica che l'ID sia presente
      if (!firstMatch.id) {
        console.log('\n❌ ERRORE: ID mancante!');
      } else {
        console.log('\n✅ ID presente e valido!');
      }
      
      // Verifica che il timestamp sia valido
      const startDate = new Date(firstMatch.start);
      if (isNaN(startDate.getTime())) {
        console.log('❌ ERRORE: Timestamp non valido!');
      } else {
        console.log('✅ Timestamp valido:', startDate.toLocaleString('it-IT'));
      }
      
      // Verifica che il paese sia presente
      if (!firstMatch.country || firstMatch.country === 'Other' || firstMatch.country === 'Unknown') {
        console.log('⚠️ WARNING: Paese non riconosciuto');
      } else {
        console.log('✅ Paese valido:', firstMatch.country);
      }
    }
    
  } catch (error) {
    console.log('❌ Errore:', error.message);
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', error.response.data);
    }
  }
}

testServerResponse();