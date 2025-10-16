const axios = require('axios');

const RENDER_URL = 'https://bot-live-proxy.onrender.com';

console.log('🔥 TEST COLD START - Render Free Tier');
console.log('⏰ Timeout esteso a 90 secondi per il risveglio del server...\n');

async function testColdStart() {
  const startTime = Date.now();
  
  try {
    console.log('📡 Tentativo di connessione a:', RENDER_URL + '/api/test');
    console.log('⏳ Attendi... (può richiedere fino a 60 secondi)');
    
    const response = await axios.get(`${RENDER_URL}/api/test`, {
      timeout: 90000 // 90 secondi
    });
    
    const duration = Math.round((Date.now() - startTime) / 1000);
    
    console.log('\n✅ SERVER ONLINE!');
    console.log(`⏱️  Tempo di risposta: ${duration} secondi`);
    console.log('📊 Status:', response.status);
    console.log('📦 Risposta:', JSON.stringify(response.data, null, 2));
    
    if (duration > 30) {
      console.log('\n⚠️  NOTA: Il server era in sleep mode (piano gratuito Render)');
      console.log('   Il primo accesso richiede 30-60 secondi per il risveglio.');
      console.log('   Gli accessi successivi saranno più veloci.');
    }
    
    // Ora testa le API
    console.log('\n🔄 Test API LiveScore...');
    const livescoreResponse = await axios.get(`${RENDER_URL}/api/livescore`, {
      timeout: 60000
    });
    
    console.log('✅ API LiveScore risponde!');
    console.log(`📈 Partite trovate: ${livescoreResponse.data.matches?.length || 0}`);
    
    if (livescoreResponse.data.matches?.length > 0) {
      console.log('\n📋 Prime 3 partite:');
      livescoreResponse.data.matches.slice(0, 3).forEach((match, i) => {
        console.log(`   ${i + 1}. ${match.home} vs ${match.away}`);
        console.log(`      Score: ${match.homeScore || 0} - ${match.awayScore || 0}`);
        console.log(`      League: ${match.league}`);
      });
    }
    
    console.log('\n🎉 TUTTO FUNZIONA CORRETTAMENTE!');
    
  } catch (error) {
    const duration = Math.round((Date.now() - startTime) / 1000);
    
    console.log('\n❌ ERRORE dopo', duration, 'secondi');
    
    if (error.code === 'ECONNABORTED') {
      console.log('⏱️  Timeout: Il server non risponde nemmeno dopo 90 secondi');
      console.log('\n🔍 POSSIBILI CAUSE:');
      console.log('   1. Server crashato o non avviato su Render');
      console.log('   2. Errore nel deployment');
      console.log('   3. Servizio sospeso (verifica dashboard Render)');
      console.log('\n🔧 AZIONI:');
      console.log('   1. Vai su https://dashboard.render.com/');
      console.log('   2. Verifica lo stato del servizio "bot-live-proxy"');
      console.log('   3. Controlla i logs per errori');
      console.log('   4. Prova "Manual Deploy" → "Clear build cache & deploy"');
    } else if (error.response) {
      console.log('📊 Status:', error.response.status);
      console.log('💬 Errore:', error.response.data);
    } else {
      console.log('💥 Errore:', error.message);
    }
  }
}

testColdStart();