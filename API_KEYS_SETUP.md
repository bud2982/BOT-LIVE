# 🔑 Guida per Ottenere API Keys Gratuite

## 📋 **API Gratuite Disponibili**

### 1. **API-Football** (Consigliata)
- **Sito**: https://api-football.com
- **Piano gratuito**: 100 richieste/giorno
- **Registrazione**: Gratuita
- **Copertura**: 1000+ campionati mondiali
- **Sostituire in**: `football_scraper_today.js` linea 388
- **Formato**: `'X-RapidAPI-Key': 'TUA_CHIAVE_QUI'`

### 2. **APIfootball.com**
- **Sito**: https://apifootball.com
- **Piano gratuito**: 10 richieste/giorno
- **Registrazione**: Gratuita
- **Copertura**: Campionati principali
- **Sostituire in**: `football_scraper_today.js` linea 404
- **Formato**: `APIkey: 'TUA_CHIAVE_QUI'`

### 3. **Sportmonks**
- **Sito**: https://www.sportmonks.com/football-api
- **Piano gratuito**: Danish Superliga + Scottish Premiership
- **Registrazione**: Gratuita
- **Sostituire in**: `football_scraper_today.js` linea 412
- **Formato**: `api_token: 'TUA_CHIAVE_QUI'`

### 4. **Live-Score API**
- **Sito**: https://live-score-api.com
- **Piano gratuito**: 100 richieste/giorno
- **Registrazione**: Gratuita
- **Sostituire in**: `football_scraper_today.js` linea 421
- **Formato**: `'X-API-Key': 'TUA_CHIAVE_QUI'`

### 5. **Football-Data.org**
- **Sito**: https://www.football-data.org/client/register
- **Piano gratuito**: 10 richieste/minuto
- **Registrazione**: Gratuita
- **Sostituire in**: `football_scraper_today.js` linea 452
- **Formato**: `'X-Auth-Token': 'TUA_CHIAVE_QUI'`

## 🚀 **Procedura di Registrazione**

### Passo 1: Registrazione
1. Vai sul sito dell'API
2. Clicca "Sign Up" o "Register"
3. Inserisci email e password
4. Conferma l'email

### Passo 2: Ottenere la Chiave
1. Accedi al dashboard
2. Vai su "API Keys" o "Credentials"
3. Copia la tua chiave API

### Passo 3: Configurazione
1. Apri `football_scraper_today.js`
2. Cerca `YOUR_API_KEY` o `YOUR_FREE_TOKEN`
3. Sostituisci con la tua chiave reale
4. Salva il file

## 📊 **Risultati Attesi**

Con le API keys configurate:
- **Senza API keys**: 6-10 partite (solo OpenLigaDB + RSS)
- **Con 1-2 API keys**: 15-30 partite
- **Con tutte le API keys**: 50+ partite da tutto il mondo

## ⚠️ **Note Importanti**

1. **Limiti di Rate**: Rispetta i limiti delle API gratuite
2. **Rotazione**: Il sistema prova tutte le fonti automaticamente
3. **Fallback**: Se un'API fallisce, usa le altre
4. **RSS sempre attivi**: I feed RSS funzionano sempre senza chiavi

## 🔧 **Test delle API**

Dopo aver configurato le chiavi, testa il sistema:

```bash
# Avvia il server
node proxy_server_new.js

# Testa in un altro terminale
curl http://localhost:3001/api/matches/today
```

## 📈 **Monitoraggio**

Il sistema mostra nel log:
- ✅ Fonti che funzionano
- ❌ Fonti che falliscono
- 📊 Numero totale di partite trovate
- 🔄 Fonti utilizzate con successo

## 🆘 **Risoluzione Problemi**

### API Key non funziona:
1. Verifica che sia copiata correttamente
2. Controlla se hai superato il limite giornaliero
3. Verifica che l'account sia attivo

### Poche partite:
- Normale! Non tutti i campionati giocano ogni giorno
- I weekend hanno più partite dei giorni feriali
- Alcune API potrebbero essere temporaneamente offline

### Errori di connessione:
- Verifica la connessione internet
- Alcuni siti potrebbero bloccare richieste automatiche
- I feed RSS sono più affidabili dei siti web