# 🔍 ANALISI DEI 3 PROBLEMI RIPORTATI

## 📅 Data: 17/01/2025

---

## ❌ **PROBLEMA 1: Partite selezionate dalla Home non appaiono tra le "Partite Seguite"**

### **Comportamento Atteso:**
1. Utente va alla Home
2. Seleziona 2-3 partite (checkbox)
3. Clicca "Segui partite" (pulsante viola)
4. Vede messaggio "✅ X partite seguite"
5. Va alla sezione "Partite Seguite"
6. **DOVREBBE** vedere le partite selezionate

### **Comportamento Reale:**
- Le partite NON appaiono nella sezione "Partite Seguite"

### **Analisi del Codice:**

#### **File: `home_screen.dart` (linee 139-194)**
```dart
Future<void> _addSelectedToFollowed() async {
  if (_selected.isEmpty) {
    _showError('Seleziona almeno una partita da seguire');
    return;
  }

  final followedService = FollowedMatchesService();
  final hybridService = HybridFootballService();
  int addedCount = 0;

  try {
    // Ottieni tutte le partite per trovare quelle selezionate
    final allMatches = await hybridService.getFixturesToday();
    
    for (final fixtureId in _selected) {
      final match = allMatches.firstWhere((m) => m.id == fixtureId);
      final isAlreadyFollowed = await followedService.isMatchFollowed(fixtureId);
      
      if (!isAlreadyFollowed) {
        await followedService.followMatch(match);
        addedCount++;
      }
    }

    if (mounted) {
      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $addedCount ${addedCount == 1 ? "partita seguita" : "partite seguite"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      _showError('Errore nell\'aggiungere le partite: $e');
    }
  }
}
```

#### **File: `followed_matches_service.dart` (linee 9-46)**
```dart
Future<bool> followMatch(Fixture match) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final followedMatches = await getFollowedMatches();
    
    // Controlla se la partita è già seguita
    final isAlreadyFollowed = followedMatches.any((m) => m.id == match.id);
    if (isAlreadyFollowed) {
      print('⚠️ Partita già seguita: ${match.home} vs ${match.away}');
      return false;
    }
    
    // Aggiungi la partita
    followedMatches.add(match);
    
    // Salva la lista aggiornata
    final matchesJson = followedMatches.map((m) => {
      'id': m.id,
      'home': m.home,
      'away': m.away,
      'goalsHome': m.goalsHome,
      'goalsAway': m.goalsAway,
      'start': m.start.toIso8601String(),
      'elapsed': m.elapsed,
      'league': m.league,
      'country': m.country,
    }).toList();
    
    await prefs.setString(_followedMatchesKey, json.encode(matchesJson));
    
    print('✅ Partita aggiunta alle seguite: ${match.home} vs ${match.away}');
    return true;
    
  } catch (e) {
    print('💥 Errore nel seguire la partita: $e');
    return false;
  }
}
```

### **Possibili Cause:**

1. **Eccezione durante `firstWhere`**: Se l'ID non viene trovato, `firstWhere` lancia un'eccezione
2. **Errore di serializzazione JSON**: Possibile problema nel salvare su SharedPreferences
3. **Problema di sincronizzazione**: La pagina "Partite Seguite" non si aggiorna dopo l'aggiunta

### **Soluzione Proposta:**

✅ **Aggiungere log dettagliati** per tracciare ogni passaggio
✅ **Gestire l'eccezione `firstWhere`** con `orElse`
✅ **Verificare che SharedPreferences salvi correttamente**
✅ **Aggiungere un refresh automatico** della pagina "Partite Seguite"

---

## ❌ **PROBLEMA 2: Nessuna notifica locale sui risultati**

### **Comportamento Atteso:**
1. Utente seleziona partite dalla Home
2. Clicca il pulsante verde (play) per avviare il monitoraggio
3. **DOVREBBE** ricevere notifiche locali quando:
   - C'è un gol
   - Cambia il punteggio
   - La partita inizia/finisce

