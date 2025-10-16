import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test per verificare i limiti dell'API LiveScore a pagamento
/// e scoprire come ottenere TUTTE le partite disponibili
void main() async {
  print('🔍 TEST LIMITI API LIVESCORE (Account a Pagamento)');
  print('=' * 60);
  
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  // Test 1: Fixtures senza parametri (comportamento attuale)
  print('\n📋 TEST 1: /fixtures/list.json (SENZA PARAMETRI)');
  print('-' * 60);
  await testEndpoint(
    '$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret',
    'Fixtures Default'
  );
  
  // Test 2: Fixtures con data specifica (oggi)
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  print('\n📋 TEST 2: /fixtures/list.json (CON DATA: $todayStr)');
  print('-' * 60);
  await testEndpoint(
    '$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret&from=$todayStr&to=$todayStr',
    'Fixtures con Data'
  );
  
  // Test 3: Scores/live (endpoint alternativo)
  print('\n📋 TEST 3: /scores/live.json');
  print('-' * 60);
  await testEndpoint(
    '$baseUrl/scores/live.json?key=$apiKey&secret=$apiSecret',
    'Scores Live'
  );
  
  // Test 4: Matches/live (endpoint attuale per live)
  print('\n📋 TEST 4: /matches/live.json');
  print('-' * 60);
  await testEndpoint(
    '$baseUrl/matches/live.json?key=$apiKey&secret=$apiSecret',
    'Matches Live'
  );
  
  // Test 5: Fixtures con paginazione (se supportata)
  print('\n📋 TEST 5: /fixtures/list.json (CON PAGINAZIONE - Pagina 2)');
  print('-' * 60);
  await testEndpoint(
    '$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret&page=2',
    'Fixtures Pagina 2'
  );
  
  // Test 6: Leagues/list per vedere tutte le competizioni disponibili
  print('\n📋 TEST 6: /leagues/list.json (COMPETIZIONI DISPONIBILI)');
  print('-' * 60);
  await testLeagues(
    '$baseUrl/leagues/list.json?key=$apiKey&secret=$apiSecret'
  );
  
  print('\n' + '=' * 60);
  print('✅ TEST COMPLETATI');
  print('=' * 60);
}

