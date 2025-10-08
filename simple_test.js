const FootballScraper = require('./football_scraper');

async function testScraper() {
  console.log('🧪 Test del nuovo sistema di scraping...');
  
  const scraper = new FootballScraper();
  const result = await scraper.getMatches();
  
  console.log('\n📊 RISULTATO:');
  console.log(JSON.stringify(result, null, 2));
}

testScraper().catch(console.error);