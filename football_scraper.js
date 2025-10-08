const axios = require('axios');
const cheerio = require('cheerio');

// Sistema di scraping calcio completamente nuovo - SOLO DATI REALI
class FootballScraper {
  constructor() {
    this.sources = [
      // RSS Feeds (più affidabili per notizie)
      {
        name: 'ESPN RSS',
        url: 'https://www.espn.com/espn/rss/soccer/news',
        type: 'rss'
      },
      {
        name: 'BBC Sport RSS',
        url: 'https://feeds.bbci.co.uk/sport/football/rss.xml',
        type: 'rss'
      },
      {
        name: 'Sky Sports RSS',
        url: 'https://www.skysports.com/rss/12040',
        type: 'rss'
      },
      {
        name: 'Goal.com RSS',
        url: 'https://www.goal.com/feeds/en/news',
        type: 'rss'
      },
      // API pubbliche (con token demo limitato)
      {
        name: 'Football-Data.org',
        url: 'https://api.football-data.org/v4/matches?dateFrom=' + new Date().toISOString().split('T')[0],
        type: 'api',
        headers: { 'X-Auth-Token': 'demo' }
      },
      // JSON endpoints pubblici
      {
        name: 'TheSportsDB Today',
        url: 'https://www.thesportsdb.com/api/v1/json/3/eventsday.php?d=' + new Date().toISOString().split('T')[0],
        type: 'json'
      }
    ];
  }

  // Headers anti-detection avanzati
  getHeaders(referer = null) {
    const userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0'
    ];