### **Comportamento Reale:**
- NON arriva alcuna notifica locale

### **Analisi del Codice:**

#### **File: `monitor_controller.dart` (linee 154-186)**
```dart
Future<void> _processFixtures(List<Fixture> fixtures) async {
  for (final f in fixtures) {
    final elapsed = f.elapsed ?? 0;
    final isZeroZero = f.goalsHome == 0 && f.goalsAway == 0;
    
    print('PARTITA LIVE: ${f.home} - ${f.away}, Minuto: $elapsed, Risultato: ${f.goalsHome}-${f.goalsAway}');
    
    // ⚠️ PROBLEMA: Notifica SOLO se 0-0 dopo 8 minuti!
    if (isZeroZero && elapsed >= 8) {
      if (!notified.contains(f.id)) {
        print('CONDIZIONE SODDISFATTA! Invio notifica per: ${f.home} - ${f.away}');
        try {
          await notif.showAlert(
            id: f.id,
            title: '${f.home} - ${f.away}',
            body: 'Ancora 0-0 al minuto ${f.elapsed}? Over 2.5',
          );
          notified.add(f.id);
          print('Notifica inviata con successo per ID: ${f.id}');
        } catch (notifError) {
          print('ERRORE durante l\'invio della notifica: $notifError');
        }
      }
    }
  }
}
```

### **PROBLEMA TROVATO:**

🔴 **La logica di notifica è TROPPO SPECIFICA!**

Il codice invia notifiche **SOLO** se:
- La partita è 0-0
- Sono passati almeno 8 minuti
- Questa è una logica per scommesse "Over 2.5", non per notifiche generiche!

**Mancano notifiche per:**
- ⚽ Goal segnati
- 🏁 Inizio partita
- 🏁 Fine partita
- 📊 Cambio punteggio

### **Soluzione Proposta:**

✅ **Riscrivere `_processFixtures`** per inviare notifiche su:
- Ogni goal (confrontando punteggio precedente)
- Inizio partita (elapsed passa da null a > 0)
- Fine partita (elapsed >= 90)
- Cambio punteggio

✅ **Salvare lo stato precedente** delle partite per confrontare i cambiamenti

---

## ❌ **PROBLEMA 3: Nessuna notifica Telegram**

### **Comportamento Atteso:**
1. Utente configura Chat ID Telegram nelle impostazioni
2. Segue alcune partite
3. **DOVREBBE** ricevere notifiche Telegram quando:
   - C'è un gol
   - Cambia il punteggio
   - La partita inizia/finisce

### **Comportamento Reale:**
- NON arriva alcuna notifica Telegram

### **Analisi del Codice:**

#### **File: `telegram_service.dart`**
Il servizio ha metodi per:
- `subscribeToMatch()` - Registra una sottoscrizione
- `sendNotification()` - Invia una notifica
- `createGoalMessage()` - Crea messaggio per goal
- `createMatchStartMessage()` - Crea messaggio per inizio
- `createMatchEndMessage()` - Crea messaggio per fine

#### **File: `followed_matches_page.dart` (linee 174-221)**
```dart
Future<void> _sendTestNotification(Fixture match) async {
  final prefs = await SharedPreferences.getInstance();
  final chatId = prefs.getString('telegram_chat_id');
  
  if (chatId == null || chatId.isEmpty) {
    // Mostra errore
    return;
  }
  
  final message = _telegramService.createMatchReminderMessage(match, 0);
  final success = await _telegramService.sendNotification(
    chatId: chatId,
    message: message,
    matchId: match.id,
  );
  
  // Mostra risultato
}
```

### **PROBLEMA TROVATO:**

🔴 **Le notifiche Telegram NON vengono mai inviate automaticamente!**

Il codice ha:
- ✅ Un metodo di **test manuale** (funziona solo se clicchi sui 3 puntini)
- ❌ **NESSUN** invio automatico quando cambia il punteggio
- ❌ **NESSUNA** integrazione con il monitoraggio live

