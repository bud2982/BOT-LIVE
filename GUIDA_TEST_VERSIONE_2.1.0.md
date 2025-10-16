# 📱 GUIDA TEST - Versione 2.1.0

## 🎯 COSA È STATO CORRETTO

Questa versione risolve **4 problemi critici** rilevati dopo l'implementazione della paginazione:

### ✅ Problema 1: Partite Internazionali Mancanti
**Prima**: Solo 30 partite visualizzate  
**Dopo**: 90-150 partite con paginazione automatica (fino a 5 pagine)

### ✅ Problema 2: Sezione LIVE Vuota
**Prima**: Nessuna partita mostrata nella sezione LIVE anche durante partite in corso  
**Dopo**: Partite live rilevate correttamente tramite parsing dello status

### ✅ Problema 3: Partite Seguite Non Compaiono
**Prima**: Dopo aver selezionato partite, non comparivano nella sezione dedicata  
**Dopo**: Partite seguite visibili immediatamente con aggiornamento automatico

### ✅ Problema 4: Punteggi Non Si Aggiornano
**Prima**: Punteggi rimanevano 0-0, nessuna notifica inviata  
**Dopo**: Aggiornamento automatico ogni 30 secondi con notifiche Telegram

---

## 🧪 PROCEDURA DI TEST

### FASE 1: Installazione
```bash
# L'APK si trova in:
c:\Users\Dario\Documents\GitHub\BOT LIVE\BOT-LIVE\build\app\outputs\flutter-apk\app-release.apk

# Trasferisci sul dispositivo e installa
```

### FASE 2: Test Problema 1 - Partite Internazionali

**Obiettivo**: Verificare che vengano mostrate 90+ partite

**Passi**:
1. Apri l'app
2. Vai alla schermata principale
3. Scorri l'elenco delle partite
4. **VERIFICA**: Dovresti vedere molte più partite rispetto a prima (90-150 invece di 30)
5. **VERIFICA**: Cerca partite di Champions League, Europa League, o altre competizioni internazionali
6. **VERIFICA**: Controlla che ci siano partite di diversi paesi (42+ paesi)

**Risultato Atteso**:
- ✅ Almeno 90 partite visualizzate
- ✅ Presenza di competizioni internazionali
- ✅ Partite da molti paesi diversi

**Se Fallisce**:
- Controlla i log dell'app: `adb logcat | findstr "LiveScore"`
- Verifica la connessione internet
- Controlla che l'API key sia valida

---

### FASE 3: Test Problema 2 - Sezione LIVE

**Obiettivo**: Verificare che le partite in corso compaiano nella sezione LIVE

**Prerequisito**: Esegui il test quando ci sono partite in corso (controlla su livescore.com)

**Passi**:
1. Apri l'app durante orari di partite (es. sera europea)
2. Vai alla schermata principale
3. Guarda la sezione "LIVE" in alto
4. **VERIFICA**: Dovresti vedere le partite attualmente in corso
5. **VERIFICA**: Ogni partita live dovrebbe mostrare:
   - Minuto di gioco (es. "45'", "HT", "67'")
   - Punteggio aggiornato
   - Status (es. "IN PLAY", "HALF TIME")

**Risultato Atteso**:
- ✅ Partite in corso visibili nella sezione LIVE
- ✅ Minuto di gioco mostrato correttamente
- ✅ Punteggio aggiornato in tempo reale

**Se Fallisce**:
- Verifica che ci siano effettivamente partite in corso su livescore.com
- Controlla i log: `adb logcat | findstr "LIVE"`
- Se non ci sono partite in corso, la sezione sarà vuota (comportamento normale)

---

### FASE 4: Test Problema 3 - Partite Seguite

**Obiettivo**: Verificare che le partite selezionate compaiano nella sezione dedicata

