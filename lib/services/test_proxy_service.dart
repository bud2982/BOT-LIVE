import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class TestProxyService {
  static const String _baseUrl = 'http://localhost:3001';
  
  Future<List<Fixture>> getFixturesToday() async {
    print('TestProxyService: Recupero partite di test dal proxy server...');
    
    try {
      final url = Uri.parse('$_baseUrl/api/livescore');
      
      print('TestProxyService: Richiesta a $url');
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));
      
      print('TestProxyService: Risposta ricevuta - Status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Errore server proxy: ${response.statusCode} - ${response.body}');
      }
      
      if (response.body.isEmpty) {
        throw Exception('Risposta server proxy vuota');
      }
      
      final data = json.decode(response.body);
      print('TestProxyService: Dati ricevuti: ${response.body.substring(0, 200)}...');
      
      // Parse della risposta del proxy
      final fixtures = _parseProxyResponse(data);
      print('TestProxyService: Convertite ${fixtures.length} partite');
      
      return fixtures;
      
    } catch (e) {
      print('TestProxyService: Errore: $e');
      rethrow;
    }
  }
  
  List<Fixture> _parseProxyResponse(Map<String, dynamic> data) {
    try {
      final List<Fixture> fixtures = [];
      
      if (data['success'] == true && data['matches'] != null) {
        final matches = data['matches'] as List<dynamic>;
        
        for (final match in matches) {
          try {
            final fixture = Fixture(
              id: match['id'] ?? 0,
              home: match['home'] ?? 'Team Casa',
              away: match['away'] ?? 'Team Ospite',
              goalsHome: match['goalsHome'] ?? 0,
              goalsAway: match['goalsAway'] ?? 0,
              start: DateTime.tryParse(match['start'] ?? '') ?? DateTime.now(),
              elapsed: match['elapsed'],
              league: match['league'] ?? 'Lega Sconosciuta',
              country: match['country'] ?? 'Other',
            );
            fixtures.add(fixture);
          } catch (e) {
            print('TestProxyService: Errore parsing singola partita: $e');
            continue;
          }
        }
      }
      
      return fixtures;
      
    } catch (e) {
      print('TestProxyService: Errore parsing risposta: $e');
      return [];
    }
  }
}