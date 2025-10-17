# 🧪 GUIDA RAPIDA TEST NOTIFICHE

## ⚡ **TEST IN 10 MINUTI**

---

## 📦 **STEP 1: INSTALLA L'APK (2 minuti)**

### **Opzione A: Con ADB**
```powershell
adb install -r "c:\Users\Dario\Documents\GitHub\BOT LIVE\BOT-LIVE\build\app\outputs\flutter-apk\app-release.apk"
```

### **Opzione B: Manuale**
1. Copia `app-release.apk` sul telefono
2. Apri il file e installa
3. Accetta permessi

---

## ⚙️ **STEP 2: CONFIGURA TELEGRAM (2 minuti)**

1. ✅ Apri l'app
2. ✅ Vai a **Impostazioni** (icona ingranaggio in alto a destra nella Home)
3. ✅ Inserisci il tuo **Chat ID Telegram**
4. ✅ Clicca **"Salva"**
5. ✅ Testa con **"Invia notifica di test"**

### **Come ottenere il Chat ID:**
1. Apri Telegram
2. Cerca il bot `@userinfobot`
3. Invia `/start`
4. Copia il numero che ti dà (es. `123456789`)

---

## 🧪 **STEP 3: TEST NOTIFICHE LOCALI (3 minuti)**

### **Cosa testare:**
Notifiche locali sul telefono quando una partita è 0-0 dopo 8 minuti.

### **Come testare:**

1. ✅ Vai alla **Home**
2. ✅ Seleziona 1-2 partite che stanno per iniziare (checkbox)
3. ✅ Clicca il **pulsante verde** in basso a destra (icona play ▶️)
4. ✅ Vedi **"Monitoraggio attivo"** con pallino verde
5. ✅ Attendi che una partita sia **0-0 dopo 8 minuti**
6. ✅ Dovresti ricevere una **notifica locale** sul telefono

### **Esempio notifica:**
```
📱 Notifica locale:
Titolo: Juventus - Inter
Corpo: Ancora 0-0 al minuto 12? Over 2.5
```

### **Se non funziona:**
- ❌ Verifica che il monitoraggio sia attivo (pallino verde)
- ❌ Verifica permessi notifiche: Impostazioni Android → App → BOT LIVE → Notifiche
- ❌ Controlla log: `adb logcat | Select-String "CONDIZIONE SODDISFATTA"`

---

## 📱 **STEP 4: TEST NOTIFICHE TELEGRAM (5 minuti)**

### **Cosa testare:**
Notifiche Telegram automatiche quando:
1. Partita 0-0 dopo 8 minuti
2. Partita 1-0 o 0-1 a fine primo tempo (40-50 minuti)

### **Come testare:**

#### **Test A: Notifica 0-0 dopo 8 minuti**

1. ✅ Vai alla **Home** o **"Partite per Paese"**
2. ✅ Segui 1-2 partite che stanno per iniziare (clicca bookmark 🔖)
3. ✅ Vai alla sezione **"Partite Seguite"** (pulsante viola in basso)
4. ✅ Attendi che una partita sia **0-0 dopo 8 minuti**
5. ✅ Dovresti ricevere una **notifica su Telegram**

**Esempio notifica Telegram:**
```
⚽ ALERT SCOMMESSE - 0-0 dopo 8'

Juventus 0 - 0 Inter
🏆 Serie A
🌍 Italy
⏱️ 12' - Ancora 0-0!

💡 Suggerimento: Over 2.5 goals
```

---

#### **Test B: Notifica 1-0/0-1 fine primo tempo**

1. ✅ Segui partite che stanno per arrivare al **45° minuto**
2. ✅ Vai alla sezione **"Partite Seguite"**
3. ✅ Se una partita è **1-0 o 0-1** tra il **40° e 50° minuto**
4. ✅ Dovresti ricevere una **notifica su Telegram**

**Esempio notifica Telegram:**
```
⚽ ALERT SCOMMESSE - Fine Primo Tempo

Juventus 1 - 0 Inter
🏆 Serie A
🌍 Italy
⏱️ 45' - Juventus in vantaggio 1-0

💡 Situazione interessante per il secondo tempo!
```

---

