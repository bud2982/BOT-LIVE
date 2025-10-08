const FootballScraperToday = require('./football_scraper_today.js');

async function testFullScraper() {
  console.log('🧪 Testando il sistema completo di scraping...\n');
  
  const scraper = new FootballScraperToday();
  
  try {
    const result = await scraper.getMatches();
    
    console.log(`🎯 RISULTATI FINALI:`);
    console.log(`📊 Successo: ${result.success}`);
    
    if (result.success && result.matches) {
      const matches = result.matches;
      console.log(`📊 Totale partite trovate: ${matches.length}`);
      console.log(`📊 Fonti di successo: ${result.sources_successful}/${result.sources_total}`);
      
      // Raggruppa per fonte
      const sourceStats = {};
      matches.forEach(match => {
        const source = match.source || 'Unknown';
        sourceStats[source] = (sourceStats[source] || 0) + 1;
      });
      
      console.log('\n📈 STATISTICHE PER FONTE:');
      Object.entries(sourceStats)
        .sort(([,a], [,b]) => b - a)
        .forEach(([source, count]) => {
          console.log(`  ${source}: ${count} partite`);
        });
      
      if (matches.length > 0) {
        console.log('\n⚽ PRIME 5 PARTITE:');
        matches.slice(0, 5).forEach((match, i) => {
          console.log(`  ${i+1}. ${match.home} vs ${match.away} (${match.league}) - ${match.status}`);
        });
      }
      
      // Verifica se Live-Score API ha contribuito
      const liveScoreMatches = matches.filter(m => m.source === 'Live-Score API Free');
      if (liveScoreMatches.length > 0) {
        console.log(`\n✅ Live-Score API ha contribuito con ${liveScoreMatches.length} partite!`);
      } else {
        console.log(`\n⚠️  Live-Score API non ha contribuito partite (normale se non ci sono partite oggi)`);
      }
    } else {
      console.log(`❌ Nessuna partita trovata: ${result.error || result.message}`);
    }
    
  } catch (error) {
    console.error('❌ Errore durante il test:', error.message);
  }
}

testFullScraper();