Future<void> testEndpoint(String url, String name) async {
  try {
    print('🔄 Richiesta a: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('📊 Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Analizza la struttura della risposta
      print('📦 Struttura risposta:');
      print('   - success: ${data['success']}');
      
      // Trova l'array di partite (può essere in posizioni diverse)
      List<dynamic>? matches;
      int totalMatches = 0;
      
      if (data['data'] != null) {
        if (data['data']['match'] != null) {
          matches = data['data']['match'] as List<dynamic>?;
          totalMatches = matches?.length ?? 0;
          print('   - data.match: $totalMatches partite');
        } else if (data['data']['fixtures'] != null) {
          matches = data['data']['fixtures'] as List<dynamic>?;
          totalMatches = matches?.length ?? 0;
          print('   - data.fixtures: $totalMatches partite');
        } else if (data['data'] is List) {
          matches = data['data'] as List<dynamic>?;
          totalMatches = matches?.length ?? 0;
          print('   - data (array): $totalMatches partite');
        } else {
          print('   - data: ${data['data'].runtimeType}');
          print('   - Chiavi in data: ${(data['data'] as Map).keys.join(', ')}');
        }
      } else if (data['matches'] != null) {
        matches = data['matches'] as List<dynamic>?;
        totalMatches = matches?.length ?? 0;
        print('   - matches: $totalMatches partite');
      }
      
      // Controlla se ci sono informazioni sulla paginazione
      if (data['pagination'] != null) {
        print('   - pagination: ${data['pagination']}');
      }
      if (data['total'] != null) {
        print('   - total: ${data['total']}');
      }
      if (data['page'] != null) {
        print('   - page: ${data['page']}');
      }
      if (data['per_page'] != null) {
        print('   - per_page: ${data['per_page']}');
      }
      
      print('\n✅ TOTALE PARTITE TROVATE: $totalMatches');
      
      // Analizza le prime 3 partite per vedere i dati disponibili
      if (matches != null && matches.isNotEmpty) {
        print('\n📝 ESEMPIO PARTITE (prime 3):');
        for (int i = 0; i < (matches.length > 3 ? 3 : matches.length); i++) {
          final match = matches[i];
          final home = match['home']?['name'] ?? match['home_name'] ?? 'N/A';
          final away = match['away']?['name'] ?? match['away_name'] ?? 'N/A';
          final league = match['league']?['name'] ?? match['competition']?['name'] ?? match['competition_name'] ?? 'N/A';
          final country = match['country']?['name'] ?? match['league']?['country'] ?? 'N/A';
          
          print('   ${i + 1}. $home vs $away');
          print('      League: $league');
          print('      Country: $country');
        }
        
        // Conta partite per paese
        final Map<String, int> countryCounts = {};
        for (final match in matches) {
          final country = match['country']?['name'] ?? match['league']?['country'] ?? 'Unknown';
          countryCounts[country] = (countryCounts[country] ?? 0) + 1;
        }
        
        print('\n📊 DISTRIBUZIONE PER PAESE:');
        final sortedCountries = countryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final entry in sortedCountries.take(10)) {
          print('   ${entry.key}: ${entry.value} partite');
        }
        
        // Cerca partite internazionali
        final internationalMatches = matches.where((match) {
          final league = (match['league']?['name'] ?? match['competition']?['name'] ?? match['competition_name'] ?? '').toString().toLowerCase();
          return league.contains('champions') || 
                 league.contains('europa') || 
                 league.contains('world') ||
                 league.contains('international') ||
                 league.contains('uefa') ||
                 league.contains('fifa');
        }).toList();
        
        if (internationalMatches.isNotEmpty) {
          print('\n🌍 PARTITE INTERNAZIONALI TROVATE: ${internationalMatches.length}');
          for (final match in internationalMatches.take(5)) {
            final home = match['home']?['name'] ?? match['home_name'] ?? 'N/A';
            final away = match['away']?['name'] ?? match['away_name'] ?? 'N/A';
            final league = match['league']?['name'] ?? match['competition']?['name'] ?? 'N/A';
            print('   - $home vs $away ($league)');
          }
        } else {
          print('\n⚠️ NESSUNA PARTITA INTERNAZIONALE TROVATA');
        }
      }
      
    } else {
      print('❌ Errore: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
    
  } catch (e) {
    print('❌ ERRORE: $e');
  }
}

Future<void> testLeagues(String url) async {
  try {
    print('🔄 Richiesta a: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('📊 Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Trova l'array di leghe
      List<dynamic>? leagues;
      
      if (data['data'] != null) {
        if (data['data']['league'] != null) {
          leagues = data['data']['league'] as List<dynamic>?;
        } else if (data['data'] is List) {
          leagues = data['data'] as List<dynamic>?;
        }
      }
      
      if (leagues != null && leagues.isNotEmpty) {
        print('\n✅ TOTALE COMPETIZIONI DISPONIBILI: ${leagues.length}');
        
        // Cerca competizioni internazionali
        final internationalLeagues = leagues.where((league) {
          final name = (league['name'] ?? '').toString().toLowerCase();
          return name.contains('champions') || 
                 name.contains('europa') || 
                 name.contains('world') ||
                 name.contains('uefa') ||
                 name.contains('fifa') ||
                 name.contains('international');
        }).toList();
        
        if (internationalLeagues.isNotEmpty) {
          print('\n🌍 COMPETIZIONI INTERNAZIONALI DISPONIBILI:');
          for (final league in internationalLeagues) {
            final id = league['id'] ?? 'N/A';
            final name = league['name'] ?? 'N/A';
            final country = league['country']?['name'] ?? 'International';
            print('   - ID: $id | $name ($country)');
          }
          
          print('\n💡 SUGGERIMENTO: Puoi filtrare per competition_id per ottenere partite specifiche');
          print('   Esempio: /fixtures/list.json?key=...&competition_id=ID_COMPETIZIONE');
        }
        
        // Mostra prime 10 leghe
        print('\n📝 PRIME 10 COMPETIZIONI:');
        for (int i = 0; i < (leagues.length > 10 ? 10 : leagues.length); i++) {
          final league = leagues[i];
          final id = league['id'] ?? 'N/A';
          final name = league['name'] ?? 'N/A';
          final country = league['country']?['name'] ?? 'N/A';
          print('   ${i + 1}. ID: $id | $name ($country)');
        }
      }
      
    } else {
      print('❌ Errore: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
    
  } catch (e) {
    print('❌ ERRORE: $e');
  }
}