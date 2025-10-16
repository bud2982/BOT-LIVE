const axios = require('axios');

console.log('🧪 TEST SERVER LOCALE');
console.log('============================================================');
console.log(`⏰ Ora: ${new Date().toLocaleString('it-IT')}`);
console.log('');

async function testLocalServer() {
  // Aspetta 3 secondi per dare tempo al server di avviarsi
  console.log('⏳ Attendo 3 secondi per l\'avvio del server...');
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  const baseUrl = 'http://localhost:3001';
  
  // Test 1: Health check
  console.log('\n🧪 Test 1: Health Check');
  console.log('─'.repeat(60));
  try {
    const response = await axios.get(`${baseUrl}/api/test`, { timeout: 5000 });
    console.log(`✅ Status: ${response.status}`);
    console.log(`📦 Risposta:`, response.data);
  } catch (error) {
    console.log(`❌ Errore: ${error.message}`);
  }
  
  // Test 2: Partite di oggi
  console.log('\n🧪 Test 2: Partite di Oggi');
  console.log('─'.repeat(60));
  try {
    const response = await axios.get(`${baseUrl}/api/livescore`, { timeout: 15000 });
    console.log(`✅ Status: ${response.status}`);
    console.log(`📈 Partite trovate: ${response.data.matches?.length || 0}`);
    console.log(`🔗 Fonte: ${response.data.source}`);
    
    if (response.data.matches && response.data.matches.length > 0) {
      console.log('\n🎉 PRIME 5 PARTITE:\n');
      response.data.matches.slice(0, 5).forEach((match, index) => {
        console.log(`${index + 1}. ${match.home} vs ${match.away}`);
        console.log(`   League: ${match.league} | Paese: ${match.country}`);
      });
    }
  } catch (error) {
    console.log(`❌ Errore: ${error.message}`);
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Messaggio: ${error.response.data.message}`);
    }
  }
  
  // Test 3: Partite LIVE
  console.log('\n🧪 Test 3: Partite LIVE');
  console.log('─'.repeat(60));
  try {
    const response = await axios.get(`${baseUrl}/api/live`, { timeout: 15000 });
    console.log(`✅ Status: ${response.status}`);
    console.log(`🔴 Partite LIVE: ${response.data.matches?.length || 0}`);
    
    if (response.data.matches && response.data.matches.length > 0) {
      console.log('\n🔴 PARTITE LIVE:\n');
      response.data.matches.slice(0, 5).forEach((match, index) => {
        console.log(`${index + 1}. ${match.home} ${match.homeScore}-${match.awayScore} ${match.away}`);
        console.log(`   Minuto: ${match.elapsed}' | League: ${match.league}`);
      });
    }
  } catch (error) {
    console.log(`❌ Errore: ${error.message}`);
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Messaggio: ${error.response.data.message}`);
    }
  }
  
  console.log('\n============================================================');
  console.log('🏁 Test completato');
  console.log('\n💡 Per fermare il server, chiudi la finestra PowerShell separata');
}

testLocalServer();