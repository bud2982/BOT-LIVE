const axios = require('axios');

// Sistema di scraping calcio REALE - Versione 2.0
class FootballScraperV2 {
  constructor() {
    // Fonti API pubbliche più affidabili
    this.sources = [
      {
        name: 'API-Football (RapidAPI)',
        url: 'https://api-football-v1.p.rapidapi.com/v3/fixtures',
        type: 'api',
        headers: {
          'X-RapidAPI-Key': 'demo', // Token demo limitato
          'X-RapidAPI-Host': 'api-football-v1.p.rapidapi.com'
        },
        params: {
          date: new Date().toISOString().split('T')[0]
        }
      },
      {
        name: 'Football-Data.org',
        url: 'https://api.football-data.org/v4/matches',
        type: 'api',
        headers: { 'X-Auth-Token': 'demo' },
        params: {
          dateFrom: new Date().toISOString().split('T')[0],
          dateTo: new Date().toISOString().split('T')[0]
        }
      },
      {
        name: 'TheSportsDB',
        url: 'https://www.thesportsdb.com/api/v1/json/3/eventsday.php',
        type: 'json',
        params: {
          d: new Date().toISOString().split('T')[0],
          s: 'Soccer'
        }
      },
      {
        name: 'OpenLigaDB (Bundesliga)',
        url: 'https://api.openligadb.de/getmatchdata/bl1',
        type: 'json'
      }
    ];
  }

  // Headers anti-detection
  getHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'DNT': '1'
    };
  }

  // Delay casuale
  async randomDelay() {
    await new Promise(resolve => setTimeout(resolve, Math.random() * 2000 + 1000));
  }

  // Parser per diverse API
  parseApiResponse(data, sourceName) {
    const matches = [];
    
    try {
      if (sourceName === 'Football-Data.org' && data.matches) {
        for (const match of data.matches.slice(0, 10)) {
          if (match.homeTeam && match.awayTeam) {
            matches.push({
              id: matches.length + 1,
              home: match.homeTeam.name || match.homeTeam.shortName,
              away: match.awayTeam.name || match.awayTeam.shortName,
              goalsHome: match.score?.fullTime?.home ?? 0,
              goalsAway: match.score?.fullTime?.away ?? 0,
              start: match.utcDate,
              elapsed: match.status === 'IN_PLAY' ? match.minute : null,
              league: match.competition?.name || 'Unknown',
              status: match.status
            });
          }
        }
      } else if (sourceName === 'API-Football (RapidAPI)' && data.response) {
        for (const fixture of data.response.slice(0, 10)) {
          if (fixture.teams?.home && fixture.teams?.away) {
            matches.push({
              id: matches.length + 1,
              home: fixture.teams.home.name,
              away: fixture.teams.away.name,
              goalsHome: fixture.goals?.home ?? 0,
              goalsAway: fixture.goals?.away ?? 0,
              start: fixture.fixture.date,
              elapsed: fixture.fixture.status.elapsed,
              league: fixture.league?.name || 'Unknown',
              status: fixture.fixture.status.long
            });
          }
        }
      } else if (sourceName === 'TheSportsDB' && data.events) {
        for (const event of data.events.slice(0, 10)) {
          if (event.strSport === 'Soccer' && event.strHomeTeam && event.strAwayTeam) {
            matches.push({
              id: matches.length + 1,
              home: event.strHomeTeam,
              away: event.strAwayTeam,
              goalsHome: parseInt(event.intHomeScore) || 0,
              goalsAway: parseInt(event.intAwayScore) || 0,
              start: event.dateEvent + 'T' + (event.strTime || '00:00:00'),
              elapsed: event.strStatus === 'Match Finished' ? null : event.strProgress,
              league: event.strLeague || 'Unknown',
              status: event.strStatus
            });
          }
        }
      } else if (sourceName === 'OpenLigaDB (Bundesliga)' && Array.isArray(data)) {
        for (const match of data.slice(0, 10)) {
          if (match.team1 && match.team2) {
            matches.push({
              id: matches.length + 1,
              home: match.team1.teamName,
              away: match.team2.teamName,
              goalsHome: match.matchResults?.[0]?.pointsTeam1 ?? 0,
              goalsAway: match.matchResults?.[0]?.pointsTeam2 ?? 0,
              start: match.matchDateTime,
              elapsed: match.matchIsFinished ? null : 'Live',
              league: 'Bundesliga',
              status: match.matchIsFinished ? 'Finished' : 'Live'
            });
          }
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing ${sourceName}: ${error.message}`);
    }

    return matches;
  }

  // Valida una partita
  isValidMatch(match) {
    return match.home && 
           match.away && 
           match.home.length >= 3 && 
           match.away.length >= 3 && 
           match.home !== match.away &&
           !isNaN(match.goalsHome) && 
           !isNaN(match.goalsAway) &&
           match.goalsHome >= 0 && 
           match.goalsAway >= 0;
  }

  // Metodo principale
  async getMatches() {
    console.log('🔄 Inizio ricerca partite reali (API v2.0)...');
    
    for (const source of this.sources) {
      try {
        console.log(`🌐 Tentativo ${source.name}: ${source.url}`);
        
        await this.randomDelay();
        
        const config = {
          headers: { ...this.getHeaders(), ...source.headers },
          timeout: 30000,
          maxRedirects: 5
        };

        // Aggiungi parametri se presenti
        if (source.params) {
          config.params = source.params;
        }

        const response = await axios.get(source.url, config);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ Risposta ricevuta da ${source.name}`);
          console.log(`📊 Dati: ${JSON.stringify(response.data).substring(0, 200)}...`);
          
          const matches = this.parseApiResponse(response.data, source.name);
          const validMatches = matches.filter(match => this.isValidMatch(match));
          
          if (validMatches.length > 0) {
            console.log(`🎯 SUCCESSO! Trovate ${validMatches.length} partite reali da ${source.name}`);
            console.log(`📋 Partite: ${validMatches.map(m => `${m.home} ${m.goalsHome}-${m.goalsAway} ${m.away}`).join(', ')}`);
            
            return {
              success: true,
              matches: validMatches.slice(0, 10),
              source: `real-${source.name.toLowerCase().replace(/\s+/g, '-')}`,
              timestamp: new Date().toISOString()
            };
          } else {
            console.log(`⚠️ Nessuna partita valida trovata da ${source.name}`);
          }
        } else {
          console.log(`❌ Risposta non valida da ${source.name}: Status ${response.status}`);
        }
      } catch (error) {
        console.log(`❌ Errore ${source.name}: ${error.message}`);
        if (error.response) {
          console.log(`📊 Status: ${error.response.status}`);
        }
      }
    }
    
    // NESSUN FALLBACK - Solo errore onesto
    console.log('❌ Impossibile recuperare dati reali da tutte le fonti API');
    return {
      success: false,
      error: 'Impossibile recuperare dati reali dalle API disponibili',
      message: 'Tutte le API di calcio sono temporaneamente non disponibili o richiedono autenticazione. Nessun dato finto generato.',
      sources_tried: this.sources.map(s => s.name),
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = FootballScraperV2;