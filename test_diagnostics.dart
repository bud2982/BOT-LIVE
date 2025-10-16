import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 TEST DIAGNOSTICO COMPLETO');
  print('=' * 80);
  
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  // Test 1: Fixtures List (partite di oggi)
  print('\n📋 TEST 1: FIXTURES LIST (Partite di oggi)');
  print('-' * 80);
  await testEndpoint(
    '$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret',
    'fixtures/list.json'
  );
  
  // Test 2: Matches Live (partite in corso)
  print('\n🔴 TEST 2: MATCHES LIVE (Partite in corso)');
  print('-' * 80);
  await testEndpoint(
    '$baseUrl/matches/live.json?key=$apiKey&secret=$apiSecret',
    'matches/live.json'
  );
  
  // Test 3: Fixtures Matches (alternativa)
  print('\n⚽ TEST 3: FIXTURES MATCHES (Alternativa)');
  print('-' * 80);
  await testEndpoint(
    '$baseUrl/fixtures/matches.json?key=$apiKey&secret=$apiSecret',
    'fixtures/matches.json'
  );
  
  // Test 4: Leagues (competizioni disponibili)
  print('\n🏆 TEST 4: LEAGUES (Competizioni disponibili)');
  print('-' * 80);
  await testEndpoint(
    '$baseUrl/leagues/list.json?key=$apiKey&secret=$apiSecret',
    'leagues/list.json'
  );
  
  print('\n' + '=' * 80);
  print('✅ TEST DIAGNOSTICO COMPLETATO');
}

Future<void> testEndpoint(String url, String name) async {
  try {
    print('📡 Richiesta a: $name');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Analizza la struttura della risposta
      if (data is Map) {
        print('   Tipo: Map');
        print('   Chiavi: ${data.keys.join(", ")}');
        
        if (data['success'] == true) {
          print('   ✅ Success: true');
          
          if (data['data'] != null) {
            final dataSection = data['data'];
            
            if (dataSection is Map) {
              print('   Data keys: ${dataSection.keys.join(", ")}');
              
              // Conta le partite
              int matchCount = 0;
              List<dynamic>? matches;
              
              if (dataSection['match'] is List) {
                matches = dataSection['match'];
                matchCount = matches?.length ?? 0;
              } else if (dataSection['fixtures'] is List) {
                matches = dataSection['fixtures'];
                matchCount = matches?.length ?? 0;
              } else if (dataSection['fixture'] is List) {
                matches = dataSection['fixture'];
                matchCount = matches?.length ?? 0;
              } else if (dataSection['league'] is List) {
                matches = dataSection['league'];
                matchCount = matches?.length ?? 0;
              }
              
              print('   📊 Totale elementi: $matchCount');
              
              // Analizza le prime 3 partite
              if (matches != null && matches.isNotEmpty) {
                print('\n   🔍 ANALISI PRIME 3 PARTITE:');
                for (int i = 0; i < (matches.length > 3 ? 3 : matches.length); i++) {
                  final match = matches[i];
                  print('   \n   Partita ${i + 1}:');
                  
                  if (match is Map) {
                    // Squadre
                    final home = match['home']?['name'] ?? match['home_name'] ?? 'N/A';
                    final away = match['away']?['name'] ?? match['away_name'] ?? 'N/A';
                    print('      Squadre: $home vs $away');
                    
                    // Punteggio
                    final score = match['scores']?['score'] ?? 
                                 '${match['score']?['home'] ?? 0} - ${match['score']?['away'] ?? 0}';
                    print('      Score: $score');
                    
                    // Tempo
                    final elapsed = match['elapsed'] ?? match['time'] ?? match['minute'] ?? 'N/A';
                    print('      Elapsed: $elapsed');
                    
                    // Status
                    final status = match['status'] ?? 'N/A';
                    print('      Status: $status');
                    
                    // Paese
                    final country = match['country']?['name'] ?? 
                                   match['country'] ?? 
                                   match['location']?['country']?['name'] ?? 
                                   'N/A';
                    print('      Country: $country');
                    
                    // Lega
                    final league = match['competition']?['name'] ?? 
                                  match['league']?['name'] ?? 
                                  match['league'] ?? 
                                  'N/A';
                    print('      League: $league');
                    
                    // Orario
                    final time = match['time'] ?? match['scheduled'] ?? match['start_time'] ?? 'N/A';
                    print('      Time: $time');
                  }
                }
                
                // Statistiche sui paesi
                print('\n   🌍 DISTRIBUZIONE PER PAESE:');
                final Map<String, int> countryStats = {};
                for (final match in matches) {
                  if (match is Map) {
                    final country = match['country']?['name'] ?? 
                                   match['country'] ?? 
                                   match['location']?['country']?['name'] ?? 
                                   'Unknown';
                    countryStats[country] = (countryStats[country] ?? 0) + 1;
                  }
                }
                
                final sortedCountries = countryStats.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                
                for (final entry in sortedCountries.take(10)) {
                  print('      ${entry.key}: ${entry.value} partite');
                }
                
                // Statistiche sullo status
                print('\n   📊 DISTRIBUZIONE PER STATUS:');
                final Map<String, int> statusStats = {};
                for (final match in matches) {
                  if (match is Map) {
                    final status = match['status']?.toString() ?? 'Unknown';
                    statusStats[status] = (statusStats[status] ?? 0) + 1;
                  }
                }
                
                for (final entry in statusStats.entries) {
                  print('      ${entry.key}: ${entry.value} partite');
                }
                
                // Conta partite live (con elapsed)
                int liveCount = 0;
                for (final match in matches) {
                  if (match is Map) {
                    if (match['elapsed'] != null || 
                        (match['status']?.toString().toLowerCase().contains('live') ?? false) ||
                        (match['status']?.toString().toLowerCase().contains('play') ?? false)) {
                      liveCount++;
                    }
                  }
                }
                print('\n   🔴 Partite LIVE (con elapsed o status live): $liveCount');
              }
            }
          }
        } else {
          print('   ❌ Success: false');
          if (data['error'] != null) {
            print('   Error: ${data['error']}');
          }
        }
      }
      
      // Mostra un sample della risposta
      print('\n   📄 Sample risposta (primi 500 caratteri):');
      print('   ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      
    } else {
      print('   ❌ Errore HTTP: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
    
  } catch (e) {
    print('   💥 Errore: $e');
  }
  
  print('');
}