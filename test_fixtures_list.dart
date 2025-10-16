import 'dart:convert';
import 'package:http/http.dart' as http;

// Test per verificare la qualità dei dati dall'endpoint fixtures/list.json
void main() async {
  const apiKey = 'wUOF0E1DmdetayWk';
  const apiSecret = 'Vng53xQ0F9Knz416YPLZuNCR1Rkbqhvl';
  const baseUrl = 'https://livescore-api.com/api-client';
  
  print('🔍 TEST FIXTURES/LIST.JSON - Verifica qualità dati paese\n');
  print('=' * 80);
  
  try {
    final url = Uri.parse('$baseUrl/fixtures/list.json?key=$apiKey&secret=$apiSecret');
    
    print('📡 Richiesta a: fixtures/list.json');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('✅ Status: ${response.statusCode}\n');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        final dataSection = data['data'];
        List<dynamic> matches = [];
        
        if (dataSection['fixtures'] is List) {
          matches = dataSection['fixtures'] as List;
        } else if (dataSection['fixture'] is List) {
          matches = dataSection['fixture'] as List;
        } else if (dataSection is List) {
          matches = dataSection as List;
        }
        
        print('📊 Totale partite: ${matches.length}\n');
        print('=' * 80);
        
        // Analizza i primi 10 match per vedere la struttura dati
        int withCountry = 0;
        int withoutCountry = 0;
        Map<String, int> countryCounts = {};
        
        for (int i = 0; i < matches.length && i < 10; i++) {
          final match = matches[i];
          print('\n🏆 PARTITA ${i + 1}:');
          print('   Chiavi disponibili: ${(match as Map).keys.toList()}');
          
          // Squadre
          String home = 'N/A';
          String away = 'N/A';
          
          if (match['home'] != null) {
            if (match['home'] is Map && match['home']['name'] != null) {
              home = match['home']['name'];
            } else if (match['home'] is String) {
              home = match['home'];
            }
          } else if (match['home_name'] != null) {
            home = match['home_name'];
          }
          
          if (match['away'] != null) {
            if (match['away'] is Map && match['away']['name'] != null) {
              away = match['away']['name'];
            } else if (match['away'] is String) {
              away = match['away'];
            }
          } else if (match['away_name'] != null) {
            away = match['away_name'];
          }
          
          print('   Squadre: $home vs $away');
          
          // Lega
          String league = 'N/A';
          if (match['league'] != null) {
            if (match['league'] is Map && match['league']['name'] != null) {
              league = match['league']['name'];
            } else if (match['league'] is String) {
              league = match['league'];
            }
          } else if (match['competition'] != null) {
            if (match['competition'] is Map && match['competition']['name'] != null) {
              league = match['competition']['name'];
            } else if (match['competition'] is String) {
              league = match['competition'];
            }
          }
          print('   Lega: $league');
          
          // Paese - controlla tutti i possibili formati
          String? country;
          String countrySource = '';
          
          if (match['country'] != null) {
            if (match['country'] is Map && match['country']['name'] != null) {
              country = match['country']['name'];
              countrySource = 'country.name';
            } else if (match['country'] is String) {
              country = match['country'];
              countrySource = 'country';
            }
          }
          
          if (country == null && match['location'] != null && match['location'] is Map) {
            if (match['location']['country'] != null) {
              if (match['location']['country'] is Map && match['location']['country']['name'] != null) {
                country = match['location']['country']['name'];
                countrySource = 'location.country.name';
              } else if (match['location']['country'] is String) {
                country = match['location']['country'];
                countrySource = 'location.country';
              }
            }
          }
          
          if (country == null && match['federation'] != null) {
            if (match['federation'] is Map && match['federation']['name'] != null) {
              country = match['federation']['name'];
              countrySource = 'federation.name';
            } else if (match['federation'] is String) {
              country = match['federation'];
              countrySource = 'federation';
            }
          }
          
          if (country != null && country.isNotEmpty) {
            print('   ✅ Paese: $country (da: $countrySource)');
            withCountry++;
            countryCounts[country] = (countryCounts[country] ?? 0) + 1;
          } else {
            print('   ❌ Paese: NON DISPONIBILE');
            withoutCountry++;
          }
          
          // Ora
          String? time;
          if (match['time'] != null) {
            time = match['time'];
          } else if (match['added'] != null) {
            time = match['added'];
          }
          if (time != null) {
            print('   Ora: $time');
          }
          
          // Competition ID
          if (match['competition_id'] != null) {
            print('   Competition ID: ${match['competition_id']}');
          } else if (match['competition'] != null && match['competition'] is Map && match['competition']['id'] != null) {
            print('   Competition ID: ${match['competition']['id']}');
          }
        }
        
        // Analizza TUTTE le partite per statistiche complete
        print('\n' + '=' * 80);
        print('📊 ANALISI COMPLETA DI TUTTE LE ${matches.length} PARTITE:\n');
        
        withCountry = 0;
        withoutCountry = 0;
        countryCounts.clear();
        
        for (final match in matches) {
          String? country;
          
          if (match['country'] != null) {
            if (match['country'] is Map && match['country']['name'] != null) {
              country = match['country']['name'];
            } else if (match['country'] is String) {
              country = match['country'];
            }
          }
          
          if (country == null && match['location'] != null && match['location'] is Map) {
            if (match['location']['country'] != null) {
              if (match['location']['country'] is Map && match['location']['country']['name'] != null) {
                country = match['location']['country']['name'];
              } else if (match['location']['country'] is String) {
                country = match['location']['country'];
              }
            }
          }
          
          if (country == null && match['federation'] != null) {
            if (match['federation'] is Map && match['federation']['name'] != null) {
              country = match['federation']['name'];
            } else if (match['federation'] is String) {
              country = match['federation'];
            }
          }
          
          if (country != null && country.isNotEmpty) {
            withCountry++;
            countryCounts[country] = (countryCounts[country] ?? 0) + 1;
          } else {
            withoutCountry++;
          }
        }
        
        print('✅ Partite CON paese: $withCountry (${(withCountry / matches.length * 100).toStringAsFixed(1)}%)');
        print('❌ Partite SENZA paese: $withoutCountry (${(withoutCountry / matches.length * 100).toStringAsFixed(1)}%)');
        
        print('\n🌍 DISTRIBUZIONE PER PAESE:');
        final sortedCountries = countryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (final entry in sortedCountries) {
          print('   ${entry.key}: ${entry.value} partite');
        }
        
        print('\n' + '=' * 80);
        print('💡 CONCLUSIONE:');
        if (withCountry > matches.length * 0.8) {
          print('   ✅ Questo endpoint fornisce dati paese di BUONA qualità!');
          print('   ✅ Usalo nell\'app per migliorare la classificazione delle partite.');
        } else if (withCountry > matches.length * 0.5) {
          print('   ⚠️  Questo endpoint fornisce dati paese PARZIALI.');
          print('   ⚠️  Sarà necessario dedurre il paese dalla lega per alcune partite.');
        } else {
          print('   ❌ Questo endpoint NON fornisce dati paese sufficienti.');
          print('   ❌ Sarà necessario dedurre il paese dalla lega per la maggior parte delle partite.');
        }
        
      } else {
        print('❌ Formato risposta non riconosciuto');
      }
    } else {
      print('❌ Errore ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Errore: $e');
  }
}