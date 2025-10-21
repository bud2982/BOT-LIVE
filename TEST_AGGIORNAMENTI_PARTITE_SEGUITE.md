# 🧪 Test: Aggiornamenti Partite Seguite

## Scenario: Verificare che i risultati live si aggiornino

### Step 1: Avviare l'app
```
flutter run
```

### Step 2: Seguire una partita live
1. Vai nella Home
2. Seleziona una partita dalla sezione "Live Now" o "Today's Matches"
3. Premi il pulsante per seguire la partita
4. Verifica che appaia nella sezione "My Followed Matches"

### Step 3: Osservare gli aggiornamenti
Apri la pagina **"My Followed Matches"** e osserva:

#### Cosa Dovrebbe Succedere:
- ✅ I risultati si aggiornano automaticamente (ogni 30 secondi)
- ✅ Se il punteggio cambia, vedrai l'update immediato
- ✅ I log di console mostrano i cambiamenti

#### Log che Vedrai:
```
🔄 Aggiornamento risultati live per 1 partite seguite...
📊 Trovate 1 partite nelle live
✅ AGGIORNAMENTO RILEVATO:
   Vecchio: Team A 0-0 Team B (5')
   Nuovo:   Team A 1-0 Team B (7')
🔄 Aggiornate 1 partite
```

### Step 4: Verificare il Matching Fallback
Se i risultati NON si aggiornano per ID, dovrai vedere:

```
🔍 ID matching fallito per Team A vs Team B (ID: 12345), provo matching alternativo...
✅ Matching alternativo riuscito: trovata partita per squadre e data
```

Se questo appare, significa che il matching fallback ha salvato la situazione!

### Step 5: Test Aggiornamento Globale
Lascia l'app in background e leggi i log. Dovresti vedere:

```
FollowedMatchesUpdater: Inizio aggiornamento partite seguite
FollowedMatchesUpdater: Trovate N partite seguite
FollowedMatchesUpdater: Recuperati M aggiornamenti
```

Questo significa che il servizio globale sta aggiornando le partite anche quando la pagina non è attiva!

---

## 🐛 Debuggare se Ancora Non Funziona

Se gli aggiornamenti ancora non funzionano:

1. **Verifica i log della API**:
   ```
   LiveScoreApiService: ⚠️ ID API non disponibile, generato ID stabile: 123456
   ```
   Se vedi questo, il fallback è in uso

2. **Verifica che l'API restituisce dati**:
   ```
   LiveScoreApiService: matches/live.json - Trovate XX partite live
   ```

3. **Verifica il matching**:
   Leggi se vedi il log "Matching alternativo"

4. **Controlla SharedPreferences**:
   La partita seguita è salvata correttamente?

---

## 📝 Problemi Noti e Soluzioni

| Problema | Soluzione |
|----------|-----------|
| ID non match | ✅ Implementato fallback per squadre+data |
| API non restituisce ID | ✅ Generato ID stabile |
| Partite non si aggiornano | ✅ Servizio globale attivo ogni 30 sec |
| Risultati vecchi | ✅ Aggiornamento quando visualizzi la pagina |

---

## 📞 Prossimi Step se Necessario

Se ancora non funziona, manda i log di:
1. Console quando segui una partita
2. Console quando visualizzi le partite seguite
3. Risultato di `test_followed_matches_debug.dart` (se riesci a farlo girare su device)