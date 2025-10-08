import 'package:live_bot/services/api_football_service.dart';

void main() async {
  print('=== TEST RECUPERO PARTITE ===');
  
  // Inizializza il servizio API con la chiave RapidAPI
  print('Inizializzazione servizio API...');
  final apiService = ApiFootballService(
    '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f', 
    useSampleData: false, // Prova a usare dati reali
    useRealisticSimulation: false
  );
  
  // Recupera le partite di oggi
  print('Recupero partite di oggi...');
  final fixtures = await apiService.getFixturesToday();
  print('Partite recuperate: ${fixtures.length}');
  
  // Stampa tutte le partite
  print('\nElenco partite di oggi:');
  for (var i = 0; i < fixtures.length; i++) {
    final f = fixtures[i];
    print('${i+1}. ${f.home} vs ${f.away} - Inizio: ${f.start.toString().substring(0, 16)}');
  }
  
  print('\n=== TEST COMPLETATO ===');
}