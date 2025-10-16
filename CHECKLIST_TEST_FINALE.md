# ✅ CHECKLIST TEST FINALE - VERSIONE 2.1.0

**Data:** 16 Ottobre 2025  
**Versione:** 2.1.0  
**Tester:** _________________  
**Dispositivo:** _________________  
**Android Version:** _________________

---

## 📋 PRE-TEST SETUP

### Preparazione Ambiente

- [ ] APK compilato presente in `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Dispositivo Android connesso via USB
- [ ] Debug USB abilitato sul dispositivo
- [ ] Comando `adb devices` mostra il dispositivo
- [ ] Proxy server Node.js avviato (se necessario per notifiche)
- [ ] Connessione internet attiva sul dispositivo

### Comandi Preparatori

```bash
# Verifica connessione dispositivo
adb devices

# Installa APK
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Avvia monitoraggio log (in finestra separata)
adb logcat | findstr "LiveScore"
```

---

## 🧪 TEST 1: PARTITE INTERNAZIONALI (Problema 1)

**Obiettivo:** Verificare che vengano recuperate 90-150 partite invece di 30

**Tempo stimato:** 5 minuti

### Procedura

1. [ ] Aprire l'app
2. [ ] Navigare alla schermata principale (Home)
3. [ ] Attendere caricamento partite
4. [ ] Scorrere l'elenco delle partite

### Criteri di Successo

- [ ] **Numero partite:** Almeno 90 partite visibili (target: 90-150)
- [ ] **Varietà geografica:** Partite da almeno 30+ paesi diversi
- [ ] **Varietà leghe:** Partite da almeno 25+ leghe diverse
- [ ] **Nessun duplicato:** Ogni partita appare una sola volta
- [ ] **Tempo caricamento:** Completato entro 10 secondi

### Risultati

| Metrica | Valore Misurato | Target | ✅/❌ |
|---------|-----------------|--------|-------|
| Numero partite | _________ | 90-150 | [ ] |
| Paesi rappresentati | _________ | 30+ | [ ] |
| Leghe rappresentate | _________ | 25+ | [ ] |
| Duplicati trovati | _________ | 0 | [ ] |
| Tempo caricamento | _________ sec | <10s | [ ] |

### Note
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Esito Test 1:** [ ] PASS  [ ] FAIL

---

## 🔴 TEST 2: SEZIONE LIVE (Problema 2)

**Obiettivo:** Verificare che le partite live vengano rilevate e mostrate correttamente

**Tempo stimato:** 10 minuti

**⚠️ NOTA:** Questo test richiede che ci siano partite in corso. Eseguire durante orari di gioco (14:00-23:00 CET).

### Procedura

1. [ ] Aprire l'app
2. [ ] Navigare alla sezione "LIVE"
3. [ ] Verificare presenza partite in corso
4. [ ] Controllare dettagli di ogni partita live

### Criteri di Successo

- [ ] **Partite live visibili:** Almeno 1 partita se ci sono match in corso
- [ ] **Punteggio mostrato:** Punteggio corrente visibile (es. 2-1)
- [ ] **Minuto mostrato:** Minuto di gioco visibile (es. 45', 67')
- [ ] **Status corretto:** Status "IN PLAY", "HALF TIME", etc.
- [ ] **Aggiornamento automatico:** Punteggi si aggiornano automaticamente
- [ ] **Nessuna partita finita:** Partite con status "FINISHED" non appaiono

### Risultati

| Metrica | Valore Misurato | Note | ✅/❌ |
|---------|-----------------|------|-------|
| Partite live trovate | _________ | | [ ] |
| Punteggi corretti | _________ / _________ | | [ ] |
| Minuti corretti | _________ / _________ | | [ ] |
| Status corretti | _________ / _________ | | [ ] |
| Partite finite escluse | Sì / No | | [ ] |

### Test Dettagliato Partita Live

**Partita 1:**
- Home Team: _________________  Away Team: _________________
- Punteggio: _____ - _____
- Minuto: _____'
- Status: _________________
- [ ] Tutti i dati corretti

**Partita 2:**
- Home Team: _________________  Away Team: _________________
- Punteggio: _____ - _____
- Minuto: _____'
- Status: _________________
- [ ] Tutti i dati corretti

### Note
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Esito Test 2:** [ ] PASS  [ ] FAIL  [ ] N/A (nessuna partita live)

---

## ⭐ TEST 3: PARTITE SEGUITE (Problema 3)

**Obiettivo:** Verificare che le partite selezionate appaiano nella sezione "Followed Matches"

**Tempo stimato:** 5 minuti

### Procedura

1. [ ] Aprire l'app
2. [ ] Selezionare 3-5 partite dalla schermata principale
3. [ ] Navigare alla sezione "Followed Matches"
4. [ ] Verificare che tutte le partite selezionate siano visibili
5. [ ] Chiudere completamente l'app (kill process)
6. [ ] Riaprire l'app
7. [ ] Verificare che le partite seguite siano ancora presenti

### Criteri di Successo

- [ ] **Partite visibili immediatamente:** Dopo selezione, appaiono subito
- [ ] **Tutte le partite presenti:** Tutte le partite selezionate sono visibili
- [ ] **Persistenza:** Partite ancora presenti dopo riavvio app
- [ ] **Dettagli corretti:** Nomi squadre, punteggi, orari corretti
- [ ] **Rimozione funzionante:** Possibile rimuovere partite dalla lista

### Risultati

| Azione | Risultato | ✅/❌ |
|--------|-----------|-------|
| Selezionate 5 partite | _____ partite apparse | [ ] |
| Tutte visibili in "Followed" | Sì / No | [ ] |
| Dettagli corretti | _____ / 5 | [ ] |
| Persistenza dopo riavvio | Sì / No | [ ] |
| Rimozione funzionante | Sì / No | [ ] |

### Test Persistenza Dettagliato

**Prima del riavvio:**
- Partite seguite: _____
- Timestamp: _________________

**Dopo riavvio:**
- Partite seguite: _____
- Timestamp: _________________
- [ ] Stesso numero di partite
- [ ] Stesse partite presenti

### Note
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Esito Test 3:** [ ] PASS  [ ] FAIL

---

## 🔄 TEST 4: AGGIORNAMENTO PUNTEGGI (Problema 4)

**Obiettivo:** Verificare che i punteggi si aggiornino automaticamente ogni 30 secondi

**Tempo stimato:** 15 minuti

**⚠️ NOTA:** Questo test richiede partite live in corso.

### Procedura

1. [ ] Selezionare 2-3 partite live
2. [ ] Navigare a "Followed Matches"
3. [ ] Annotare punteggi e minuti attuali
4. [ ] Attendere 30 secondi senza toccare lo schermo
5. [ ] Verificare se punteggi/minuti sono cambiati
6. [ ] Ripetere per 3 cicli (90 secondi totali)

### Criteri di Successo

- [ ] **Aggiornamento automatico:** Punteggi si aggiornano senza refresh manuale
- [ ] **Intervallo corretto:** Aggiornamenti ogni ~30 secondi
- [ ] **Minuti aggiornati:** Minuto di gioco si incrementa
- [ ] **Punteggi corretti:** Punteggi corrispondono alla realtà
- [ ] **Notifiche Telegram:** Notifiche ricevute per goal (se configurato)

### Risultati - Monitoraggio Temporale

**Partita monitorata:** _________________ vs _________________

| Tempo | Minuto | Punteggio | Cambiamento | ✅/❌ |
|-------|--------|-----------|-------------|-------|
| T0 (inizio) | _____ | ___-___ | - | [ ] |
| T1 (+30s) | _____ | ___-___ | Sì / No | [ ] |
| T2 (+60s) | _____ | ___-___ | Sì / No | [ ] |
| T3 (+90s) | _____ | ___-___ | Sì / No | [ ] |

### Test Notifiche Telegram (se configurato)

- [ ] Bot Telegram configurato
- [ ] Chat ID impostato
- [ ] Proxy server in esecuzione

**Eventi notificati:**
- [ ] Goal squadra casa
- [ ] Goal squadra ospite
- [ ] Fine primo tempo
- [ ] Fine partita
- [ ] Alert minuto 8 (se 0-0)

**Notifiche ricevute:** _____ / _____ eventi

### Note
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Esito Test 4:** [ ] PASS  [ ] FAIL  [ ] N/A (nessuna partita live)

---

## 🔍 TEST AGGIUNTIVI

### Test Performance

- [ ] **Avvio app:** Tempo < 5 secondi
- [ ] **Caricamento partite:** Tempo < 10 secondi
- [ ] **Scroll fluido:** Nessun lag durante scroll
- [ ] **Memoria:** App non crasha per out of memory
- [ ] **Batteria:** Consumo batteria accettabile

### Test UI/UX

- [ ] **Layout corretto:** Tutti gli elementi visibili
- [ ] **Testo leggibile:** Font size appropriato
- [ ] **Colori corretti:** Tema applicato correttamente
- [ ] **Icone visibili:** Tutte le icone caricate
- [ ] **Navigazione fluida:** Transizioni smooth tra schermate

### Test Errori

- [ ] **Nessuna connessione:** Messaggio errore appropriato
- [ ] **API non disponibile:** Gestione errore corretta
- [ ] **Dati corrotti:** App non crasha
- [ ] **Timeout:** Gestione timeout corretta

---

## 📊 RIEPILOGO FINALE

### Risultati per Problema

| Problema | Descrizione | Esito | Note |
|----------|-------------|-------|------|
| 1 | Partite internazionali | [ ] PASS [ ] FAIL | _________ |
| 2 | Sezione LIVE | [ ] PASS [ ] FAIL | _________ |
| 3 | Partite seguite | [ ] PASS [ ] FAIL | _________ |
| 4 | Aggiornamento punteggi | [ ] PASS [ ] FAIL | _________ |

### Metriche Complessive

| Metrica | Target | Misurato | ✅/❌ |
|---------|--------|----------|-------|
| Partite totali | 90-150 | _________ | [ ] |
| Partite live | 1+ (se disponibili) | _________ | [ ] |
| Paesi | 30+ | _________ | [ ] |
| Leghe | 25+ | _________ | [ ] |
| Aggiornamenti/min | 2 (ogni 30s) | _________ | [ ] |

### Problemi Riscontrati

```
1. _________________________________________________________________
   Gravità: [ ] Critico  [ ] Alto  [ ] Medio  [ ] Basso
   
