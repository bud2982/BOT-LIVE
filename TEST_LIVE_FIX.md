# 🧪 TEST RAPIDO - FIX SEZIONE LIVE

## ⚡ **GUIDA VELOCE PER TESTARE IL FIX**

---

## 📱 **STEP 1: INSTALLA L'APK AGGIORNATO** (2 minuti)

### **Opzione A: Via ADB (Raccomandato)**
```powershell
adb install -r "c:\Users\Dario\Documents\GitHub\BOT LIVE\BOT-LIVE\build\app\outputs\flutter-apk\app-release.apk"
```

### **Opzione B: Manualmente**
1. Copia `app-release.apk` sul telefono
2. Apri il file e installa
3. Autorizza l'installazione da origini sconosciute se richiesto

---

## 🔍 **STEP 2: RACCOGLI I LOG** (1 minuto)

### **Metodo Automatico (Raccomandato)**
```powershell
.\collect_live_logs.ps1
```

Questo script:
- ✅ Verifica che il dispositivo sia collegato
- ✅ Pulisce i log precedenti
- ✅ Mostra i log in tempo reale con colori
- ✅ Filtra solo i log rilevanti

### **Metodo Manuale**
```powershell
adb logcat | Select-String "LiveScore|LiveScreen|HybridFootball"
```

---

## 🎯 **STEP 3: TESTA LA SEZIONE LIVE** (2 minuti)

1. ✅ Apri l'app sul telefono
2. ✅ Vai alla sezione "Risultati Live" (icona TV rossa)
3. ✅ Osserva i log sul PC mentre l'app carica

---

## 📊 **STEP 4: ANALIZZA I LOG**

### **✅ LOG POSITIVI (Tutto OK)**

```
HybridFootballService: Recupero partite live SOLO da LiveScore API...
LiveScoreApiService: Tentativo 1 - matches/live.json
LiveScoreApiService: matches/live.json - Status: 200
LiveScoreApiService: 🔍 Analisi struttura risposta API...
LiveScoreApiService: success = true
LiveScoreApiService: ✅ Trovato array "match" (endpoint live) - 15 elementi
LiveScoreApiService: 🔍 Esempio prima partita (dati grezzi):
  Chiavi: [id, home, away, status, time, scores, competition, country]
  status: IN PLAY
  time: 67'
LiveScoreApiService: matches/live.json - Parse completato: 15 partite totali
  📊 Partita 0: Manchester United vs Liverpool - elapsed: 67
  📊 Partita 1: Real Madrid vs Barcelona - elapsed: 45
LiveScoreApiService: matches/live.json - Trovate 15 partite live dopo filtro
🔍 LiveScreen: Ricevute 15 partite dal servizio
  📊 Partita 0: Manchester United vs Liverpool - elapsed: 67
✅ LiveScreen: 15 partite live dopo filtro
```

**RISULTATO:** ✅ **FUNZIONA!** Le partite dovrebbero essere visibili nell'app.

---

### **❌ LOG PROBLEMATICI**

#### **Problema 1: Nessuna partita dall'API**
```
🔍 LiveScreen: Ricevute 0 partite dal servizio
```

**CAUSA:** Non ci sono partite live al momento OPPURE problema API
**SOLUZIONE:** 
- Testa in orari con partite in corso (pomeriggio/sera)
- Verifica lo status code dell'API (deve essere 200)

---

#### **Problema 2: Partite ricevute ma elapsed null**
```
🔍 LiveScreen: Ricevute 15 partite dal servizio
  📊 Partita 0: Manchester United vs Liverpool - elapsed: null
  ❌ Filtrata: Manchester United vs Liverpool (elapsed: null)
✅ LiveScreen: 0 partite live dopo filtro
```

**CAUSA:** Il campo `elapsed` non viene parsato correttamente
**SOLUZIONE:** 
1. Guarda i dati grezzi della prima partita nei log
2. Identifica quale campo contiene i minuti (`time`, `minute`, `elapsed`)
3. Condividi i log per una correzione mirata

---

#### **Problema 3: Errore API**
```
LiveScoreApiService: matches/live.json - Status: 401
```

**CAUSA:** Chiave API non valida o scaduta
**SOLUZIONE:** 
- Verifica la chiave API su Render
- Rigenera una nuova chiave se necessario

---

#### **Problema 4: Formato risposta non riconosciuto**
```
LiveScoreApiService: ❌ Formato risposta non riconosciuto
LiveScoreApiService: Chiavi disponibili: [success, result]
```

**CAUSA:** La struttura della risposta API è diversa
**SOLUZIONE:** 
- Condividi i log completi
- Modificheremo il parsing per gestire il nuovo formato

---

## 🎯 **CHECKLIST RISULTATI**

Dopo il test, verifica:

### **Log:**
- [ ] Vedo "Ricevute X partite dal servizio" con X > 0
- [ ] Vedo i dati delle prime 3 partite
- [ ] Il campo `elapsed` non è null
- [ ] Vedo "X partite live dopo filtro" con X > 0

### **App:**
- [ ] La sezione Live mostra partite
- [ ] Le partite hanno minuti trascorsi (es. 67')
- [ ] Le partite hanno punteggi aggiornati (es. 2-1)
- [ ] Le partite hanno barra colorata laterale

---

## 📝 **COSA CONDIVIDERE SE NON FUNZIONA**

Se il problema persiste, condividi:

1. **Log completi** della sezione "Analisi struttura risposta API"
2. **Log della prima partita** (dati grezzi)
3. **Screenshot** della sezione Live nell'app
4. **Orario del test** (per verificare se c'erano partite in corso)

---

## 🔧 **COMANDI UTILI**

### **Verifica dispositivo collegato:**
```powershell
adb devices
```

### **Installa APK:**
```powershell
adb install -r "c:\Users\Dario\Documents\GitHub\BOT LIVE\BOT-LIVE\build\app\outputs\flutter-apk\app-release.apk"
```

### **Raccogli log:**
```powershell
.\collect_live_logs.ps1
```

### **Salva log su file:**
```powershell
adb logcat | Select-String "LiveScore|LiveScreen" > live_logs.txt
```

### **Pulisci log:**
```powershell
adb logcat -c
```

---

## ⏱️ **TEMPO TOTALE: ~5 MINUTI**

- Step 1 (Installa): 2 min
- Step 2 (Log): 1 min
- Step 3 (Test): 2 min

---

**🚀 Buon Test!**

Se tutto funziona, vedrai le partite live nell'app! 🎉
Se non funziona, i log ci diranno esattamente dove si blocca. 🔍