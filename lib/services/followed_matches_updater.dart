import 'dart:async';
import '../models/fixture.dart';
import 'followed_matches_service.dart';
import 'hybrid_football_service.dart';

/// Servizio per aggiornare automaticamente le partite seguite con i dati live
class FollowedMatchesUpdater {
  final FollowedMatchesService _followedService = FollowedMatchesService();
  final HybridFootballService _footballService = HybridFootballService();
  
  Timer? _updateTimer;
  bool _isUpdating = false;
  
  /// Avvia l'aggiornamento automatico delle partite seguite
  /// [intervalSeconds] - Intervallo di aggiornamento in secondi (default: 30)
  void startAutoUpdate({int intervalSeconds = 30}) {
    print('FollowedMatchesUpdater: Avvio aggiornamento automatico (ogni $intervalSeconds secondi)');
    
    // Ferma il timer precedente se esiste
    stopAutoUpdate();
    
    // Esegui subito il primo aggiornamento
    updateFollowedMatches();
    
    // Imposta il timer per gli aggiornamenti successivi
    _updateTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      updateFollowedMatches();
    });
  }
  
  /// Ferma l'aggiornamento automatico
  void stopAutoUpdate() {
    if (_updateTimer != null) {
      print('FollowedMatchesUpdater: Fermo aggiornamento automatico');
      _updateTimer?.cancel();
      _updateTimer = null;
    }
  }
  
  /// Aggiorna manualmente le partite seguite con i dati live
  Future<void> updateFollowedMatches() async {
    if (_isUpdating) {
      print('FollowedMatchesUpdater: Aggiornamento già in corso, salto');
      return;
    }
    
    _isUpdating = true;
    
    try {
      print('FollowedMatchesUpdater: Inizio aggiornamento partite seguite');
      
      // Ottieni le partite seguite
      final followedMatches = await _followedService.getFollowedMatches();
      
      if (followedMatches.isEmpty) {
        print('FollowedMatchesUpdater: Nessuna partita seguita');
        return;
      }
      
      print('FollowedMatchesUpdater: Trovate ${followedMatches.length} partite seguite');
      
      // Ottieni gli ID delle partite seguite
      final followedIds = followedMatches.map((m) => m.id).toList();
      print('FollowedMatchesUpdater: IDs partite seguite: $followedIds');
      
      // Recupera i dati aggiornati per queste partite usando getLiveByIds
      // (che ora cerca sia nelle live che nelle fixtures di oggi)
      List<Fixture> updatedData = [];
      try {
        updatedData = await _footballService.getLiveByIds(followedIds);
        print('FollowedMatchesUpdater: Recuperati ${updatedData.length} aggiornamenti');
      } catch (e) {
        print('FollowedMatchesUpdater: Errore getLiveByIds: $e');
        return;
      }
      
      if (updatedData.isEmpty) {
        print('FollowedMatchesUpdater: Nessun aggiornamento disponibile per le partite seguite');
        return;
      }
      
      // Aggiorna ogni partita seguita con i nuovi dati
      int updatedCount = 0;
      for (final updatedMatch in updatedData) {
        final oldMatch = followedMatches.firstWhere(
          (m) => m.id == updatedMatch.id,
          orElse: () => updatedMatch,
        );
        
        // Controlla se ci sono cambiamenti
        final hasChanges = oldMatch.goalsHome != updatedMatch.goalsHome ||
                          oldMatch.goalsAway != updatedMatch.goalsAway ||
                          oldMatch.elapsed != updatedMatch.elapsed;
        
        if (hasChanges) {
          print('FollowedMatchesUpdater: Aggiornamento ${updatedMatch.home} vs ${updatedMatch.away}');
          print('  Vecchio: ${oldMatch.goalsHome}-${oldMatch.goalsAway} (${oldMatch.elapsed ?? "N/A"}\')');
          print('  Nuovo: ${updatedMatch.goalsHome}-${updatedMatch.goalsAway} (${updatedMatch.elapsed ?? "N/A"}\')');
          
          // Usa copyWith per preservare il campo 'start' originale
          final mergedMatch = oldMatch.copyWith(
            goalsHome: updatedMatch.goalsHome,
            goalsAway: updatedMatch.goalsAway,
            elapsed: updatedMatch.elapsed,
          );
          
          // Aggiorna la partita seguita
          await _followedService.unfollowMatch(mergedMatch.id);
          await _followedService.followMatch(mergedMatch);
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) {
        print('FollowedMatchesUpdater: ✅ Aggiornate $updatedCount partite');
      } else {
        print('FollowedMatchesUpdater: Nessuna modifica rilevata');
      }
      
    } catch (e) {
      print('FollowedMatchesUpdater: ❌ Errore durante l\'aggiornamento: $e');
    } finally {
      _isUpdating = false;
    }
  }
  
  /// Pulisce le risorse
  void dispose() {
    stopAutoUpdate();
  }
}