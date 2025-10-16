const axios = require('axios');

// Scraper per API UFFICIALE livescore-api.com (A PAGAMENTO)
class FootballScraperToday {
  constructor() {
    // Credenziali API ufficiali livescore-api.com
    // Usa variabili d'ambiente su Render, fallback per sviluppo locale
    this.apiKey = process.env.LIVESCORE_API_KEY || 'wUOF0E1DmdetayWk';
    this.apiSecret = process.env.LIVESCORE_API_SECRET || 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
    this.baseUrl = 'https://livescore-api.com/api-client';
    
    // Data di oggi nel formato YYYY-MM-DD
    const today = new Date().toISOString().split('T')[0];
    
    // ENDPOINT UFFICIALI LIVESCORE-API.COM
    this.sources = [
      // 1. PARTITE LIVE (massima priorità)
      {
        name: 'LiveScore API - Live Matches',
        url: `${this.baseUrl}/scores/live.json`,
        type: 'api',
        params: {
          key: this.apiKey,
          secret: this.apiSecret
        },
        priority: 1
      },
      
      // 2. FIXTURES DI OGGI (tutte le partite programmate)
      {
        name: 'LiveScore API - Today Fixtures',
        url: `${this.baseUrl}/fixtures/matches.json`,
        type: 'api',
        params: {
          key: this.apiKey,
          secret: this.apiSecret,
          date: today
        },
        priority: 2
      }
    ];
    
    // Cache per ridurre chiamate API (60 secondi)
    this.cache = {
      data: null,
      timestamp: null,
      ttl: 60000 // 60 secondi
    };
  }

  getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json',
      'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8',
      'Connection': 'keep-alive'
    };
  }

  async randomDelay() {
    const delay = Math.random() * 500 + 300; // 300-800ms
    await new Promise(resolve => setTimeout(resolve, delay));
  }

  // Metodo per determinare la nazione dalla lega
  getCountryFromLeague(league) {
    if (!league) return 'Other';
    
    const leagueCountryMap = {
      // Europa
      'Premier League': 'England',
      'Championship': 'England',
      'League One': 'England',
      'League Two': 'England',
      'La Liga': 'Spain',
      'Segunda División': 'Spain',
      'Serie A': 'Italy',
      'Serie B': 'Italy',
      'Bundesliga': 'Germany',
      '2. Bundesliga': 'Germany',
      'Ligue 1': 'France',
      'Ligue 2': 'France',
      'Eredivisie': 'Netherlands',
      'Primeira Liga': 'Portugal',
      'Ekstraklasa': 'Poland',
      'Super League': 'Greece',
      
      // Asia
      'J. League': 'Japan',
      'J. League 2': 'Japan',
      'K-League 1': 'South Korea',
      'K-League 2': 'South Korea',
      'Chinese Super League': 'China',
      
      // Internazionali
      'Champions League': 'International',
      'Europa League': 'International',
      'World Cup': 'International',
      'Euro': 'International',
      'Copa America': 'International'
    };
    
    // Cerca corrispondenza esatta
    if (leagueCountryMap[league]) {
      return leagueCountryMap[league];
    }
    
    // Cerca corrispondenza parziale
    for (const [leagueName, country] of Object.entries(leagueCountryMap)) {
      if (league.toLowerCase().includes(leagueName.toLowerCase()) || 
          leagueName.toLowerCase().includes(league.toLowerCase())) {
        return country;
      }
    }
    
    // Fallback basato su parole chiave
    const leagueLower = league.toLowerCase();
    if (leagueLower.includes('premier') || leagueLower.includes('championship')) return 'England';
    if (leagueLower.includes('liga') || leagueLower.includes('spanish')) return 'Spain';
    if (leagueLower.includes('serie') || leagueLower.includes('italian')) return 'Italy';
    if (leagueLower.includes('bundesliga') || leagueLower.includes('german')) return 'Germany';
    if (leagueLower.includes('ligue') || leagueLower.includes('french')) return 'France';
    if (leagueLower.includes('eredivisie') || leagueLower.includes('dutch')) return 'Netherlands';
    if (leagueLower.includes('primeira') || leagueLower.includes('portuguese')) return 'Portugal';
    
    return 'Other';
  }

  parseLiveScoreAPI(data, sourceName) {
    const matches = [];
    try {
      // L'API ufficiale restituisce: { success: true, data: { match: [...] } }
      // oppure { success: true, data: { fixtures: [...] } }
      
      if (!data.success) {
        console.log(`❌ API Error: ${data.error || 'Unknown error'}`);
        return matches;
      }
      
      const matchesData = data?.data?.match || data?.data?.fixtures || [];
      
      if (!Array.isArray(matchesData)) {
        console.log(`⚠️ Formato dati non valido da ${sourceName}`);
        return matches;
      }
      
      console.log(`📦 Ricevuti ${matchesData.length} match da ${sourceName}`);
      
      for (const match of matchesData) {
        try {
          // Estrai data e ora
          let matchDate = new Date().toISOString().split('T')[0];
          let matchTime = '00:00';
          
          // L'API ufficiale usa 'date' e 'time'
          if (match.date) {
            matchDate = match.date;
          }
          
          // Il campo 'time' è nel formato "HH:MM:SS", estraiamo solo "HH:MM"
          if (match.time && match.time.includes(':')) {
            matchTime = match.time.substring(0, 5);
          }
          
          // Estrai punteggi (solo per partite live)
          let homeScore = '0';
          let awayScore = '0';
          
          if (match.score && typeof match.score === 'string') {
            const scoreParts = match.score.split('-').map(s => s.trim());
            if (scoreParts.length === 2) {
              homeScore = scoreParts[0] || '0';
              awayScore = scoreParts[1] || '0';
            }
          }
          
          // Estrai nomi squadre
          const homeName = match.home_name || match.home?.name || 'Team A';
          const awayName = match.away_name || match.away?.name || 'Team B';
          
          // Estrai lega - CORRETTO: usa competition.name
          const leagueName = match.competition?.name || match.competition_name || match.league?.name || 'Unknown League';
          
          // Estrai paese - se non disponibile, lo determiniamo dalla lega
          const countryName = match.country_name || match.country?.name || match.league?.country || '';
          
          // Estrai ID ufficiale se disponibile
          const matchId = match.id || match.fixture_id || null;
          
          // Estrai status e elapsed (solo per partite live)
          const status = match.status || 'SCHEDULED';
          const elapsed = match.elapsed || null;
          
          // Estrai location (stadio)
          const location = match.location || '';
          
          const parsedMatch = {
            id: matchId,
            home: homeName,
            away: awayName,
            homeScore: homeScore,
            awayScore: awayScore,
            status: status,
            league: leagueName,
            time: matchTime,
            country: countryName,
            date: matchDate,
            elapsed: elapsed,
            location: location,
            source: sourceName
          };
          
          matches.push(parsedMatch);
          
        } catch (matchError) {
          console.log(`⚠️ Errore parsing singola partita: ${matchError.message}`);
        }
      }
      
    } catch (error) {
      console.log(`❌ Errore parsing ${sourceName}: ${error.message}`);
    }
    
    return matches;
  }

  isValidMatch(match) {
    return match && 
           match.home && 
           match.away && 
           match.home.trim() !== '' && 
           match.away.trim() !== '' &&
           match.home !== match.away;
  }

  // Verifica se la cache è ancora valida
  isCacheValid() {
    if (!this.cache.data || !this.cache.timestamp) {
      return false;
    }
    
    const now = Date.now();
    const age = now - this.cache.timestamp;
    
    return age < this.cache.ttl;
  }

  async getMatches() {
    // Controlla cache
    if (this.isCacheValid()) {
      console.log('📦 Utilizzo cache (età: ' + Math.round((Date.now() - this.cache.timestamp) / 1000) + 's)');
      return this.cache.data;
    }
    
    console.log(`🚀 Avvio ricerca partite con API ufficiale livescore-api.com`);
    console.log(`🔑 API Key: ${this.apiKey.substring(0, 4)}...${this.apiKey.substring(12)}`);
    
    const allMatches = [];
    const successfulSources = [];
    let sourcesAttempted = 0;
    
    // Ordina le fonti per priorità
    const sortedSources = this.sources.sort((a, b) => (a.priority || 999) - (b.priority || 999));
    
    for (const source of sortedSources) {
      sourcesAttempted++;
      try {
        console.log(`🌐 [${sourcesAttempted}/${this.sources.length}] ${source.name}`);
        console.log(`   URL: ${source.url}`);
        
        await this.randomDelay();
        
        const config = {
          headers: this.getHeaders(),
          timeout: 15000,
          maxRedirects: 3,
          params: source.params
        };

        const response = await axios.get(source.url, config);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ Risposta ricevuta da ${source.name}`);
          
          // Verifica se l'API ha restituito un errore
          if (response.data.success === false) {
            console.log(`❌ API Error: ${response.data.error || 'Unknown error'}`);
            continue;
          }
          
          const matches = this.parseLiveScoreAPI(response.data, source.name);
          const validMatches = matches.filter(match => this.isValidMatch(match));
          
          if (validMatches.length > 0) {
            console.log(`🎯 ${source.name}: ${validMatches.length} partite valide trovate`);
            
            allMatches.push(...validMatches);
            successfulSources.push(source.name);
          } else {
            console.log(`⚠️ ${source.name}: Nessuna partita valida trovata`);
          }
        } else {
          console.log(`❌ ${source.name}: Risposta non valida (Status: ${response.status})`);
        }
      } catch (error) {
        console.log(`❌ Errore ${source.name}: ${error.message}`);
        if (error.response) {
          console.log(`📊 Status: ${error.response.status}`);
          if (error.response.data) {
            console.log(`📄 Response:`, JSON.stringify(error.response.data, null, 2));
          }
        }
      }
    }
    
    // Rimuovi duplicati
    const uniqueMatches = [];
    const seen = new Set();
    
    for (const match of allMatches) {
      // Usa l'ID ufficiale se disponibile, altrimenti crea una chiave
      const key = match.id || `${match.home.toLowerCase()}-${match.away.toLowerCase()}-${match.date}`;
      if (!seen.has(key)) {
        seen.add(key);
        uniqueMatches.push(match);
      }
    }
    
    if (uniqueMatches.length > 0) {
      console.log(`🎉 TOTALE: ${uniqueMatches.length} partite uniche trovate!`);
      console.log(`📊 Endpoint di successo: ${successfulSources.join(', ')}`);
      
      // Trasforma i dati nel formato atteso dal proxy
      const transformedMatches = uniqueMatches.map((match) => {
        // Combina date e time per creare il timestamp ISO completo
        let startTimestamp;
        if (match.date && match.time) {
          startTimestamp = new Date(`${match.date}T${match.time}:00`).toISOString();
        } else if (match.date) {
          startTimestamp = new Date(`${match.date}T00:00:00`).toISOString();
        } else {
          startTimestamp = new Date().toISOString();
        }
        
        // Genera un ID univoco se non presente
        const matchId = match.id || Math.abs(
          `${match.home}-${match.away}-${match.date}`.split('').reduce((hash, char) => {
            return ((hash << 5) - hash) + char.charCodeAt(0);
          }, 0)
        );
        
        return {
          id: matchId,
          home: match.home,
          away: match.away,
          goalsHome: parseInt(match.homeScore) || 0,
          goalsAway: parseInt(match.awayScore) || 0,
          start: startTimestamp,
          time: match.time, // Ora della partita (HH:MM)
          date: match.date, // Data della partita (YYYY-MM-DD)
          elapsed: match.elapsed || null,
          status: match.status,
          league: match.league,
          country: match.country || this.getCountryFromLeague(match.league),
          location: match.location || '', // Stadio
          source: match.source
        };
      });
      
      console.log(`✅ Trasformate ${transformedMatches.length} partite nel formato corretto`);
      if (transformedMatches.length > 0) {
        console.log(`🔍 Esempio: ${transformedMatches[0].home} vs ${transformedMatches[0].away} (${transformedMatches[0].league})`);
      }
      
      const result = {
        success: true,
        matches: transformedMatches,
        source: `LiveScore API Official: ${successfulSources.join(', ')}`,
        sources_successful: successfulSources.length,
        sources_total: this.sources.length,
        timestamp: new Date().toISOString(),
        date: new Date().toISOString().split('T')[0],
        total_matches: transformedMatches.length
      };
      
      // Salva in cache
      this.cache.data = result;
      this.cache.timestamp = Date.now();
      
      return result;
    }
    
    // Nessuna partita trovata
    console.log(`❌ Nessuna partita trovata da tutti gli endpoint`);
    const errorResult = {
      success: false,
      error: 'Nessuna partita trovata',
      message: `Provati ${this.sources.length} endpoint LiveScore API ufficiali. Nessun dato disponibile.`,
      sources_tried: this.sources.map(s => s.name),
      timestamp: new Date().toISOString()
    };
    
    return errorResult;
  }
}

module.exports = FootballScraperToday;