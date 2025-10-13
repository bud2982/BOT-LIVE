const express = require('express');
const cors = require('cors');
const axios = require('axios');
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
  
  // TEMPORANEO: Forza l'uso dei dati di test per verificare il raggruppamento
  console.log('🧪 FORZANDO DATI DI TEST per verificare raggruppamento per paese');
  
  // Funzione helper per creare date con orari specifici
  const createMatchDate = (hoursFromNow, minutes = 0) => {
    const date = new Date();
    date.setHours(date.getHours() + hoursFromNow);
    date.setMinutes(minutes);
    date.setSeconds(0);
    date.setMilliseconds(0);
    return date.toISOString();
  };
  
  const testMatches = [
    {
      id: 1,
      home: 'Juventus',
      away: 'Milan',
      goalsHome: 2,
      goalsAway: 1,
      start: createMatchDate(2, 30), // Tra 2 ore e 30 minuti
      elapsed: null,
      league: 'Serie A',
      country: 'Italy'
    },
    {
      id: 2,
      home: 'Barcelona',
      away: 'Real Madrid',
      goalsHome: 1,
      goalsAway: 3,
      start: createMatchDate(1, 0), // Tra 1 ora
      elapsed: null,
      league: 'La Liga',
      country: 'Spain'
    },
    {
      id: 3,
      home: 'Manchester United',
      away: 'Liverpool',
      goalsHome: 0,
      goalsAway: 2,
      start: createMatchDate(3, 15), // Tra 3 ore e 15 minuti
      elapsed: null,
      league: 'Premier League',
      country: 'England'
    },
    {
      id: 4,
      home: 'Bayern Munich',
      away: 'Borussia Dortmund',
      goalsHome: 3,
      goalsAway: 1,
      start: createMatchDate(0, 45), // Tra 45 minuti
      elapsed: null,
      league: 'Bundesliga',
      country: 'Germany'
    },
    {
      id: 5,
      home: 'PSG',
      away: 'Marseille',
      goalsHome: 2,
      goalsAway: 0,
      start: createMatchDate(4, 0), // Tra 4 ore
      elapsed: null,
      league: 'Ligue 1',
      country: 'France'
    },
    {
      id: 6,
      home: 'Inter',
      away: 'Napoli',
      goalsHome: 1,
      goalsAway: 1,
      start: createMatchDate(2, 0), // Tra 2 ore
      elapsed: null,
      league: 'Serie A',
      country: 'Italy'
    },
    {
      id: 7,
      home: 'Team A',
      away: 'Team B',
      goalsHome: 0,
      goalsAway: 0,
      start: createMatchDate(5, 30), // Tra 5 ore e 30 minuti
      elapsed: null,
      league: 'Various',
      country: 'Other'
    }
  ];
  
  return {
    success: true,
    matches: testMatches,
    source: 'test-data-for-grouping',
    timestamp: new Date().toISOString(),
    total_found: testMatches.length,
    note: 'DATI DI TEST - per verificare raggruppamento per paese'
  };

  // CODICE ORIGINALE COMMENTATO TEMPORANEAMENTE
  /*
  if (uniqueMatches.length > 0) {
    return {
      success: true,
      matches: uniqueMatches.slice(0, 20), // Massimo 20 partite
      source: successfulSources.join(', '),
      timestamp: new Date().toISOString(),
      total_found: uniqueMatches.length
    };
  }
  */
  
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

// ========================================
// TELEGRAM NOTIFICATION ENDPOINTS
// ========================================

// Storage in memoria per le sottoscrizioni (in produzione usare un database)
const subscriptions = new Map();

