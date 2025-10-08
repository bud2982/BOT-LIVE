const FootballScraperV2 = require('./football_scraper_v2');

async function testScraperV2() {
  console.log('🧪 Test del sistema di scraping v2.0 (API-focused)...');
  
  const scraper = new FootballScraperV2();
  const result = await scraper.getMatches();
  
  console.log('\n📊 RISULTATO:');
  console.log(JSON.stringify(result, null, 2));
}

testScraperV2().catch(console.error);