2. _________________________________________________________________
   Gravità: [ ] Critico  [ ] Alto  [ ] Medio  [ ] Basso
   
3. _________________________________________________________________
   Gravità: [ ] Critico  [ ] Alto  [ ] Medio  [ ] Basso
```

### Raccomandazioni

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## ✅ DECISIONE FINALE

**Data test:** _________________  
**Ora completamento:** _________________  
**Durata totale test:** _________ minuti

### Esito Complessivo

- [ ] **APPROVATO PER RILASCIO** - Tutti i test superati
- [ ] **APPROVATO CON RISERVA** - Test superati con problemi minori
- [ ] **NON APPROVATO** - Problemi critici riscontrati

### Firma Tester

Nome: _________________  
Firma: _________________  
Data: _________________

---

## 📝 ALLEGATI

### Screenshot Richiesti

- [ ] Screenshot schermata principale con 90+ partite
- [ ] Screenshot sezione LIVE con partite in corso
- [ ] Screenshot "Followed Matches" con partite selezionate
- [ ] Screenshot notifica Telegram (se configurato)
- [ ] Screenshot log ADB con aggiornamenti

### File Log

- [ ] Log completo ADB salvato in `logs/adb_log_[data].txt`
- [ ] Screenshot salvati in `screenshots/test_[data]/`

---

**Fine Checklist**

*Per supporto o domande, consultare:*
- *GUIDA_TEST_VERSIONE_2.1.0.md*
- *REPORT_TEST_COMPLETO.md*
- *CORREZIONI_APPLICATE.md*