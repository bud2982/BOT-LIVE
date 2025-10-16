import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 TEST RILEVAMENTO PARTITE LIVE\n');
  print('=' * 60);
  
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  // Test 1: fixtures/list.json (partite di oggi)
  print('\n📋 TEST 1: fixtures/list.json (partite di oggi)');
  print('-' * 60);
  
  try {
    final fixturesUrl = Uri.parse('$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret&page=1');
    final fixturesResponse = await http.get(fixturesUrl).timeout(const Duration(seconds: 30));
    
    if (fixturesResponse.statusCode == 200) {
      final fixturesData = json.decode(fixturesResponse.body);
      final matches = fixturesData['data']['match'] as List<dynamic>;
      
      print('✅ Recuperate ${matches.length} partite');
      print('\nAnalisi prime 5 partite:');
      
      for (int i = 0; i < 5 && i < matches.length; i++) {
        final match = matches[i];
        print('\n--- Partita ${i + 1} ---');
        print('ID: ${match['id']}');
        print('Home: ${match['home']?['name'] ?? 'N/A'}');
        print('Away: ${match['away']?['name'] ?? 'N/A'}');
        print('Status: ${match['status']}');
        print('Time: ${match['time']}');
        print('Elapsed: ${match['elapsed']}');
        print('Minute: ${match['minute']}');
        
        // Analizza il punteggio
        if (match['scores'] != null && match['scores']['score'] != null) {
          print('Score: ${match['scores']['score']}');
        }
        
        // Determina se è live
        final status = match['status']?.toString().toLowerCase() ?? '';
        final isLive = status.contains('in play') || 
                       status.contains('live') || 
                       status.contains('playing') ||
                       (match['minute'] != null && int.tryParse(match['minute'].toString()) != null);
        
        print('🔴 È LIVE? ${isLive ? "SÌ" : "NO"}');
      }
    } else {
      print('❌ Errore: ${fixturesResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Errore fixtures: $e');
  }
  
  // Test 2: matches/live.json (partite live)
  print('\n\n🔴 TEST 2: matches/live.json (partite live)');
  print('-' * 60);
  
  try {
    final liveUrl = Uri.parse('$baseUrl/matches/live.json?key=$apiKey&secret=$apiSecret');
    final liveResponse = await http.get(liveUrl).timeout(const Duration(seconds: 30));
    
    if (liveResponse.statusCode == 200) {
      final liveData = json.decode(liveResponse.body);
      
      // Prova diversi formati
      List<dynamic>? liveMatches;
      if (liveData['data'] != null && liveData['data']['match'] != null) {
        liveMatches = liveData['data']['match'] as List<dynamic>;
      } else if (liveData['data'] != null && liveData['data'] is List) {
        liveMatches = liveData['data'] as List<dynamic>;
      } else if (liveData['matches'] != null) {
        liveMatches = liveData['matches'] as List<dynamic>;
      }
      
      if (liveMatches != null && liveMatches.isNotEmpty) {
        print('✅ Recuperate ${liveMatches.length} partite live');
        print('\nAnalisi prime 3 partite live:');
        
        for (int i = 0; i < 3 && i < liveMatches.length; i++) {
          final match = liveMatches[i];
          print('\n--- Partita Live ${i + 1} ---');
          print('ID: ${match['id']}');
          print('Home: ${match['home']?['name'] ?? 'N/A'}');
          print('Away: ${match['away']?['name'] ?? 'N/A'}');
          print('Status: ${match['status']}');
          print('Time: ${match['time']}');
          print('Elapsed: ${match['elapsed']}');
          print('Minute: ${match['minute']}');
          
          if (match['scores'] != null && match['scores']['score'] != null) {
            print('Score: ${match['scores']['score']}');
          }
        }
      } else {
        print('⚠️ Nessuna partita live al momento');
        print('Struttura risposta:');
        print(json.encode(liveData).substring(0, 500));
      }
    } else {
      print('❌ Errore: ${liveResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Errore live: $e');
  }
  
  // Test 3: Confronto tra fixtures e live
  print('\n\n🔄 TEST 3: Confronto fixtures vs live');
  print('-' * 60);
  
  try {
    // Recupera entrambi
    final fixturesUrl = Uri.parse('$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret&page=1');
    final liveUrl = Uri.parse('$baseUrl/matches/live.json?key=$apiKey&secret=$apiSecret');
    
    final fixturesResponse = await http.get(fixturesUrl).timeout(const Duration(seconds: 30));
    final liveResponse = await http.get(liveUrl).timeout(const Duration(seconds: 30));
    
    if (fixturesResponse.statusCode == 200 && liveResponse.statusCode == 200) {
      final fixturesData = json.decode(fixturesResponse.body);
      final liveData = json.decode(liveResponse.body);
      
      final fixturesMatches = fixturesData['data']['match'] as List<dynamic>;
      
      // Conta partite live in fixtures
      int liveInFixtures = 0;
      for (final match in fixturesMatches) {
        final status = match['status']?.toString().toLowerCase() ?? '';
        if (status.contains('in play') || status.contains('live') || status.contains('playing')) {
          liveInFixtures++;
        }
      }
      
      print('📊 Partite totali in fixtures: ${fixturesMatches.length}');
      print('🔴 Partite live in fixtures (status): $liveInFixtures');
      
      // Conta partite live nell'endpoint live
      List<dynamic>? liveMatches;
      if (liveData['data'] != null && liveData['data']['match'] != null) {
        liveMatches = liveData['data']['match'] as List<dynamic>;
      } else if (liveData['data'] != null && liveData['data'] is List) {
        liveMatches = liveData['data'] as List<dynamic>;
      }
      
      print('🔴 Partite nell\'endpoint live: ${liveMatches?.length ?? 0}');
      
      if (liveInFixtures == 0 && (liveMatches?.isEmpty ?? true)) {
        print('\n⚠️ NESSUNA PARTITA LIVE AL MOMENTO');
        print('Questo è normale se non ci sono partite in corso.');
      } else if (liveInFixtures > 0 && (liveMatches?.isEmpty ?? true)) {
        print('\n⚠️ PROBLEMA: Fixtures ha partite live ma l\'endpoint live è vuoto!');
      } else if (liveInFixtures == 0 && (liveMatches?.isNotEmpty ?? false)) {
        print('\n⚠️ PROBLEMA: Endpoint live ha partite ma fixtures non le marca come live!');
      } else {
        print('\n✅ Coerenza tra fixtures e endpoint live');
      }
    }
  } catch (e) {
    print('❌ Errore confronto: $e');
  }
  
  print('\n' + '=' * 60);
  print('✅ Test completato');
}