**Passi**:
1. Apri l'app
2. Vai alla schermata principale
3. Seleziona 2-3 partite cliccando sull'icona "stella" o "segui"
4. Vai alla sezione "Partite Seguite" (icona in basso)
5. **VERIFICA**: Le partite selezionate dovrebbero essere visibili
6. **VERIFICA**: Ogni partita dovrebbe mostrare:
   - Nome squadre
   - Orario/Minuto
   - Punteggio
   - Competizione

**Risultato Atteso**:
- ✅ Partite selezionate visibili immediatamente
- ✅ Informazioni complete per ogni partita
- ✅ Possibilità di rimuovere partite dalla lista

**Se Fallisce**:
- Controlla i log: `adb logcat | findstr "FollowedMatches"`
- Verifica che il salvataggio in SharedPreferences funzioni
- Prova a riavviare l'app (le partite dovrebbero persistere)

---

### FASE 5: Test Problema 4 - Aggiornamento Punteggi

**Obiettivo**: Verificare che i punteggi si aggiornino automaticamente

**Prerequisito**: Avere partite seguite che sono in corso

**Passi**:
1. Segui 2-3 partite che stanno per iniziare o sono in corso
2. Vai alla sezione "Partite Seguite"
3. Lascia l'app aperta per almeno 2 minuti
4. **VERIFICA**: I punteggi dovrebbero aggiornarsi automaticamente ogni 30 secondi
5. **VERIFICA**: Se c'è un gol, dovresti ricevere una notifica Telegram
6. **VERIFICA**: Il minuto di gioco dovrebbe avanzare

**Test Specifici**:

**A) Test Aggiornamento Automatico**:
- Apri "Partite Seguite"
- Nota il punteggio di una partita live (es. 0-0 al 15')
- Aspetta 30 secondi
- **VERIFICA**: Il minuto dovrebbe essere cambiato (es. 16' o 17')
- Se c'è un gol su livescore.com, dovrebbe apparire nell'app

**B) Test Notifica Telegram**:
- Assicurati di aver configurato il bot Telegram
- Segui una partita che sta per iniziare
- Aspetta che la partita inizi
- **VERIFICA**: Dovresti ricevere notifica all'8° minuto se è ancora 0-0
- **VERIFICA**: Dovresti ricevere notifica a fine primo tempo
- **VERIFICA**: Dovresti ricevere notifica per ogni gol

**Risultato Atteso**:
- ✅ Punteggi aggiornati ogni 30 secondi
- ✅ Minuto di gioco avanza automaticamente
- ✅ Notifiche Telegram inviate correttamente
- ✅ Notifica all'8° minuto se 0-0
- ✅ Notifica a fine primo tempo
- ✅ Notifica per ogni gol

**Se Fallisce**:
- Controlla i log: `adb logcat | findstr "Update"`
- Verifica che il timer di 30 secondi sia attivo
- Controlla la configurazione del bot Telegram
- Verifica che il proxy server sia in esecuzione (se usato)

---

## 🔍 COMANDI UTILI PER DEBUG

### Visualizza Log in Tempo Reale
```bash
# Log generali
adb logcat | findstr "Flutter"

# Log specifici per LiveScore API
adb logcat | findstr "LiveScore"

# Log per partite live
adb logcat | findstr "LIVE"

# Log per aggiornamenti
adb logcat | findstr "Update"

# Log per notifiche Telegram
adb logcat | findstr "Telegram"
```

### Verifica Installazione
```bash
# Controlla se l'app è installata
adb shell pm list packages | findstr "botlive"

# Avvia l'app manualmente
adb shell am start -n com.example.botlive/.MainActivity
```

### Cancella Dati App (Reset Completo)
```bash
# Cancella cache e dati
adb shell pm clear com.example.botlive
```

---

## 📊 CHECKLIST COMPLETA

### Prima del Test
- [ ] APK compilato con successo
- [ ] APK trasferito su dispositivo
- [ ] App installata correttamente
- [ ] Connessione internet attiva
- [ ] API key LiveScore valida
- [ ] Bot Telegram configurato (se si testano notifiche)
- [ ] Proxy server avviato (se usato)

