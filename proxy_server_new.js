const express = require('express');
const cors = require('cors');
const FootballScraperV2 = require('./football_scraper_v2');
const FootballScraperRSS = require('./football_scraper');
const FootballScraperToday = require('./football_scraper_today');

const app = express();
const PORT = 3001;

// Abilita CORS per tutte le richieste
app.use(cors());
app.use(express.json());

// Endpoint di test
app.get('/api/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Proxy server funzionante!',
    timestamp: new Date().toISOString()
  });
});

// Funzione per combinare risultati da più scraper
async function getTodayMatches() {
  console.log('🔄 Ricerca partite del giorno da fonti multiple...');
  
  const scrapers = [
    { name: 'TODAY-SPECIALIZED', instance: new FootballScraperToday() },
    { name: 'API-V2', instance: new FootballScraperV2() },
    { name: 'RSS', instance: new FootballScraperRSS() }
  ];
  
  let allMatches = [];
  let successfulSources = [];
  
  for (const scraper of scrapers) {
    try {
      console.log(`🌐 Tentativo con ${scraper.name}...`);
      const result = await scraper.instance.getMatches();
      
      if (result.success && result.matches && result.matches.length > 0) {
        console.log(`✅ ${scraper.name}: ${result.matches.length} partite trovate`);
        
        // Filtra partite di oggi
        const today = new Date().toISOString().split('T')[0];
        const todayMatches = result.matches.filter(match => {
          if (!match.start) return false;
          const matchDate = new Date(match.start).toISOString().split('T')[0];
          return matchDate === today;
        });
        
        if (todayMatches.length > 0) {
          allMatches = allMatches.concat(todayMatches);
          successfulSources.push(`${result.source} (${todayMatches.length} partite)`);
        }
      }
    } catch (error) {
      console.log(`❌ Errore ${scraper.name}: ${error.message}`);
    }
  }
  
  // Rimuovi duplicati basandosi su home + away
  const uniqueMatches = [];
  const seen = new Set();
  
  for (const match of allMatches) {
    const key = `${match.home}-${match.away}`;
    if (!seen.has(key)) {
      seen.add(key);
      uniqueMatches.push(match);
    }
  }
  
  if (uniqueMatches.length > 0) {
    return {
      success: true,
      matches: uniqueMatches.slice(0, 20), // Massimo 20 partite
      source: successfulSources.join(', '),
      timestamp: new Date().toISOString(),
      total_found: uniqueMatches.length
    };
  }
  
  return {
    success: false,
    error: 'Nessuna partita di oggi trovata',
    message: 'Non sono state trovate partite per la data odierna dalle fonti disponibili. Nessun dato finto generato.',
    timestamp: new Date().toISOString()
  };
}

// Endpoint per recuperare partite - SOLO DATI REALI
app.get('/api/livescore', async (req, res) => {
  try {
    console.log('🔄 Richiesta partite del giorno ricevuta');
    
    const result = await getTodayMatches();
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(503).json(result);
    }
    
  } catch (error) {
    console.error('💥 Errore generale:', error.message);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      message: 'Errore interno del server. Nessun dato finto generato.',
      timestamp: new Date().toISOString()
    });
  }
});

// Funzione per ottenere partite live
async function getLiveMatches() {
  console.log('🔴 Ricerca partite LIVE da fonti multiple...');
  
  const scrapers = [
    { name: 'TODAY-SPECIALIZED', instance: new FootballScraperToday() },
    { name: 'API-V2', instance: new FootballScraperV2() },
    { name: 'RSS', instance: new FootballScraperRSS() }
  ];
  
  let allMatches = [];
  let successfulSources = [];
  
  for (const scraper of scrapers) {
    try {
      console.log(`🌐 Tentativo LIVE con ${scraper.name}...`);
      const result = await scraper.instance.getMatches();
      
      if (result.success && result.matches && result.matches.length > 0) {
        // Filtra solo partite in corso (con elapsed time o status specifici)
        const liveMatches = result.matches.filter(match => {
          return match.elapsed !== null && match.elapsed !== undefined ||
                 (match.status && (
                   match.status.includes('LIVE') || 
                   match.status.includes('IN_PLAY') || 
                   match.status.includes('1H') || 
                   match.status.includes('2H') ||
                   match.status.includes('HT')
                 ));
        });
        
        if (liveMatches.length > 0) {
          console.log(`🔴 ${scraper.name}: ${liveMatches.length} partite LIVE trovate`);
          allMatches = allMatches.concat(liveMatches);
          successfulSources.push(`${result.source} (${liveMatches.length} live)`);
        }
      }
    } catch (error) {
      console.log(`❌ Errore LIVE ${scraper.name}: ${error.message}`);
    }
  }
  
  // Rimuovi duplicati
  const uniqueMatches = [];
  const seen = new Set();
  
  for (const match of allMatches) {
    const key = `${match.home}-${match.away}`;
    if (!seen.has(key)) {
      seen.add(key);
      uniqueMatches.push(match);
    }
  }
  
  if (uniqueMatches.length > 0) {
    return {
      success: true,
      matches: uniqueMatches.slice(0, 10), // Massimo 10 partite live
      source: successfulSources.join(', ').replace(/real-/g, 'live-'),
      timestamp: new Date().toISOString(),
      total_live: uniqueMatches.length
    };
  }
  
  return {
    success: false,
    error: 'Nessuna partita live trovata',
    message: 'Non ci sono partite in corso al momento. Nessun dato finto generato.',
    timestamp: new Date().toISOString()
  };
}

// Endpoint per partite live - SOLO DATI REALI
app.get('/api/live', async (req, res) => {
  try {
    console.log('🔴 Richiesta partite LIVE ricevuta');
    
    const result = await getLiveMatches();
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(503).json(result);
    }
    
  } catch (error) {
    console.error('💥 Errore generale partite live:', error.message);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      message: 'Errore interno del server. Nessun dato finto generato.',
      timestamp: new Date().toISOString()
    });
  }
});

// Avvio del server
app.listen(PORT, () => {
  console.log(`🚀 Proxy server avviato su http://localhost:${PORT}`);
  console.log('📡 Endpoints disponibili:');
  console.log('   - GET /api/test - Test connessione');
  console.log('   - GET /api/livescore - Partite del giorno (SOLO DATI REALI)');
  console.log('   - GET /api/live - Partite live (SOLO DATI REALI)');
  console.log('');
  console.log('⚠️  IMPORTANTE: Questo server NON genera mai dati falsi!');
  console.log('   Se non trova dati reali, restituisce un errore onesto.');
});