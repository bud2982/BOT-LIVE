import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST CHIAVE API RAPIDAPI ===');
  
  const apiKey = '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f';
  const host = 'api-football-v1.p.rapidapi.com';
  const endpoint = 'https://$host/v3/timezone';  // Endpoint semplice per testare l'autenticazione
  
  try {
    print('Invio richiesta di test a $endpoint');
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': host,
      },
    );
    
    print('Codice di stato: ${response.statusCode}');
    print('Headers risposta: ${response.headers}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESSO: La chiave API funziona correttamente!');
      final data = jsonDecode(response.body);
      print('Risposta: ${jsonEncode(data)}');
    } else if (response.statusCode == 403) {
      print('❌ ERRORE 403 FORBIDDEN: Problemi con la chiave API');
      print('Dettagli: ${response.body}');
      print('Possibili cause:');
      print('1. La chiave API potrebbe essere scaduta');
      print('2. Hai raggiunto il limite di richieste del tuo piano');
      print('3. La chiave non ha accesso a questo endpoint specifico');
    } else {
      print('❌ ERRORE ${response.statusCode}: Problema con la richiesta');
      print('Dettagli: ${response.body}');
    }
  } catch (e) {
    print('❌ ECCEZIONE: $e');
    print('Si è verificato un errore durante la connessione all\'API');
  }
  
  // Test endpoint fixtures
  try {
    const fixturesEndpoint = 'https://$host/v3/fixtures?date=2023-12-01';
    print('\nTest endpoint fixtures: $fixturesEndpoint');
    
    final fixturesResponse = await http.get(
      Uri.parse(fixturesEndpoint),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': host,
      },
    );
    
    print('Codice di stato fixtures: ${fixturesResponse.statusCode}');
    
    if (fixturesResponse.statusCode == 200) {
      print('✅ SUCCESSO: Endpoint fixtures funziona!');
      final data = jsonDecode(fixturesResponse.body);
      final results = data['results'];
      print('Numero di partite trovate: $results');
    } else {
      print('❌ ERRORE ${fixturesResponse.statusCode}: Problema con l\'endpoint fixtures');
      print('Dettagli: ${fixturesResponse.body}');
    }
  } catch (e) {
    print('❌ ECCEZIONE endpoint fixtures: $e');
  }
  
  print('=== FINE TEST CHIAVE API ===');
}