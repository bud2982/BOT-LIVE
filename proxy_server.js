const express = require('express');
const cors = require('cors');
const axios = require('axios');
const cheerio = require('cheerio');
const FootballScraper = require('./football_scraper');
const FootballScraperToday = require('./football_scraper_today');

const app = express();
const PORT = 3001;

// Abilita CORS per tutte le richieste
app.use(cors());
app.use(express.json());

// Headers avanzati per simulare un browser reale con anti-detection
const getAdvancedHeaders = (referer = null) => {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/121.0'
  ];
  
  const languages = [
    'en-US,en;q=0.9,it;q=0.8',
    'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
    'en-GB,en;q=0.9,it;q=0.8',
    'en-US,en;q=0.5'
  ];
  
  const baseHeaders = {
    'User-Agent': userAgents[Math.floor(Math.random() * userAgents.length)],
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': languages[Math.floor(Math.random() * languages.length)],
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': referer ? 'same-origin' : 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
    'DNT': '1',
    'Sec-GPC': '1'
  };
  
  if (referer) {
    baseHeaders['Referer'] = referer;
  }
  
  return baseHeaders;
};

// Delay casuale per evitare detection
const randomDelay = (min = 1000, max = 3000) => {
  return new Promise(resolve => {
    const delay = Math.floor(Math.random() * (max - min + 1)) + min;
    setTimeout(resolve, delay);
  });
};

// Funzione per pulire i nomi delle squadre
const cleanTeamName = (name) => {
  if (!name) return '';
  return name
    .replace(/^\d+\s*/, '') // Rimuovi numeri all'inizio
    .replace(/\s*\d+$/, '') // Rimuovi numeri alla fine
    .replace(/[^\w\s]/g, ' ') // Sostituisci caratteri speciali con spazi
    .replace(/\s+/g, ' ') // Sostituisci spazi multipli con uno singolo
    .trim()
    .split(' ')
    .filter(word => word.length > 1) // Rimuovi parole di una lettera
    .slice(0, 3) // Prendi massimo 3 parole
    .join(' ');
};

// Funzione per validare una partita
const isValidMatch = (home, away, homeScore, awayScore) => {
  const cleanHome = cleanTeamName(home);
  const cleanAway = cleanTeamName(away);
  
  return cleanHome && 
         cleanAway && 
         cleanHome.length >= 3 && 
         cleanAway.length >= 3 && 
         cleanHome !== cleanAway &&
         !isNaN(homeScore) && 
         !isNaN(awayScore) &&
         homeScore >= 0 && 
         awayScore >= 0;
};

// Funzione per determinare il paese dalla lega
const getCountryFromLeague = (leagueName) => {
  if (!leagueName) return 'Other';
  
  const league = leagueName.toLowerCase();
  
  // Mappatura esatta delle leghe
  const exactMappings = {
    'premier league': 'England',
    'championship': 'England',
    'league one': 'England',
    'league two': 'England',
    'la liga': 'Spain',
    'segunda división': 'Spain',
    'segunda b': 'Spain',
    'serie a': 'Italy',
    'serie b': 'Italy',
    'bundesliga': 'Germany',
    '2. bundesliga': 'Germany',
    'ligue 1': 'France',
    'ligue 2': 'France',
    'eredivisie': 'Netherlands',
    'primeira liga': 'Portugal',
    'liga 3': 'Portugal',
    'segunda liga': 'Portugal',
    'j. league': 'Japan',
    'j. league 2': 'Japan',
    'k-league 1': 'South Korea',
    'k-league 2': 'South Korea',
    'pfl': 'Philippines',
    'champions league': 'International',
    'europa league': 'International',
    'world cup': 'International',
    'euro': 'International'
  };
  
  // Cerca corrispondenza esatta
  if (exactMappings[league]) {
    return exactMappings[league];
  }
  
  // Cerca corrispondenza parziale
  for (const [leagueName, country] of Object.entries(exactMappings)) {
    if (league.includes(leagueName) || leagueName.includes(league)) {
      return country;
    }
  }
  
  // Fallback basato su parole chiave
  if (league.includes('premier') || league.includes('championship')) return 'England';
  if (league.includes('liga') || league.includes('spanish')) return 'Spain';
  if (league.includes('serie') || league.includes('italian')) return 'Italy';
  if (league.includes('bundesliga') || league.includes('german')) return 'Germany';
  if (league.includes('ligue') || league.includes('french')) return 'France';
  if (league.includes('eredivisie') || league.includes('dutch')) return 'Netherlands';
  if (league.includes('primeira') || league.includes('portuguese')) return 'Portugal';
  if (league.includes('league') && league.includes('j')) return 'Japan';
  if (league.includes('league') && league.includes('k')) return 'South Korea';
  if (league.includes('pfl') || league.includes('philippines')) return 'Philippines';
  if (league.includes('chinese') || league.includes('china')) return 'China';
  
  return 'Other';
};

