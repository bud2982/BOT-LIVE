import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST SOTTOSCRIZIONE API FOOTBALL SU RAPIDAPI ===');
  
  const apiKey = '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f';
  const host = 'api-football-v1.p.rapidapi.com';
  
  // Test endpoint status (dovrebbe funzionare anche con sottoscrizione base)
  try {
    const statusEndpoint = 'https://$host/v3/status';
    print('\nTest endpoint status: $statusEndpoint');
    
    final statusResponse = await http.get(
      Uri.parse(statusEndpoint),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': host,
      },
    );
    
    print('Codice di stato: ${statusResponse.statusCode}');
    print('Headers risposta: ${statusResponse.headers}');
    
    if (statusResponse.statusCode == 200) {
      print('✅ SUCCESSO: Endpoint status funziona!');
      final data = jsonDecode(statusResponse.body);
      print('Risposta: ${jsonEncode(data)}');
      print('\nLa tua sottoscrizione all\'API Football su RapidAPI è attiva.');
    } else if (statusResponse.statusCode == 403) {
      print('❌ ERRORE 403 FORBIDDEN: Non sei iscritto all\'API Football su RapidAPI');
      print('Dettagli: ${statusResponse.body}');
      print('\nDevi iscriverti all\'API Football su RapidAPI:');
      print('1. Accedi al tuo account RapidAPI');
      print('2. Cerca "API-Football" tra le API disponibili');
      print('3. Iscriviti al piano gratuito (Basic) dell\'API-Football');
    } else if (statusResponse.statusCode == 429) {
      print('❌ ERRORE 429 TOO MANY REQUESTS: Hai raggiunto il limite di richieste');
      print('Dettagli: ${statusResponse.body}');
      print('\nHai raggiunto il limite di richieste del tuo piano Basic.');
      print('Attendi che il limite si resetti o considera l\'upgrade a un piano superiore.');
    } else {
      print('❌ ERRORE ${statusResponse.statusCode}: Problema con la richiesta');
      print('Dettagli: ${statusResponse.body}');
    }
  } catch (e) {
    print('❌ ECCEZIONE: $e');
    print('Si è verificato un errore durante la connessione all\'API');
  }
  
  print('=== FINE TEST SOTTOSCRIZIONE ===');
}