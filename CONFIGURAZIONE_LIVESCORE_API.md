# 🔑 CONFIGURAZIONE LIVESCORE API

## ⚠️ IMPORTANTE: CHIAVE API RICHIESTA

L'app ora utilizza **ESCLUSIVAMENTE** le API di LiveScore. Per funzionare correttamente, devi configurare la tua chiave API.

## 📋 PASSO 1: Ottieni la Chiave API LiveScore

1. Vai su: **https://live-score-api.com**
2. Clicca su **"Sign Up"** o **"Register"**
3. Crea un account gratuito
4. Conferma la tua email
5. Accedi al dashboard
6. Copia la tua **API Key**

## 🔧 PASSO 2: Configura la Chiave API

1. Apri il file: `lib/services/livescore_api_service.dart`
2. Trova la riga:
   ```dart
   static const String _apiKey = 'YOUR_LIVESCORE_API_KEY_HERE';
   ```
3. Sostituisci `YOUR_LIVESCORE_API_KEY_HERE` con la tua chiave reale:
   ```dart
   static const String _apiKey = 'la_tua_chiave_api_qui';
   ```
4. Salva il file

## 🚀 PASSO 3: Testa la Configurazione

Dopo aver configurato la chiave API, riavvia l'app:

```bash
flutter run -d chrome
```

## ✅ VERIFICA FUNZIONAMENTO

Se tutto è configurato correttamente, vedrai:

- ✅ **Connessione riuscita - Recupero dati da LiveScore**
- ✅ Partite reali con squadre vere
- ✅ Punteggi aggiornati in tempo reale
- ✅ Informazioni complete su campionati e paesi

## ❌ ERRORI COMUNI

### "Chiave API LiveScore mancante"
- **Causa**: Non hai configurato la chiave API
- **Soluzione**: Segui il PASSO 2 sopra

### "Chiave API LiveScore non valida o scaduta"
- **Causa**: Chiave API errata o account scaduto
- **Soluzione**: Verifica la chiave API sul sito LiveScore

### "Limite richieste API LiveScore superato"
- **Causa**: Hai superato il limite giornaliero
- **Soluzione**: Aspetta il reset giornaliero o aggiorna il piano

## 📊 PIANO GRATUITO LIVESCORE

- **Richieste giornaliere**: 100
- **Copertura**: Campionati mondiali
- **Dati live**: Sì
- **Costo**: Gratuito per 14 giorni

## 🔄 DOPO LA CONFIGURAZIONE

Una volta configurata la chiave API, l'app:

1. **NON utilizzerà più dati di esempio**
2. **Mostrerà solo partite reali da LiveScore**
3. **Aggiornerà i punteggi in tempo reale**
4. **Fornirà informazioni complete sui campionati**

## 🆘 SUPPORTO

Se hai problemi:

1. Verifica che la chiave API sia copiata correttamente
2. Controlla che non ci siano spazi extra
3. Assicurati che l'account LiveScore sia attivo
4. Verifica la connessione internet

---

**🎯 OBIETTIVO**: Utilizzare SOLO API LiveScore ufficiali e verificate per dati reali e aggiornati.