// Endpoint per recuperare partite dalle API ufficiali LiveScore
app.get('/api/livescore', async (req, res) => {
  try {
    console.log('🔄 Richiesta partite del giorno ricevuta - API ufficiali LiveScore');
    
    // USA SOLO IL NOSTRO SCRAPER CON API LIVESCORE UFFICIALI - NO FALLBACK
    const scraper = new FootballScraperToday();
    const result = await scraper.getMatches();
    
    if (result && result.success && result.matches && result.matches.length > 0) {
      console.log(`🎯 SUCCESSO! Trovate ${result.matches.length} partite REALI con API LiveScore`);
      console.log(`📋 Fonti di successo: ${result.sources_successful}/${result.sources_total}`);
      console.log(`📊 Fonte principale: ${result.source}`);
      
      // Converti il formato per compatibilità con l'app Flutter
      const formattedMatches = result.matches.map((match, index) => {
        // Debug: stampa i primi 2 match per vedere date e orari
        if (index < 2) {
          console.log(`🔍 DEBUG Match ${index + 1}: ${match.home} vs ${match.away}`);
          console.log(`🔍 DEBUG - date: "${match.date}", time: "${match.time}"`);
        }
        
        // Correggi il formato della data
        let startDate;
        if (match.date && match.time) {
          startDate = `${match.date}T${match.time}:00Z`;
          if (index < 2) {
            console.log(`🔍 DEBUG - startDate costruito: "${startDate}"`);
          }
        } else if (match.date) {
          startDate = `${match.date}T15:00:00Z`;
          if (index < 2) {
            console.log(`🔍 DEBUG - startDate con ora default: "${startDate}"`);
          }
        } else {
          startDate = new Date().toISOString();
          if (index < 2) {
            console.log(`🔍 DEBUG - startDate con data corrente: "${startDate}"`);
          }
        }
        
        const league = match.league || 'Unknown League';
        const country = getCountryFromLeague(league);
        
        return {
          id: index + 1,
          home: match.home,
          away: match.away,
          goalsHome: parseInt(match.homeScore) || 0,
          goalsAway: parseInt(match.awayScore) || 0,
          start: startDate,
          elapsed: match.status === 'LIVE' ? (match.time || null) : null,
          league: league,
          country: country
        };
      });
      
      return res.json({ 
        success: true, 
        matches: formattedMatches, 
        source: `livescore-api-${result.source}`,
        timestamp: result.timestamp,
        sources_successful: result.sources_successful,
        sources_total: result.sources_total,
        total_matches: formattedMatches.length
      });
    }
    
    // NESSUN FALLBACK - SOLO API LIVESCORE REALI
    console.log('❌ API LiveScore non disponibili - NESSUN FALLBACK ATTIVO');
    res.status(503).json({ 
      success: false, 
      error: 'API LiveScore temporaneamente non disponibili',
      message: 'Solo API LiveScore reali sono abilitate. Nessun dato fittizio.',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('💥 Errore generale:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Endpoint per recuperare partite live - SOLO API LIVESCORE REALI
app.get('/api/live', async (req, res) => {
  try {
    console.log('🔴 Richiesta partite LIVE ricevuta - SOLO API LiveScore REALI');
    
    // USA SOLO IL NOSTRO SCRAPER CON API LIVESCORE UFFICIALI - NO FALLBACK
    const scraper = new FootballScraperToday();
    const result = await scraper.getMatches();
    
    if (result && result.success && result.matches && result.matches.length > 0) {
      console.log(`🎯 SUCCESSO! Trovate ${result.matches.length} partite REALI con API LiveScore`);
      console.log(`📋 Fonti di successo: ${result.sources_successful}/${result.sources_total}`);
      console.log(`📊 Fonte principale: ${result.source}`);
      
      // Filtra solo le partite LIVE
      const liveMatches = result.matches.filter(match => 
        match.status === 'LIVE' || 
        match.status === 'IN_PLAY' || 
        match.elapsed || 
        match.time
      );
      
      return res.json({ 
        success: true, 
        matches: liveMatches, 
        source: `livescore-api-live-${result.source}`,
        timestamp: result.timestamp,
        sources_successful: result.sources_successful,
        sources_total: result.sources_total,
        total_matches: liveMatches.length
      });
    }
    
    // NESSUN FALLBACK - SOLO API LIVESCORE REALI
    console.log('❌ API LiveScore non disponibili per partite LIVE - NESSUN FALLBACK ATTIVO');
    res.status(503).json({ 
      success: false, 
      error: 'API LiveScore temporaneamente non disponibili per partite LIVE',
      message: 'Solo API LiveScore reali sono abilitate. Nessun dato fittizio.',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('💥 Errore LIVE:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Endpoint per ottenere partite divise per nazione
app.get('/api/matches-by-country', async (req, res) => {
  try {
    console.log('🌍 Richiesta partite divise per nazione ricevuta');
    
    const scraper = new FootballScraperToday();
    const result = await scraper.getMatches();
    
    if (result && result.success && result.matches && result.matches.length > 0) {
      // Raggruppa le partite per nazione
      const matchesByCountry = {};
      
      result.matches.forEach(match => {
        const country = match.country || 'Other';
        if (!matchesByCountry[country]) {
          matchesByCountry[country] = [];
        }
        matchesByCountry[country].push({
          id: match.id,
          home: match.home,
          away: match.away,
          goalsHome: parseInt(match.homeScore) || 0,
          goalsAway: parseInt(match.awayScore) || 0,
          start: match.date ? `${match.date}T${match.time || '15:00'}:00Z` : new Date().toISOString(),
          elapsed: match.status === 'LIVE' ? (match.time || null) : null,
          league: match.league || 'Unknown League',
          country: country
        });
      });
      
      // Ordina i paesi per numero di partite (decrescente)
      const sortedCountries = Object.keys(matchesByCountry).sort((a, b) => 
        matchesByCountry[b].length - matchesByCountry[a].length
      );
      
      const sortedMatchesByCountry = {};
      sortedCountries.forEach(country => {
        sortedMatchesByCountry[country] = matchesByCountry[country];
      });
      
      console.log(`🎯 Partite raggruppate per ${Object.keys(sortedMatchesByCountry).length} nazioni`);
      
      return res.json({
        success: true,
        matchesByCountry: sortedMatchesByCountry,
        countries: sortedCountries,
        totalMatches: result.matches.length,
        totalCountries: Object.keys(sortedMatchesByCountry).length,
        source: result.source,
        timestamp: result.timestamp
      });
    }
    
    res.status(503).json({ 
      success: false, 
      error: 'Nessuna partita disponibile per raggruppamento per nazione'
    });
    
  } catch (error) {
    console.error('💥 Errore matches-by-country:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Endpoint per registrare notifiche Telegram
app.post('/api/telegram/subscribe', (req, res) => {
  try {
    const { chatId, matchId, matchInfo } = req.body;
    
    if (!chatId || !matchId) {
      return res.status(400).json({ 
        success: false, 
        error: 'chatId e matchId sono richiesti' 
      });
    }
    
    // Qui implementeremo la logica per salvare le sottoscrizioni
    // Per ora restituiamo successo
    console.log(`📱 Nuova sottoscrizione Telegram: Chat ${chatId} per partita ${matchId}`);
    
    res.json({
      success: true,
      message: 'Sottoscrizione registrata con successo',
      chatId: chatId,
      matchId: matchId,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('💥 Errore telegram subscribe:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Endpoint per inviare notifiche Telegram
app.post('/api/telegram/notify', async (req, res) => {
  try {
    const { chatId, message, matchId, botToken } = req.body;
    
    if (!chatId || !message) {
      return res.status(400).json({ 
        success: false, 
        error: 'chatId e message sono richiesti' 
      });
    }
    
    // Bot Token predefinito (token reale del bot)
    const defaultBotToken = '8298427630:AAFIwMJNq2qcdblAd0WNvt4J5QHK_-IgfJo';
    const telegramBotToken = botToken || defaultBotToken;
    
    console.log(`📤 Invio notifica Telegram a chat ${chatId}...`);
    
    // Invia il messaggio tramite API Telegram
    const telegramApiUrl = `https://api.telegram.org/bot${telegramBotToken}/sendMessage`;
    
    const telegramResponse = await axios.post(telegramApiUrl, {
      chat_id: chatId,
      text: message,
      parse_mode: 'HTML'
    }, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    
    if (telegramResponse.data.ok) {
      console.log(`✅ Notifica Telegram inviata con successo a chat ${chatId}`);
      res.json({
        success: true,
        message: 'Notifica inviata con successo',
        chatId: chatId,
        messageId: telegramResponse.data.result.message_id,
        timestamp: new Date().toISOString()
      });
    } else {
      console.log(`❌ Errore API Telegram: ${telegramResponse.data.description}`);
      res.status(400).json({
        success: false,
        error: `Errore Telegram: ${telegramResponse.data.description}`,
        errorCode: telegramResponse.data.error_code
      });
    }
    
  } catch (error) {
    console.error('💥 Errore telegram notify:', error.message);
    
    // Gestisci errori specifici di Telegram
    if (error.response && error.response.data) {
      const telegramError = error.response.data;
      return res.status(400).json({
        success: false,
        error: `Errore Telegram: ${telegramError.description || error.message}`,
        errorCode: telegramError.error_code
      });
    }
    
    res.status(500).json({ 
      success: false, 
      error: error.message,
      details: 'Errore nella comunicazione con Telegram'
    });
  }
});

// Endpoint di test
app.get('/api/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Proxy server funzionante!',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Proxy server avviato su http://localhost:${PORT}`);
  console.log(`📡 Endpoints disponibili:`);
  console.log(`   - GET /api/test - Test connessione`);
  console.log(`   - GET /api/livescore - Partite del giorno (API ufficiali LiveScore)`);
  console.log(`   - GET /api/live - Partite live`);
  console.log(`   - GET /api/matches-by-country - Partite divise per nazione`);
  console.log(`   - POST /api/telegram/subscribe - Registra notifiche Telegram`);
  console.log(`   - POST /api/telegram/notify - Invia notifiche Telegram`);
});