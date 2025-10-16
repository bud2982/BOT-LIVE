import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 ANALISI STRUTTURA RISPOSTA API\n');
  
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  // Test fixtures/list.json
  print('📋 STRUTTURA fixtures/list.json');
  print('=' * 60);
  
  try {
    final url = Uri.parse('$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret&page=1');
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Chiavi principali: ${data.keys.toList()}');
      
      if (data['data'] != null) {
        print('Chiavi in data: ${data['data'].keys.toList()}');
        
        if (data['data']['match'] != null) {
          final matches = data['data']['match'];
          if (matches is List && matches.isNotEmpty) {
            print('\nPrima partita completa:');
            print(json.encode(matches[0]));
          } else {
            print('match non è una lista o è vuota: ${matches.runtimeType}');
          }
        } else {
          print('match è null');
        }
      }
    }
  } catch (e) {
    print('❌ Errore: $e');
  }
  
  // Test matches/live.json
  print('\n\n🔴 STRUTTURA matches/live.json');
  print('=' * 60);
  
  try {
    final url = Uri.parse('$baseUrl/matches/live.json?key=$apiKey&secret=$apiSecret');
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Chiavi principali: ${data.keys.toList()}');
      
      if (data['data'] != null) {
        print('Tipo di data: ${data['data'].runtimeType}');
        
        if (data['data'] is Map) {
          print('Chiavi in data: ${data['data'].keys.toList()}');
          
          if (data['data']['match'] != null) {
            final matches = data['data']['match'];
            if (matches is List && matches.isNotEmpty) {
              print('\nPrima partita live completa:');
              print(json.encode(matches[0]));
            }
          }
        } else if (data['data'] is List) {
          final matches = data['data'] as List;
          if (matches.isNotEmpty) {
            print('\nPrima partita live completa:');
            print(json.encode(matches[0]));
          }
        }
      }
    }
  } catch (e) {
    print('❌ Errore: $e');
  }
}