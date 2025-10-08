# Configurazione API LiveScore Ufficiali

## Panoramica
L'app è stata aggiornata per utilizzare le API ufficiali di LiveScore invece degli scraper web. Attualmente utilizza dati realistici di esempio come fallback.

## Configurazione API Ufficiali

### 1. Ottenere le Credenziali API
1. Registrati su [LiveScore Developer Portal](https://developer.livescore.com)
2. Crea un nuovo progetto/applicazione
3. Ottieni la tua API Key

### 2. Configurare l'API Key
Modifica il file `lib/services/official_livescore_service.dart`:

```dart
static const String _apiKey = 'LA_TUA_API_KEY_QUI';
```

### 3. Endpoint API Disponibili
L'app utilizza questi endpoint:

- **Partite di oggi**: `GET /v1/fixtures/today`
- **Partite live**: `GET /v1/fixtures/live`  
- **Status API**: `GET /v1/status`

### 4. Formato Dati Atteso
Le API dovrebbero restituire dati in questo formato:

```json
{
  "data": [
    {
      "id": 12345,
      "home_team": {
        "name": "Juventus"
      },
      "away_team": {
        "name": "Inter"
      },
      "home_score": 1,
      "away_score": 2,
      "start_time": "2025-10-06T20:00:00Z",
      "elapsed_time": 45,
      "competition": {
        "name": "Serie A",
        "country": "Italy"
      }
    }
  ]
}
```

## Dati di Esempio Attuali

Attualmente l'app utilizza dati realistici di esempio che includono:

### Campionati Supportati:
- **Serie A** (Italia): Juventus, Inter, AC Milan, Napoli, Roma, Lazio
- **Premier League** (Inghilterra): Manchester United, Liverpool, Arsenal, Chelsea, Manchester City, Tottenham
- **La Liga** (Spagna): Real Madrid, Barcelona, Atletico Madrid, Valencia
- **Bundesliga** (Germania): Bayern Munich, Borussia Dortmund, RB Leipzig, Bayer Leverkusen
- **Ligue 1** (Francia): Paris Saint-Germain, Olympique Marseille
- **Champions League** (Internazionale): Partite tra i top club europei

### Caratteristiche dei Dati di Esempio:
- ✅ Nomi di squadre reali e corretti
- ✅ Campionati organizzati per paese
- ✅ Partite live simulate con minuti trascorsi
- ✅ Orari realistici (alcune in corso, altre future)
- ✅ Risultati plausibili

## Vantaggi della Nuova Implementazione

### 🚫 Problemi Risolti:
- ❌ Nomi squadre malformati ("AC Milan drew", "with Juventus on")
- ❌ Dati inconsistenti dagli scraper web
- ❌ Errori di parsing da siti web esterni
- ❌ Dipendenza da proxy server instabili

### ✅ Miglioramenti:
- ✅ Dati puliti e consistenti
- ✅ Partite correttamente catalogate per paese
- ✅ Nomi squadre corretti
- ✅ Sistema di fallback robusto
- ✅ Facile integrazione con API ufficiali future

## Test e Verifica

Esegui il test per verificare il funzionamento:

```bash
dart test_new_services.dart
```

Il test dovrebbe mostrare:
- Partite trovate per ogni servizio
- Catalogazione corretta per paese
- Partite live identificate correttamente
- Connessione API (fallback attivo)

## Prossimi Passi

1. **Ottenere API Key ufficiali** da LiveScore
2. **Testare integrazione** con API reali
3. **Configurare rate limiting** se necessario
4. **Implementare caching** per ottimizzare le performance
5. **Aggiungere più campionati** se supportati dalle API

## Note Tecniche

- Il servizio `OfficialLiveScoreService` gestisce automaticamente il fallback
- I dati di esempio sono progettati per essere realistici e utili per i test
- La struttura è pronta per l'integrazione con API reali
- Tutti i servizi esistenti continuano a funzionare senza modifiche