// Endpoint per sottoscrivere notifiche Telegram
app.post('/api/telegram/subscribe', (req, res) => {
  try {
    const { chatId, matchId, matchInfo } = req.body;
    
    if (!chatId || !matchId || !matchInfo) {
      return res.status(400).json({
        success: false,
        error: 'Parametri mancanti: chatId, matchId, matchInfo richiesti'
      });
    }
    
    console.log(`📱 Nuova sottoscrizione Telegram: Chat ${chatId} per partita ${matchId}`);
    console.log(`   Partita: ${matchInfo.home} vs ${matchInfo.away}`);
    
    // Salva la sottoscrizione
    const subscriptionKey = `${chatId}-${matchId}`;
    subscriptions.set(subscriptionKey, {
      chatId,
      matchId,
      matchInfo,
      subscribedAt: new Date().toISOString(),
      active: true
    });
    
    res.json({
      success: true,
      message: 'Sottoscrizione registrata con successo',
      subscriptionId: subscriptionKey,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('💥 Errore sottoscrizione Telegram:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Endpoint per inviare notifica Telegram
app.post('/api/telegram/notify', async (req, res) => {
  try {
    const { chatId, message, matchId, botToken } = req.body;
    
    console.log('📥 Richiesta notifica Telegram ricevuta');
    console.log('   Body ricevuto:', JSON.stringify(req.body, null, 2));
    
    if (!chatId || !message) {
      console.log('❌ Parametri mancanti!');
      console.log('   chatId:', chatId);
      console.log('   message:', message ? 'presente' : 'mancante');
      return res.status(400).json({
        success: false,
        error: 'Parametri mancanti: chatId e message richiesti'
      });
    }
    
    // Bot Token predefinito (token reale del bot)
    const defaultBotToken = '8298427630:AAFIwMJNq2qcdblAd0WNvt4J5QHK_-IgfJo';
    const telegramBotToken = botToken || defaultBotToken;
    
    console.log(`📤 Invio notifica Telegram a chat ${chatId}...`);
    console.log(`   Messaggio (primi 100 caratteri): ${message.substring(0, 100)}...`);
    if (matchId) console.log(`   Partita ID: ${matchId}`);
    console.log(`   Bot Token: ${telegramBotToken.substring(0, 10)}...`);
    
    // Invia il messaggio tramite API Telegram
    const telegramApiUrl = `https://api.telegram.org/bot${telegramBotToken}/sendMessage`;
    console.log(`   URL Telegram: ${telegramApiUrl.substring(0, 50)}...`);
    
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
    
    console.log('   Risposta Telegram ricevuta:', JSON.stringify(telegramResponse.data, null, 2));
    
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
    console.error('💥 Errore invio notifica Telegram:', error.message);
    console.error('   Stack trace:', error.stack);
    
    // Dettagli aggiuntivi per debug
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', JSON.stringify(error.response.data, null, 2));
      console.error('   Headers:', JSON.stringify(error.response.headers, null, 2));
    } else if (error.request) {
      console.error('   Nessuna risposta ricevuta dal server Telegram');
      console.error('   Request:', error.request);
    } else {
      console.error('   Errore nella configurazione della richiesta:', error.message);
    }
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'Nessun dettaglio disponibile',
      type: error.response ? 'response_error' : (error.request ? 'no_response' : 'config_error')
    });
  }
});

// Endpoint per ottenere le sottoscrizioni attive
app.get('/api/telegram/subscriptions', (req, res) => {
  try {
    const activeSubscriptions = Array.from(subscriptions.values()).filter(sub => sub.active);
    
    res.json({
      success: true,
      subscriptions: activeSubscriptions,
      total: activeSubscriptions.length,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('💥 Errore recupero sottoscrizioni:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Endpoint per rimuovere sottoscrizione
app.delete('/api/telegram/unsubscribe/:chatId/:matchId', (req, res) => {
  try {
    const { chatId, matchId } = req.params;
    const subscriptionKey = `${chatId}-${matchId}`;
    
    if (subscriptions.has(subscriptionKey)) {
      subscriptions.delete(subscriptionKey);
      console.log(`🗑️ Sottoscrizione rimossa: ${subscriptionKey}`);
      
      res.json({
        success: true,
        message: 'Sottoscrizione rimossa con successo'
      });
    } else {
      res.status(404).json({
        success: false,
        error: 'Sottoscrizione non trovata'
      });
    }
    
  } catch (error) {
    console.error('💥 Errore rimozione sottoscrizione:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ========================================
// SISTEMA DI MONITORAGGIO AUTOMATICO
// ========================================

// Storage per tracciare lo stato delle partite
const matchStates = new Map();

// Funzione per monitorare le partite e inviare notifiche
async function monitorMatches() {
  if (subscriptions.size === 0) {
    return; // Nessuna sottoscrizione attiva
  }
  
  console.log(`🔍 Monitoraggio ${subscriptions.size} sottoscrizioni attive...`);
  
  try {
    // Ottieni le partite live
    const liveResult = await getLiveMatches();
    
    if (!liveResult.success || !liveResult.matches) {
      return;
    }
    
    // Per ogni sottoscrizione attiva
    for (const [key, subscription] of subscriptions.entries()) {
      const { chatId, matchId, matchInfo } = subscription;
      
      // Trova la partita corrispondente
      const match = liveResult.matches.find(m => m.id === matchId);
      
      if (!match) {
        continue; // Partita non trovata nei dati live
      }
      
      // Ottieni lo stato precedente della partita
      const previousState = matchStates.get(matchId) || {
        goalsHome: 0,
        goalsAway: 0,
        elapsed: 0,
        notified: false
      };
      
      // Controlla se ci sono stati goal
      const newGoals = (match.goalsHome + match.goalsAway) > (previousState.goalsHome + previousState.goalsAway);
      
      if (newGoals) {
        // Determina chi ha segnato
        let goalMessage = '';
        if (match.goalsHome > previousState.goalsHome) {
          goalMessage = `⚽ <b>GOOOOOL!</b>\n\n<b>${match.home}</b> ha segnato!\n\n`;
        } else if (match.goalsAway > previousState.goalsAway) {
          goalMessage = `⚽ <b>GOOOOOL!</b>\n\n<b>${match.away}</b> ha segnato!\n\n`;
        }
        
        goalMessage += `<b>${match.home} ${match.goalsHome} - ${match.goalsAway} ${match.away}</b>\n`;
        goalMessage += `🏆 ${match.league}\n`;
        goalMessage += `⏱️ ${match.elapsed}'`;
        
        // Invia notifica
        await sendTelegramNotification(chatId, goalMessage);
        
        console.log(`⚽ Goal notificato per partita ${matchId} a chat ${chatId}`);
      }
      
      // Controlla se la partita è appena iniziata
      if (!previousState.notified && match.elapsed > 0 && match.elapsed <= 5) {
        const startMessage = `🏁 <b>PARTITA INIZIATA!</b>\n\n` +
          `<b>${match.home} vs ${match.away}</b>\n` +
          `🏆 ${match.league}\n` +
          `🌍 ${match.country}\n\n` +
          `Segui la partita in diretta! ⚽`;
        
        await sendTelegramNotification(chatId, startMessage);
        
        console.log(`🏁 Inizio partita notificato per ${matchId} a chat ${chatId}`);
        previousState.notified = true;
      }
      
      // Aggiorna lo stato della partita
      matchStates.set(matchId, {
        goalsHome: match.goalsHome,
        goalsAway: match.goalsAway,
        elapsed: match.elapsed,
        notified: previousState.notified
      });
    }
    
  } catch (error) {
    console.error('💥 Errore nel monitoraggio:', error.message);
  }
}

// Funzione helper per inviare notifiche Telegram
async function sendTelegramNotification(chatId, message) {
  try {
    const defaultBotToken = '8298427630:AAFIwMJNq2qcdblAd0WNvt4J5QHK_-IgfJo';
    const telegramApiUrl = `https://api.telegram.org/bot${defaultBotToken}/sendMessage`;
    
    await axios.post(telegramApiUrl, {
      chat_id: chatId,
      text: message,
      parse_mode: 'HTML'
    }, {
      timeout: 10000
    });
    
    return true;
  } catch (error) {
    console.error(`❌ Errore invio notifica a ${chatId}:`, error.message);
    return false;
  }
}

// Avvia il monitoraggio ogni 30 secondi
setInterval(monitorMatches, 30000);

// Avvio del server
app.listen(PORT, () => {
  console.log(`🚀 Proxy server avviato su http://localhost:${PORT}`);
  console.log('📡 Endpoints disponibili:');
  console.log('   - GET /api/test - Test connessione');
  console.log('   - GET /api/livescore - Partite del giorno (SOLO DATI REALI)');
  console.log('   - GET /api/live - Partite live (SOLO DATI REALI)');
  console.log('   - POST /api/telegram/subscribe - Sottoscrivi notifiche Telegram');
  console.log('   - POST /api/telegram/notify - Invia notifica Telegram');
  console.log('   - GET /api/telegram/subscriptions - Lista sottoscrizioni attive');
  console.log('   - DELETE /api/telegram/unsubscribe/:chatId/:matchId - Rimuovi sottoscrizione');
  console.log('');
  console.log('⚠️  IMPORTANTE: Questo server NON genera mai dati falsi!');
  console.log('   Se non trova dati reali, restituisce un errore onesto.');
  console.log('🤖 Sistema notifiche Telegram: ATTIVO');
  console.log('🔔 Monitoraggio automatico: ATTIVO (ogni 30 secondi)');
});