### **Se non funziona:**
- ❌ Verifica Chat ID configurato: Impostazioni → Telegram
- ❌ Verifica backend attivo: `https://bot-live-proxy.onrender.com`
- ❌ Controlla log: `adb logcat | Select-String "Notifica Telegram"`
- ❌ Verifica che il bot non sia bloccato su Telegram

---

## 🔍 **STEP 5: CONTROLLA I LOG (Opzionale)**

### **Comando per vedere tutti i log:**
```powershell
adb logcat | Select-String "flutter"
```

### **Comando per vedere solo notifiche:**
```powershell
adb logcat | Select-String "CONDIZIONE|Notifica|Telegram"
```

### **Log positivi (tutto OK):**
```
✅ CONDIZIONE 1 SODDISFATTA: 0-0 dopo 8 minuti
📤 Notifica Telegram inviata: 0-0 dopo 8 minuti
Notifica inviata con successo per ID: 12345
```

### **Log negativi (problemi):**
```
❌ Errore nell'invio notifica: 500
📱 Telegram non configurato, skip notifiche
⚠️ Errore durante l'invio notifiche Telegram: ...
```

---

## 📊 **CHECKLIST COMPLETA**

### **Configurazione:**
- [ ] APK installato
- [ ] Chat ID Telegram configurato
- [ ] Test notifica Telegram funziona
- [ ] Permessi notifiche locali abilitati

### **Test Notifiche Locali:**
- [ ] Monitoraggio attivato (pulsante play)
- [ ] Vedo "Monitoraggio attivo" con pallino verde
- [ ] Ricevo notifica quando partita 0-0 dopo 8'

### **Test Notifiche Telegram:**
- [ ] Partite seguite dalla Home/Paese
- [ ] Vedo partite nella sezione "Partite Seguite"
- [ ] Ricevo notifica Telegram quando 0-0 dopo 8'
- [ ] Ricevo notifica Telegram quando 1-0/0-1 fine primo tempo

---

## 🎯 **RISULTATI ATTESI**

### **✅ SE TUTTO FUNZIONA:**

**Notifiche Locali:**
- 📱 Ricevi notifica sul telefono quando partita 0-0 dopo 8'
- 📱 Notifica appare nella barra notifiche Android
- 📱 Puoi cliccare sulla notifica per aprire l'app

**Notifiche Telegram:**
- 📱 Ricevi messaggio su Telegram quando 0-0 dopo 8'
- 📱 Ricevi messaggio su Telegram quando 1-0/0-1 fine primo tempo
- 📱 Ogni notifica arriva solo UNA volta per partita
- 📱 Messaggi formattati con emoji e informazioni complete

---

## 🐛 **PROBLEMI COMUNI**

### **1. "Non ricevo notifiche locali"**

**Causa:** Permessi notifiche negati

**Soluzione:**
1. Vai in Impostazioni Android
2. App → BOT LIVE
3. Notifiche → Abilita tutto

---

### **2. "Non ricevo notifiche Telegram"**

**Causa:** Chat ID non configurato o errato

**Soluzione:**
1. Verifica Chat ID: Impostazioni → Telegram
2. Testa con "Invia notifica di test"
3. Se non funziona, ottieni nuovo Chat ID da `@userinfobot`

---

### **3. "Notifica arriva più volte"**

**Causa:** Bug nel sistema di tracciamento

**Soluzione:**
1. Riavvia l'app
2. Se persiste, segnala il problema con i log

---

### **4. "Backend Telegram non risponde"**

**Causa:** Server Render in sleep mode

**Soluzione:**
1. Apri `https://bot-live-proxy.onrender.com` nel browser
2. Attendi 30 secondi che si attivi
3. Riprova

---

## 📞 **SUPPORTO**

Se hai problemi, condividi:

1. **Screenshot** della sezione "Partite Seguite"
2. **Log completi** (comando: `adb logcat > log.txt`)
3. **Orario del test** (per verificare se c'erano partite)
4. **Chat ID Telegram** (per verificare configurazione)

---

## 🎉 **SUCCESSO!**

Se tutti i test passano:
- ✅ **Notifiche locali funzionano**
- ✅ **Notifiche Telegram funzionano**
- ✅ **Partite seguite si aggiornano**
- ✅ **App completa e funzionante**

---

**Buon test! 🚀**

**Tempo totale: ~10 minuti**