    return {
      'User-Agent': userAgents[Math.floor(Math.random() * userAgents.length)],
      'Accept': 'application/json, text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9,it;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'DNT': '1',
      ...(referer && { 'Referer': referer })
    };
  }

  // Delay casuale
  async randomDelay() {
    await new Promise(resolve => setTimeout(resolve, Math.random() * 2000 + 1000));
  }

  // Parser per API JSON
  parseApiResponse(data, sourceName) {
    const matches = [];
    
    try {
      if (sourceName === 'Football-Data.org' && data.matches) {
        for (const match of data.matches.slice(0, 10)) {
          if (match.homeTeam && match.awayTeam && match.score) {
            matches.push({
              id: matches.length + 1,
              home: match.homeTeam.name || match.homeTeam.shortName,
              away: match.awayTeam.name || match.awayTeam.shortName,
              goalsHome: match.score.fullTime?.home || 0,
              goalsAway: match.score.fullTime?.away || 0,
              start: match.utcDate,
              elapsed: match.status === 'IN_PLAY' ? match.minute : null,
              league: match.competition?.name || 'Unknown'
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
              start: event.dateEvent,
              elapsed: event.strStatus === 'Match Finished' ? null : event.strProgress,
              league: event.strLeague || 'Unknown'
            });
          }
        }
      }
    } catch (error) {
      console.log(`❌ Errore parsing API ${sourceName}: ${error.message}`);
    }

    return matches;
  }

  // Parser per RSS feeds
  parseRssResponse(xmlData, sourceName) {
    const matches = [];
    
    try {
      const $ = cheerio.load(xmlData, { xmlMode: true });
      
      $('item').each((i, item) => {
        if (matches.length >= 10) return false;
        
        const title = $(item).find('title').text();
        const description = $(item).find('description').text();
        const fullText = `${title} ${description}`;
        
        // Pattern migliorati per estrarre risultati dalle notizie RSS
        const patterns = [
          // "Barcelona beat Real Madrid 3-1" o "Manchester City defeated Liverpool 2-0"
          /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(?:beat|defeated|won against|thrashed)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(\d+)[-–:](\d+)\b/gi,
          // "Juventus 2-1 Inter" o "Arsenal 3:0 Chelsea"
          /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(\d+)[-–:](\d+)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\b/gi,
          // "Liverpool vs Manchester United ended 1-1"
          /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+vs?\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(?:ended|finished|final score)\s+(\d+)[-–:](\d+)\b/gi,
          // "The match between PSG and Bayern ended 2-1"
          /\bmatch between\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+and\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(?:ended|finished)\s+(\d+)[-–:](\d+)\b/gi,
          // "Final score: Milan 1-0 Napoli"
          /\bfinal score:?\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s+(\d+)[-–:](\d+)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\b/gi
        ];
        
        for (const pattern of patterns) {
          let match;
          while ((match = pattern.exec(fullText)) !== null) {
            let home, away, homeScore, awayScore;
            
            // Pattern specifico per ogni tipo di match
            if (pattern.source.includes('beat|defeated|won against|thrashed')) {
              // "Barcelona beat Real Madrid 3-1"
              home = this.cleanTeamName(match[1]);
              away = this.cleanTeamName(match[2]);
              homeScore = parseInt(match[3]);
              awayScore = parseInt(match[4]);
            } else if (pattern.source.includes('vs?')) {
              // "Liverpool vs Manchester United ended 1-1"
              home = this.cleanTeamName(match[1]);
              away = this.cleanTeamName(match[2]);
              homeScore = parseInt(match[3]);
              awayScore = parseInt(match[4]);
            } else if (pattern.source.includes('match between')) {
              // "The match between PSG and Bayern ended 2-1"
              home = this.cleanTeamName(match[1]);
              away = this.cleanTeamName(match[2]);
              homeScore = parseInt(match[3]);
              awayScore = parseInt(match[4]);
            } else if (pattern.source.includes('final score')) {
              // "Final score: Milan 1-0 Napoli"
              home = this.cleanTeamName(match[1]);
              away = this.cleanTeamName(match[4]);
              homeScore = parseInt(match[2]);
              awayScore = parseInt(match[3]);
            } else {
              // Pattern generico "Juventus 2-1 Inter"
              home = this.cleanTeamName(match[1]);
              away = this.cleanTeamName(match[4]);
              homeScore = parseInt(match[2]);
              awayScore = parseInt(match[3]);
            }
            
            if (this.isValidMatch(home, away, homeScore, awayScore)) {
              matches.push({
                id: matches.length + 1,
                home,
                away,
                goalsHome: homeScore,
                goalsAway: awayScore,
                start: new Date().toISOString(),
                elapsed: null,
                league: 'Various'
              });
              break;
            }
          }
          if (matches.length > 0) break;
        }
      });
    } catch (error) {
      console.log(`❌ Errore parsing RSS ${sourceName}: ${error.message}`);
    }

    return matches;
  }

  // Pulisce i nomi delle squadre
  cleanTeamName(name) {
    if (!name) return '';
    return name
      .replace(/^\d+\s*/, '')
      .replace(/\s*\d+$/, '')
      .replace(/[^\w\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .split(' ')
      .filter(word => word.length > 1)
      .slice(0, 3)
      .join(' ');
  }

  // Valida una partita
  isValidMatch(home, away, homeScore, awayScore) {
    const cleanHome = this.cleanTeamName(home);
    const cleanAway = this.cleanTeamName(away);
    
    return cleanHome && 
           cleanAway && 
           cleanHome.length >= 3 && 
           cleanAway.length >= 3 && 
           cleanHome !== cleanAway &&
           !isNaN(homeScore) && 
           !isNaN(awayScore) &&
           homeScore >= 0 && 
           awayScore >= 0;
  }

  // Metodo principale per recuperare partite
  async getMatches() {
    console.log('🔄 Inizio ricerca partite reali...');
    
    for (const source of this.sources) {
      try {
        console.log(`🌐 Tentativo ${source.name}: ${source.url}`);
        
        await this.randomDelay();
        
        const config = {
          headers: { ...this.getHeaders(), ...source.headers },
          timeout: 25000,
          maxRedirects: 10
        };

        const response = await axios.get(source.url, config);
        
        if (response.status === 200 && response.data) {
          console.log(`✅ Risposta ricevuta da ${source.name} (${response.data.length || 'N/A'} bytes)`);
          
          let matches = [];
          
          if (source.type === 'api' || source.type === 'json') {
            matches = this.parseApiResponse(response.data, source.name);
          } else if (source.type === 'rss') {
            matches = this.parseRssResponse(response.data, source.name);
          }
          
          if (matches.length > 0) {
            console.log(`🎯 SUCCESSO! Trovate ${matches.length} partite reali da ${source.name}`);
            console.log(`📋 Partite: ${matches.map(m => `${m.home} ${m.goalsHome}-${m.goalsAway} ${m.away}`).join(', ')}`);
            
            return {
              success: true,
              matches: matches.slice(0, 10),
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
    console.log('❌ Impossibile recuperare dati reali da tutte le fonti');
    return {
      success: false,
      error: 'Impossibile recuperare dati reali dalle fonti disponibili',
      message: 'Tutti i servizi di calcio sono temporaneamente non disponibili. Nessun dato finto generato.',
      sources_tried: this.sources.map(s => s.name),
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = FootballScraper;