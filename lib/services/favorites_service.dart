import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_matches';
  static FavoritesService? _instance;
  
  FavoritesService._();
  
  static FavoritesService get instance {
    _instance ??= FavoritesService._();
    return _instance!;
  }
  
  // Lista delle partite preferite (solo gli ID)
  Set<int> _favoriteIds = <int>{};
  
  // Callback per notificare i cambiamenti
  List<Function()> _listeners = [];
  
  // Inizializza il servizio caricando i preferiti salvati
  Future<void> initialize() async {
    await _loadFavorites();
  }
  
  // Carica i preferiti dal storage locale
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favoriteIds = favoritesList.cast<int>().toSet();
      }
    } catch (e) {
      print('Errore nel caricamento dei preferiti: $e');
      _favoriteIds = <int>{};
    }
  }
  
  // Salva i preferiti nel storage locale
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(_favoriteIds.toList());
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Errore nel salvataggio dei preferiti: $e');
    }
  }
  
  // Aggiunge una partita ai preferiti
  Future<void> addToFavorites(int fixtureId) async {
    _favoriteIds.add(fixtureId);
    await _saveFavorites();
    _notifyListeners();
  }
  
  // Rimuove una partita dai preferiti
  Future<void> removeFromFavorites(int fixtureId) async {
    _favoriteIds.remove(fixtureId);
    await _saveFavorites();
    _notifyListeners();
  }
  
  // Controlla se una partita è nei preferiti
  bool isFavorite(int fixtureId) {
    return _favoriteIds.contains(fixtureId);
  }
  
  // Ottiene tutti gli ID delle partite preferite
  Set<int> get favoriteIds => Set.from(_favoriteIds);
  
  // Filtra una lista di partite per ottenere solo quelle preferite
  List<Fixture> filterFavorites(List<Fixture> allFixtures) {
    return allFixtures.where((fixture) => isFavorite(fixture.id)).toList();
  }
  
  // Aggiunge un listener per i cambiamenti
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  // Rimuove un listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  // Notifica tutti i listener dei cambiamenti
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        print('Errore nel listener dei preferiti: $e');
      }
    }
  }
  
  // Pulisce tutti i preferiti
  Future<void> clearAllFavorites() async {
    _favoriteIds.clear();
    await _saveFavorites();
    _notifyListeners();
  }
  
  // Ottiene il numero di partite preferite
  int get favoritesCount => _favoriteIds.length;
}