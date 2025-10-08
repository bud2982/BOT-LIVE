import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST API GRATUITE SU RAPIDAPI ===');
  
  const apiKey = '579a87ccc9msha9746fe3358bb2bp1e42a9jsnf000b28c9f8f';
  
  // Test di un'API gratuita su RapidAPI (World Time API)
  try {
    const host = 'world-time-by-api-ninjas.p.rapidapi.com';
    const endpoint = 'https://$host/v1/worldtime?city=Rome';
    
    print('\nTest API gratuita (World Time): $endpoint');
    
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': host,
      },
    );
    
    print('Codice di stato: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESSO: La tua chiave RapidAPI funziona con API gratuite!');
      final data = jsonDecode(response.body);
      print('Risposta: ${jsonEncode(data)}');
      print('\nLa tua chiave RapidAPI è valida e può essere utilizzata con API gratuite.');
    } else if (response.statusCode == 403) {
      print('❌ ERRORE 403 FORBIDDEN: Problemi con la chiave RapidAPI');
      print('Dettagli: ${response.body}');
    } else {
      print('❌ ERRORE ${response.statusCode}: Problema con la richiesta');
      print('Dettagli: ${response.body}');
    }
  } catch (e) {
    print('❌ ECCEZIONE: $e');
  }
  
  print('=== FINE TEST API GRATUITE ===');
}