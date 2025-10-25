# 🎯 Configurazione: Solo LiveScore API

**Data**: 2024
**Stato**: ✅ ATTIVO
**Ultimo aggiornamento**: Configurazione esclusiva LiveScore

---

## 📋 Riepilogo Modifiche

L'app è stata configurata per utilizzare **SOLO livescore-api.com** come fonte dati.

Tutti gli altri servizi sono stati **disabilitati ma non rimossi** dal codebase per permettere ripristini futuri:
- ❌ `ApiFootballService` - Disabilitato
- ❌ `SofaScoreScraper` - Disabilitato
- ❌ `TestProxyService` - Disabilitato (fallback rimosso)
- ❌ Dati di esempio - Nessun fallback

---

## 🔑 Credenziali API Configurate

```
Base URL: https://livescore-api.com/api-client
API Key: wUOF0E1DmdetayWk
API Secret: Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl
```

**Ubicazione**: `lib/services/livescore_api_service.dart`

---

## 📊 Architettura Dati

```
┌─────────────────────────────────────────┐
│    App (All Screens & Services)        │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   HybridFootballService                │
│   ✅ SOLO LiveScore (nessun fallback)   │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   LiveScoreApiService                  │
│   ✅ API ufficiale di LiveScore         │
│   ❌ Nessun fallback a dati di esempio  │
└─────────────────────────────────────────┘
```

---

## 🔄 Flusso Dati

### 1. **Partite di Oggi**
```
LiveScoreApiService.getFixturesToday()
├─ Endpoint: /fixtures/list.json
├─ Paginazione: max 5 pagine (150 partite)
├─ Errori: ❌ ECCEZIONE (nessun fallback)
└─ Deduplicazione: Basata su ID
```

### 2. **Partite Live**
```
LiveScoreApiService.getLiveMatches()
├─ Endpoint: /matches/live.json
├─ Fallback: Filtra getFixturesToday() se live endpoint vuoto
├─ Filtro: elapsed >= 0 (appena iniziate o in corso)
└─ Errori: ❌ ECCEZIONE
```

### 3. **Partite per ID Specifici**
```
HybridFootballService.getLiveByIds(ids)
├─ Cerca in getLiveMatches()
├─ Se non trovate tutte: Cerca in getFixturesToday()
└─ Errori: ❌ ECCEZIONE se nulla disponibile
```

---

## ⚠️ Gestione Errori

### Cosa Succede Se LiveScore Non Risponde?

```dart
// ❌ L'app lancia un'eccezione chiara
Exception('❌ ERRORE: Non è possibile recuperare le partite da LiveScore. 
Verifica la configurazione API.')
```

### Errori Specifici Gestiti

| Condizione | Codice HTTP | Azione |
|-----------|------------|--------|
| Chiave API non valida | 401 | ❌ Exception |
| Limite richieste superato | 429 | ❌ Exception |
| Errore API generico | != 200 | ❌ Exception |
| Timeout | - | ❌ Exception (30s) |
| JSON malformato | - | ❌ Exception |

---

## 📝 Log di Debug

Quando esegui l'app, vedrai log come:

```
🎯 HybridFootballService: Utilizzo SOLO LiveScore API
🎯 LiveScoreApiService: Recupero partite di oggi da LiveScore API
LiveScoreApiService: Recupero pagina 1...
LiveScoreApiService: Usando chiave API: wUOF0E1Dm...
LiveScoreApiService: Pagina 1 - Status: 200
LiveScoreApiService: Pagina 1 - Trovate 47 partite
...
✅ HybridFootballService: Recuperate 47 partite da LiveScore
```

---

## 🧪 Test Connessione

```dart
final service = HybridFootballService();
final isConnected = await service.testConnection();

if (isConnected) {
  print('✅ Connessione a LiveScore API: OK');
} else {
  print('❌ Connessione a LiveScore API: FALLITA');
}
```

---

## 🔧 Manutenzione

### Se Vuoi Ripristinare Altre Fonti

1. Vedi il **git history** per i commit precedenti
2. I servizi disabilitati sono ancora nel codebase (commentati e documentati)
3. Riattivare è facile - contatta per i dettagli

### Se Cambi Credenziali API

Modifica in `lib/services/livescore_api_service.dart`:

```dart
static const String _apiKey = 'LA_TUA_NUOVA_CHIAVE';
static const String _apiSecret = 'IL_TUO_NUOVO_SECRET';
```

### Se Vuoi Aumentare Timeout

In `livescore_api_service.dart`, cerca:

```dart
.timeout(const Duration(seconds: 30))
```

E modifica il valore.

---

## 📊 Performance Attesa

| Operazione | Tempo Atteso | Fonte |
|-----------|------------|--------|
| `getFixturesToday()` | 3-10 secondi | LiveScore (5 pagine max) |
| `getLiveMatches()` | 2-5 secondi | LiveScore (endpoint live) |
| `testConnection()` | 2-3 secondi | LiveScore |

**Nota**: I tempi dipendono dalla velocità della connessione internet e della risposta dell'API LiveScore.

---

## 🚀 Prossimi Passi

Se hai problemi:

1. **Verifica le credenziali API** in `livescore_api_service.dart`
2. **Testa la connessione** manualmente con curl:
   ```bash
   curl "https://livescore-api.com/api-client/fixtures/list.json?key=wUOF0E1DmdetayWk&secret=Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl"
   ```
3. **Controlla lo stato del servizio LiveScore** su https://livescore-api.com
4. **Verifica il limite API** nel dashboard LiveScore

---

**Status**: ✅ App configurata per utilizzo esclusivo di LiveScore API