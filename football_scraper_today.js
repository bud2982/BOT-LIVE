const axios = require('axios');

// Scraper specializzato per partite di OGGI - SOLO API UFFICIALI
class FootballScraperToday {
  constructor() {
    // SOLO API LIVESCORE UFFICIALI E VERIFICATE - NO FALLBACK
    this.sources = [
      // LIVESCORE API UFFICIALE (SOLO QUESTE)
      {
        name: 'LiveScore API Live Matches',
        url: 'http://livescore-api.com/api-client/matches/live.json',
        type: 'api',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl'
        },
        priority: 1
      },
      {
        name: 'LiveScore API Scores',
        url: 'https://livescore-api.com/api-client/scores/live.json',
        type: 'api',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl'
        },
        priority: 2
      },
      {
        name: 'LiveScore API Fixtures Today',
        url: 'https://livescore-api.com/api-client/fixtures/list.json',
        type: 'api',
        params: {
          key: 'wUOF0E1DmdetayWk',
          secret: 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl',
          date: 'today'
        },
        priority: 3
      }
    ];
  }

  getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/html, */*',
      'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache'
    };
  }

  async randomDelay() {
    const delay = Math.random() * 1000 + 500; // 500-1500ms
    await new Promise(resolve => setTimeout(resolve, delay));
  }

  // Metodo per determinare la nazione dalla lega
  getCountryFromLeague(league) {
    if (!league) return 'International';
    
    const leagueCountryMap = {
      // Europa
      'Premier League': 'England',
      'Championship': 'England',
      'League One': 'England',
      'League Two': 'England',
      'La Liga': 'Spain',
      'Segunda División': 'Spain',
      'Segunda B': 'Spain',
      'Serie A': 'Italy',
      'Serie B': 'Italy',
      'Bundesliga': 'Germany',
      '2. Bundesliga': 'Germany',
      'Ligue 1': 'France',
      'Ligue 2': 'France',
      'Eredivisie': 'Netherlands',
      'Primeira Liga': 'Portugal',
      'Liga 3': 'Portugal',
      'Segunda Liga': 'Portugal',
      'Ekstraklasa': 'Poland',
      '2nd Liga': 'Poland',
      'Super League': 'Greece',
      'Super League 2': 'Greece',
      'Campeonato de Portugal': 'Portugal',
      '3rd league': 'Czech Republic',
      
      // Asia
      'J. League': 'Japan',
      'J. League 2': 'Japan',
      'K-League 1': 'South Korea',
      'K-League 2': 'South Korea',
      'League 1': 'China',
      'PFL': 'Philippines',
      
      // Europa dell'Est
      'Premier League': 'Ukraine',
      'Football National League': 'Russia',
      
      // Internazionali
      'Champions League': 'International',
      'Europa League': 'International',
      'World Cup': 'International',
      'Euro': 'International'
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
    if (leagueLower.includes('league') && leagueLower.includes('j')) return 'Japan';
    if (leagueLower.includes('league') && leagueLower.includes('k')) return 'South Korea';
    
    return 'Other';
  }

  parseResponse(data, sourceName) {
    try {
      // Parser per LiveScore API
      if (sourceName.includes('LiveScore API')) {
        return this.parseLiveScoreAPI(data);
      }
      
      // Parser per TheSportsDB
      if (sourceName.includes('TheSportsDB')) {
        return this.parseTheSportsDB(data);
      }
      
      // Parser per Football-Data
      if (sourceName.includes('Football-Data')) {
        return this.parseFootballData(data);
      }
      
      // Parser per OpenLigaDB
      if (sourceName.includes('API') && !sourceName.includes('LiveScore')) {
        return this.parseOpenLigaDB(data);
      }
      
      // Parser per ESPN
      if (sourceName.includes('ESPN')) {
        return this.parseESPN(data);
      }
      
      // Parser per RSS
      if (sourceName.includes('RSS')) {
        return this.parseRSS(data);
      }
      
      return [];
    } catch (error) {
      console.log(`❌ Errore parsing ${sourceName}: ${error.message}`);
      return [];
    }
  }

  parseLiveScoreAPI(data) {
    const matches = [];
    try {
      // Struttura: data.data.match per live matches
      const matchesData = data?.data?.data?.match || data?.data?.match || [];
      
      if (Array.isArray(matchesData)) {
        for (const match of matchesData) {
          try {
            // Estrai data e ora dalla risposta API
            let matchDate = new Date().toISOString().split('T')[0]; // Default: oggi
            let matchTime = '00:00'; // Default: mezzanotte
            
            // Prova a estrarre la data dall'API
            if (match.date) {
              matchDate = match.date;
            } else if (match.added) {
              // Campo 'added' contiene timestamp completo (es: "2024-01-15 15:30:00")
              matchDate = match.added.split(' ')[0];
              matchTime = match.added.split(' ')[1]?.substring(0, 5) || '00:00';
            } else if (match.location) {
              // Alcuni endpoint usano 'location' per timestamp
              const locationDate = new Date(match.location);
              if (!isNaN(locationDate.getTime())) {
                matchDate = locationDate.toISOString().split('T')[0];
                matchTime = locationDate.toISOString().split('T')[1].substring(0, 5);
              }
            }
            
            // Prova a estrarre l'ora dall'API
            if (match.time && match.time.includes(':')) {
              matchTime = match.time.substring(0, 5);
            } else if (match.fixture_time) {
              matchTime = match.fixture_time.substring(0, 5);
            }
            
            const parsedMatch = {
              home: match.home?.name || match.home_name || 'Team A',
              away: match.away?.name || match.away_name || 'Team B',
              homeScore: match.home?.goals || match.home_goals || '0',
              awayScore: match.away?.goals || match.away_goals || '0',
              status: match.status || match.time || 'LIVE',
              league: match.league?.name || match.competition?.name || 'Unknown League',
              time: matchTime,
              country: match.country?.name || match.league?.country || '',
              date: matchDate
            };
            
            // Debug: stampa i primi 2 match parsati
            if (matches.length < 2) {
              console.log(`🔍 DEBUG Parser - Match ${matches.length + 1}: ${parsedMatch.home} vs ${parsedMatch.away}`);
              console.log(`🔍 DEBUG Parser - Parsed date: "${parsedMatch.date}", time: "${parsedMatch.time}"`);
              console.log(`🔍 DEBUG Parser - Raw match.added: "${match.added}"`);
              console.log(`🔍 DEBUG Parser - Raw match.time: "${match.time}"`);
              console.log(`🔍 DEBUG Parser - Raw match.date: "${match.date}"`);
            }
            
            matches.push(parsedMatch);
          } catch (matchError) {
            console.log(`⚠️ Errore parsing singola partita LiveScore: ${matchError.message}`);
          }
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing LiveScore API: ${error.message}`);
    }
    
    return matches;
  }

  parseTheSportsDB(data) {
    const matches = [];
    try {
      const events = data?.events || [];
      
      for (const event of events) {
        if (event.strSport === 'Soccer') {
          // Estrai data e ora
          let matchDate = event.dateEvent || new Date().toISOString().split('T')[0];
          let matchTime = event.strTime || '00:00';
          
          // Assicurati che l'ora sia nel formato HH:MM
          if (matchTime && !matchTime.includes(':')) {
            matchTime = '00:00';
          } else if (matchTime) {
            matchTime = matchTime.substring(0, 5);
          }
          
          matches.push({
            home: event.strHomeTeam || 'Team A',
            away: event.strAwayTeam || 'Team B',
            homeScore: event.intHomeScore || '0',
            awayScore: event.intAwayScore || '0',
            status: event.strStatus || 'Scheduled',
            league: event.strLeague || 'Unknown League',
            time: matchTime,
            country: event.strCountry || '',
            date: matchDate
          });
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing TheSportsDB: ${error.message}`);
    }
    
    return matches;
  }

  parseFootballData(data) {
    const matches = [];
    try {
      const matchesData = data?.matches || [];
      
      for (const match of matchesData) {
        // Estrai data e ora da utcDate (formato ISO: 2024-01-15T15:30:00Z)
        let matchDate = new Date().toISOString().split('T')[0];
        let matchTime = '00:00';
        
        if (match.utcDate) {
          const dateObj = new Date(match.utcDate);
          matchDate = dateObj.toISOString().split('T')[0];
          matchTime = dateObj.toISOString().split('T')[1].substring(0, 5);
        }
        
        matches.push({
          home: match.homeTeam?.name || 'Team A',
          away: match.awayTeam?.name || 'Team B',
          homeScore: match.score?.fullTime?.homeTeam || '0',
          awayScore: match.score?.fullTime?.awayTeam || '0',
          status: match.status || 'Scheduled',
          league: match.competition?.name || 'Unknown League',
          time: matchTime,
          country: match.area?.name || '',
          date: matchDate
        });
      }
    } catch (error) {
      console.log(`❌ Errore parsing Football-Data: ${error.message}`);
    }
    
    return matches;
  }

  parseOpenLigaDB(data) {
    const matches = [];
    try {
      const matchesData = Array.isArray(data) ? data : [];
      
      for (const match of matchesData) {
        // Solo partite di oggi
        const matchDate = match.matchDateTime ? match.matchDateTime.split('T')[0] : '';
        const today = new Date().toISOString().split('T')[0];
        
        if (matchDate === today) {
          // Estrai ora da matchDateTime (formato ISO)
          let matchTime = '00:00';
          if (match.matchDateTime) {
            const dateObj = new Date(match.matchDateTime);
            matchTime = dateObj.toISOString().split('T')[1].substring(0, 5);
          }
          
          matches.push({
            home: match.team1?.teamName || 'Team A',
            away: match.team2?.teamName || 'Team B',
            homeScore: match.matchResults?.[0]?.pointsTeam1 || '0',
            awayScore: match.matchResults?.[0]?.pointsTeam2 || '0',
            status: match.matchIsFinished ? 'Finished' : 'Live',
            league: match.leagueName || 'Unknown League',
            time: matchTime,
            country: 'Germany',
            date: matchDate
          });
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing OpenLigaDB: ${error.message}`);
    }
    
    return matches;
  }

  parseESPN(data) {
    const matches = [];
    try {
      const events = data?.events || [];
      
      for (const event of events) {
        const competitors = event.competitions?.[0]?.competitors || [];
        if (competitors.length >= 2) {
          // Estrai data e ora da event.date (formato ISO)
          let matchDate = new Date().toISOString().split('T')[0];
          let matchTime = '00:00';
          
          if (event.date) {
            const dateObj = new Date(event.date);
            matchDate = dateObj.toISOString().split('T')[0];
            matchTime = dateObj.toISOString().split('T')[1].substring(0, 5);
          }
          
          matches.push({
            home: competitors[0]?.team?.displayName || 'Team A',
            away: competitors[1]?.team?.displayName || 'Team B',
            homeScore: competitors[0]?.score || '0',
            awayScore: competitors[1]?.score || '0',
            status: event.status?.type?.description || 'Scheduled',
            league: event.league?.name || 'Unknown League',
            time: matchTime,
            country: '',
            date: matchDate
          });
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing ESPN: ${error.message}`);
    }
    
    return matches;
  }

  parseRSS(data) {
    // RSS parsing semplificato - estrae solo informazioni base
    const matches = [];
    try {
      // Per ora ritorna array vuoto, RSS non contiene dati strutturati di partite
      console.log(`📰 RSS feed ricevuto ma non contiene dati strutturati di partite`);
    } catch (error) {
      console.log(`❌ Errore parsing RSS: ${error.message}`);
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

  async getMatches() {
    console.log(`🚀 Avvio ricerca partite di oggi con ${this.sources.length} API ufficiali`);
    
    const allMatches = [];
    const successfulSources = [];
    let sourcesAttempted = 0;
    
    // Ordina le fonti per priorità
    const sortedSources = this.sources.sort((a, b) => (a.priority || 999) - (b.priority || 999));
    
    for (const source of sortedSources) {
      sourcesAttempted++;
      try {
        console.log(`🌐 [${sourcesAttempted}/${this.sources.length}] Tentativo ${source.name}: ${source.url}`);
        
        await this.randomDelay();
        
        const config = {
          headers: { ...this.getHeaders(), ...source.headers },
          timeout: 15000,
          maxRedirects: 3
        };

        // Aggiungi parametri se presenti
        if (source.params) {
          config.params = source.params;
        }

        const response = await axios.get(source.url, config);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ Risposta ricevuta da ${source.name}`);
          
          const matches = this.parseResponse(response.data, source.name);
          const validMatches = matches.filter(match => this.isValidMatch(match));
          
          if (validMatches.length > 0) {
            console.log(`🎯 ${source.name}: ${validMatches.length} partite valide trovate`);
            
            // Aggiungi fonte alle partite
            validMatches.forEach(match => {
              match.source = source.name;
            });
            
            allMatches.push(...validMatches);
            successfulSources.push(source.name);
            
            // Continua sempre la ricerca per ottenere tutte le partite disponibili
            console.log(`🚀 Trovate ${allMatches.length} partite totali finora, continuo la ricerca...`);
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
        }
      }
    }
    
    // Rimuovi duplicati
    const uniqueMatches = [];
    const seen = new Set();
    
    for (const match of allMatches) {
      const key = `${match.home.toLowerCase()}-${match.away.toLowerCase()}`;
      if (!seen.has(key)) {
        seen.add(key);
        uniqueMatches.push(match);
      }
    }
    
    if (uniqueMatches.length > 0) {
      console.log(`🎉 TOTALE: ${uniqueMatches.length} partite uniche trovate da ${successfulSources.length} fonti!`);
      console.log(`📊 Fonti di successo: ${successfulSources.join(', ')}`);
      
      // Aggiungi informazioni sulla nazione basate sulla lega
      const matchesWithCountry = uniqueMatches.map(match => ({
        ...match,
        country: this.getCountryFromLeague(match.league)
      }));
      
      return {
        success: true,
        matches: matchesWithCountry, // RIMOSSO IL LIMITE - TUTTE LE PARTITE
        source: `multi-source: ${successfulSources.join(', ')}`,
        sources_successful: successfulSources.length,
        sources_total: this.sources.length,
        timestamp: new Date().toISOString(),
        date: new Date().toISOString().split('T')[0],
        total_matches: matchesWithCountry.length
      };
    }
    
    // NESSUN FALLBACK - Solo errore onesto
    console.log(`❌ Impossibile recuperare partite da tutte le ${this.sources.length} fonti API`);
    return {
      success: false,
      error: 'Nessuna partita di oggi trovata dalle API',
      message: `Provate tutte le ${this.sources.length} fonti API disponibili. Nessun dato finto generato.`,
      sources_tried: this.sources.map(s => s.name),
      sources_attempted: sourcesAttempted,
      timestamp: new Date().toISOString(),
      date: new Date().toISOString().split('T')[0]
    };
  }
}

module.exports = FootballScraperToday;