import 'dart:convert';
import 'package:http/http.dart' as http;

// Test per verificare se LiveScore API supporta paginazione o filtri per ottenere più partite
void main() async {
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  print('🔍 TEST LIVESCORE API - Ricerca parametri per ottenere più partite\n');
  print('=' * 80);
  
  // Test 1: Endpoint fixtures/matches.json (quello attuale)
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {},
    'Endpoint attuale (senza parametri)'
  );
  
  // Test 2: Con parametro date esplicito
  final today = DateTime.now();
  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {'date': dateStr},
    'Con parametro date=$dateStr'
  );
  
  // Test 3: Endpoint fixtures/list.json
  await testEndpoint(
    'fixtures/list.json',
    baseUrl,
    apiKey,
    apiSecret,
    {},
    'Endpoint fixtures/list.json'
  );
  
  // Test 4: Con parametro from/to
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {'from': dateStr, 'to': dateStr},
    'Con parametri from/to'
  );
  
  // Test 5: Con parametro page (paginazione)
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {'page': '1'},
    'Con parametro page=1'
  );
  
  // Test 6: Con parametro limit
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {'limit': '100'},
    'Con parametro limit=100'
  );
  
  // Test 7: Endpoint leagues/list.json per vedere le leghe disponibili
  await testEndpoint(
    'leagues/list.json',
    baseUrl,
    apiKey,
    apiSecret,
    {},
    'Endpoint leagues/list.json (per vedere leghe disponibili)'
  );
  
  // Test 8: Combinazione di parametri
  await testEndpoint(
    'fixtures/matches.json',
    baseUrl,
    apiKey,
    apiSecret,
    {'date': dateStr, 'page': '1', 'limit': '100'},
    'Con date + page + limit'
  );
  
  print('\n' + '=' * 80);
  print('✅ Test completati!');
  print('\n💡 SUGGERIMENTI:');
  print('   - Se un endpoint restituisce più partite, usalo nell\'app');
  print('   - Se supporta paginazione, implementa chiamate multiple');
  print('   - Se supporta filtri per lega, chiama per ogni lega importante');
}

Future<void> testEndpoint(
  String endpoint,
  String baseUrl,
  String apiKey,
  String apiSecret,
  Map<String, String> extraParams,
  String description
) async {
  try {
    print('\n📡 TEST: $description');
    print('   Endpoint: $endpoint');
    if (extraParams.isNotEmpty) {
      print('   Parametri extra: $extraParams');
    }
    
    // Costruisci URL con parametri
    final params = {
      'key': apiKey,
      'secret': apiSecret,
      ...extraParams,
    };
    
    final uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params);
    print('   URL: ${uri.toString().replaceAll(apiKey, 'KEY').replaceAll(apiSecret, 'SECRET')}');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Conta le partite
      int matchCount = 0;
      List<dynamic>? dataKeys;
      
      if (data is Map) {
        dataKeys = data.keys.toList();
        
        // Cerca array di partite in vari formati
        if (data['data'] != null) {
          final dataSection = data['data'];
          if (dataSection is Map) {
            if (dataSection['match'] is List) {
              matchCount = (dataSection['match'] as List).length;
            } else if (dataSection['fixtures'] is List) {
              matchCount = (dataSection['fixtures'] as List).length;
            } else if (dataSection['fixture'] is List) {
              matchCount = (dataSection['fixture'] as List).length;
            }
          } else if (dataSection is List) {
            matchCount = dataSection.length;
          }
        } else if (data['matches'] is List) {
          matchCount = (data['matches'] as List).length;
        } else if (data['fixtures'] is List) {
          matchCount = (data['fixtures'] as List).length;
        } else if (data['leagues'] is List) {
          matchCount = (data['leagues'] as List).length;
          print('   ℹ️  Questo endpoint restituisce leghe, non partite');
        }
        
        print('   Chiavi nella risposta: $dataKeys');
      } else if (data is List) {
        matchCount = data.length;
      }
      
      print('   ✅ Partite/elementi trovati: $matchCount');
      
      // Mostra un esempio di partita se disponibile
      if (matchCount > 0 && data is Map && data['data'] != null) {
        final dataSection = data['data'];
        dynamic firstMatch;
        
        if (dataSection is Map) {
          if (dataSection['match'] is List && (dataSection['match'] as List).isNotEmpty) {
            firstMatch = (dataSection['match'] as List)[0];
          } else if (dataSection['fixtures'] is List && (dataSection['fixtures'] as List).isNotEmpty) {
            firstMatch = (dataSection['fixtures'] as List)[0];
          } else if (dataSection['leagues'] is List && (dataSection['leagues'] as List).isNotEmpty) {
            firstMatch = (dataSection['leagues'] as List)[0];
          }
        }
        
        if (firstMatch != null) {
          print('   📋 Esempio primo elemento:');
          final keys = (firstMatch as Map).keys.take(10).toList();
          print('      Chiavi disponibili: $keys');
          
          // Mostra info partita se disponibile
          if (firstMatch['home'] != null || firstMatch['home_name'] != null) {
            final home = firstMatch['home']?['name'] ?? firstMatch['home_name'] ?? 'N/A';
            final away = firstMatch['away']?['name'] ?? firstMatch['away_name'] ?? 'N/A';
            print('      Partita: $home vs $away');
          } else if (firstMatch['name'] != null) {
            print('      Nome: ${firstMatch['name']}');
          }
        }
      }
      
      // Controlla se ci sono info sulla paginazione
      if (data is Map) {
        if (data['total'] != null) {
          print('   📊 Total disponibile: ${data['total']}');
        }
        if (data['page'] != null) {
          print('   📄 Page disponibile: ${data['page']}');
        }
        if (data['pages'] != null) {
          print('   📄 Pages disponibile: ${data['pages']}');
        }
        if (data['per_page'] != null) {
          print('   📄 Per_page disponibile: ${data['per_page']}');
        }
      }
      
    } else if (response.statusCode == 401) {
      print('   ❌ Errore 401: Chiave API non valida');
    } else if (response.statusCode == 404) {
      print('   ❌ Errore 404: Endpoint non trovato');
    } else if (response.statusCode == 429) {
      print('   ❌ Errore 429: Troppi richieste (rate limit)');
    } else {
      print('   ❌ Errore ${response.statusCode}');
      if (response.body.length < 200) {
        print('   Risposta: ${response.body}');
      }
    }
    
  } catch (e) {
    print('   ❌ Errore: $e');
  }
  
  // Pausa tra richieste per evitare rate limiting
  await Future.delayed(const Duration(seconds: 2));
}