const FootballScraperToday = require('./football_scraper_today');

console.log('🧪 TEST SCRAPER CORRETTO');
console.log('============================================================');
console.log(`⏰ Ora attuale: ${new Date().toLocaleString('it-IT')}`);
console.log('');

async function testScraper() {
  console.log('🔄 Inizializzazione scraper...');
  const scraper = new FootballScraperToday();
  
  console.log('📡 Recupero partite di oggi...');
  const result = await scraper.getMatches();
  
  console.log('');
  console.log('============================================================');
  console.log('📊 RISULTATI');
  console.log('============================================================');
  
  if (result.success) {
    console.log(`✅ Successo!`);
    console.log(`📈 Partite trovate: ${result.matches.length}`);
    console.log(`🔗 Fonte: ${result.source}`);
    console.log('');
    
    if (result.matches.length > 0) {
      console.log('🎉 PRIME 10 PARTITE:\n');
      
      result.matches.slice(0, 10).forEach((match, index) => {
        console.log(`${index + 1}. ${match.home} vs ${match.away}`);
        console.log(`   Ora: ${match.time || 'N/A'} | League: ${match.league || 'N/A'}`);
        console.log(`   Paese: ${match.country || 'N/A'}`);
        console.log('');
      });
      
      if (result.matches.length > 10) {
        console.log(`... e altre ${result.matches.length - 10} partite\n`);
      }
    }
  } else {
    console.log(`❌ Errore: ${result.error}`);
    console.log(`💬 Messaggio: ${result.message}`);
  }
  
  console.log('============================================================');
  console.log('🏁 Test completato');
}

testScraper().catch(error => {
  console.error('💥 Errore:', error.message);
  console.error(error.stack);
});