### Test Problema 1 - Partite Internazionali
- [ ] Visualizzate 90+ partite
- [ ] Presenti partite internazionali
- [ ] Partite da 40+ paesi diversi
- [ ] Nessun errore nei log

### Test Problema 2 - Sezione LIVE
- [ ] Partite live visibili (se ci sono partite in corso)
- [ ] Minuto di gioco mostrato correttamente
- [ ] Status corretto (IN PLAY, HT, ecc.)
- [ ] Punteggio aggiornato

### Test Problema 3 - Partite Seguite
- [ ] Partite selezionate compaiono immediatamente
- [ ] Informazioni complete visualizzate
- [ ] Possibile rimuovere partite
- [ ] Partite persistono dopo riavvio app

### Test Problema 4 - Aggiornamento Punteggi
- [ ] Punteggi si aggiornano ogni 30 secondi
- [ ] Minuto di gioco avanza automaticamente
- [ ] Notifica Telegram all'8° minuto (0-0)
- [ ] Notifica Telegram a fine primo tempo
- [ ] Notifica Telegram per ogni gol
- [ ] Notifica Telegram per fine partita

---

## 🐛 PROBLEMI COMUNI E SOLUZIONI

### Problema: "Nessuna partita visualizzata"
**Soluzione**:
1. Verifica connessione internet
2. Controlla validità API key
3. Guarda i log: `adb logcat | findstr "ERROR"`
4. Prova a fare pull-to-refresh

### Problema: "Sezione LIVE sempre vuota"
**Soluzione**:
1. Verifica che ci siano partite in corso su livescore.com
2. Se non ci sono partite in corso, è normale che sia vuota
3. Prova durante orari di partite (sera europea, pomeriggio sudamericano)
4. Controlla i log: `adb logcat | findstr "LIVE"`

### Problema: "Partite seguite non compaiono"
**Soluzione**:
1. Verifica di aver cliccato correttamente sull'icona "segui"
2. Controlla i log: `adb logcat | findstr "FollowedMatches"`
3. Prova a cancellare dati app: `adb shell pm clear com.example.botlive`
4. Reinstalla l'app

### Problema: "Punteggi non si aggiornano"
**Soluzione**:
1. Verifica che l'app sia in primo piano
2. Controlla che ci sia connessione internet
3. Aspetta almeno 30 secondi
4. Controlla i log: `adb logcat | findstr "Update"`
5. Verifica che le partite siano effettivamente in corso

### Problema: "Notifiche Telegram non arrivano"
**Soluzione**:
1. Verifica configurazione bot Telegram
2. Controlla che il proxy server sia in esecuzione
3. Verifica il token del bot
4. Controlla i log: `adb logcat | findstr "Telegram"`
5. Testa manualmente l'endpoint: `POST http://localhost:3001/api/telegram/notify`

---

## 📞 SUPPORTO

Se riscontri problemi durante il test:

1. **Raccogli i log**:
   ```bash
   adb logcat > log_test.txt
   ```

2. **Verifica versione app**:
   - Apri l'app
   - Vai in "Impostazioni" o "Info"
   - Verifica che sia versione 2.1.0

3. **Informazioni da fornire**:
   - Versione Android del dispositivo
   - Modello dispositivo
   - Orario del test
   - Descrizione dettagliata del problema
   - Log dell'app (file log_test.txt)
   - Screenshot se possibile

---

## ✅ CRITERI DI SUCCESSO

Il test è considerato **SUPERATO** se:

1. ✅ Vengono visualizzate almeno 90 partite (invece di 30)
2. ✅ La sezione LIVE mostra partite in corso quando disponibili
3. ✅ Le partite selezionate compaiono in "Partite Seguite"
4. ✅ I punteggi si aggiornano automaticamente ogni 30 secondi
5. ✅ Le notifiche Telegram vengono inviate correttamente

Se **tutti e 5** i criteri sono soddisfatti, la versione 2.1.0 è pronta per il rilascio! 🎉

---

**Versione Guida**: 1.0  
**Data**: 15 Ottobre 2025  
**Versione App**: 2.1.0