**Manca completamente:**
- 📱 Invio automatico notifiche Telegram su cambio punteggio
- 🔄 Integrazione tra `followed_matches_updater.dart` e `telegram_service.dart`
- ⚙️ Logica per confrontare punteggi e inviare notifiche

### **Soluzione Proposta:**

✅ **Modificare `followed_matches_page.dart`** per inviare notifiche Telegram quando:
- Il punteggio cambia durante l'aggiornamento automatico (ogni 30 secondi)
- Una partita inizia (elapsed passa da null a > 0)
- Una partita finisce (elapsed >= 90)

✅ **Aggiungere un flag** per evitare notifiche duplicate

✅ **Verificare che il backend Telegram** (`bot-live-proxy.onrender.com`) sia attivo

---

## 📊 **RIEPILOGO PROBLEMI E SOLUZIONI**

| # | Problema | Causa | Soluzione | Priorità |
|---|----------|-------|-----------|----------|
| 1 | Partite non appaiono tra le seguite | Possibile eccezione in `firstWhere` o problema SharedPreferences | Aggiungere log + gestire eccezioni + verificare salvataggio | 🔴 ALTA |
| 2 | Nessuna notifica locale | Logica troppo specifica (solo 0-0 dopo 8') | Riscrivere logica per notificare su ogni goal/cambio | 🔴 ALTA |
| 3 | Nessuna notifica Telegram | Manca invio automatico | Integrare invio Telegram con aggiornamento live | 🟡 MEDIA |

---

## 🎯 **PIANO DI AZIONE**

### **FASE 1: Diagnosi (5 minuti)**
1. ✅ Aggiungere log dettagliati in `_addSelectedToFollowed()`
2. ✅ Aggiungere log in `followMatch()`
3. ✅ Compilare APK con log
4. ✅ Testare e raccogliere log

### **FASE 2: Fix Problema 1 (10 minuti)**
1. ✅ Gestire eccezione `firstWhere` con `orElse`
2. ✅ Verificare salvataggio SharedPreferences
3. ✅ Aggiungere refresh automatico pagina "Partite Seguite"
4. ✅ Testare

### **FASE 3: Fix Problema 2 (20 minuti)**
1. ✅ Salvare stato precedente partite in `MonitorController`
2. ✅ Riscrivere `_processFixtures()` per notificare su:
   - Ogni goal
   - Inizio partita
   - Fine partita
3. ✅ Testare con partite live

### **FASE 4: Fix Problema 3 (15 minuti)**
1. ✅ Modificare `_updateLiveScores()` in `followed_matches_page.dart`
2. ✅ Aggiungere invio notifica Telegram su cambio punteggio
3. ✅ Verificare backend Telegram attivo
4. ✅ Testare

---

## 🔍 **DOMANDE PER L'UTENTE**

Prima di procedere con le correzioni, ho bisogno di sapere:

### **Domanda 1: Notifiche Locali**
Quando vuoi ricevere notifiche locali?
- A) Solo quando la partita è 0-0 dopo 8 minuti (logica attuale)
- B) Su ogni goal segnato
- C) Su ogni cambio punteggio + inizio/fine partita
- D) Personalizzato (specifica)

### **Domanda 2: Notifiche Telegram**
Quando vuoi ricevere notifiche Telegram?
- A) Solo su richiesta manuale (test)
- B) Su ogni goal delle partite seguite
- C) Su ogni cambio punteggio + inizio/fine partita
- D) Personalizzato (specifica)

### **Domanda 3: Backend Telegram**
Hai accesso al backend `bot-live-proxy.onrender.com`?
- A) Sì, posso verificare i log
- B) No, ma so che è attivo
- C) Non so, devo verificare

### **Domanda 4: Priorità**
Quale problema vuoi risolvere per primo?
- A) Problema 1 (Partite seguite)
- B) Problema 2 (Notifiche locali)
- C) Problema 3 (Notifiche Telegram)
- D) Tutti insieme

---

**Attendo le tue risposte per procedere con le correzioni! 🚀**