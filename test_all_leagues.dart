import 'dart:io';
import 'lib/services/hybrid_football_service.dart';

void main() async {
  print('🔍 TEST: TUTTE LE LEGHE DISPONIBILI');
  print('=' * 80);
  
  final hybridService = HybridFootballService();
  
  try {
    final todayMatches = await hybridService.getFixturesToday();
    print('✅ Totale partite di oggi: ${todayMatches.length}');
    
    // Raggruppa per paese e lega
    final leaguesByCountry = <String, Set<String>>{};
    
    for (final match in todayMatches) {
      final country = match.country.isEmpty ? 'Unknown' : match.country;
      final league = match.league.isEmpty ? 'Unknown League' : match.league;
      
      leaguesByCountry[country] ??= <String>{};
      leaguesByCountry[country]!.add(league);
    }
    
    // Ordina i paesi
    final sortedCountries = leaguesByCountry.keys.toList()..sort();
    
    print('\n📊 LEGHE PER PAESE:');
    print('=' * 80);
    
    for (final country in sortedCountries) {
      final leagues = leaguesByCountry[country]!.toList()..sort();
      print('\n🏴 $country (${leagues.length} leghe):');
      
      for (final league in leagues) {
        final matchCount = todayMatches.where((m) => 
          m.country == country && m.league == league).length;
        print('   - $league ($matchCount partite)');
      }
    }
    
    // Cerca specificamente Olanda
    print('\n' + '=' * 80);
    print('🇳🇱 RICERCA SPECIFICA OLANDA:');
    
    final dutchCountries = sortedCountries.where((country) =>
      country.toLowerCase().contains('netherlands') ||
      country.toLowerCase().contains('holland') ||
      country.toLowerCase().contains('dutch')
    ).toList();
    
    if (dutchCountries.isNotEmpty) {
      print('✅ Paesi olandesi trovati:');
      for (final country in dutchCountries) {
        final leagues = leaguesByCountry[country]!.toList()..sort();
        print('   🏴 $country:');
        for (final league in leagues) {
          final matchCount = todayMatches.where((m) => 
            m.country == country && m.league == league).length;
          print('      - $league ($matchCount partite)');
          
          // Mostra alcune partite di esempio
          final exampleMatches = todayMatches.where((m) => 
            m.country == country && m.league == league).take(2);
          for (final match in exampleMatches) {
            print('        → ${match.home} vs ${match.away}');
          }
        }
      }
    } else {
      print('❌ Nessun paese olandese trovato');
      
      // Cerca leghe che potrebbero essere olandesi
      print('\n🔍 Ricerca leghe che potrebbero essere olandesi:');
      final possibleDutchLeagues = <String>[];
      
      for (final country in sortedCountries) {
        final leagues = leaguesByCountry[country]!;
        for (final league in leagues) {
          if (league.toLowerCase().contains('eredivisie') ||
              league.toLowerCase().contains('eerste') ||
              league.toLowerCase().contains('keuken') ||
              league.toLowerCase().contains('divisie')) {
            possibleDutchLeagues.add('$country - $league');
          }
        }
      }
      
      if (possibleDutchLeagues.isNotEmpty) {
        print('✅ Possibili leghe olandesi:');
        for (final league in possibleDutchLeagues) {
          print('   - $league');
        }
      } else {
        print('❌ Nessuna lega che sembra olandese');
      }
    }
    
  } catch (e) {
    print('❌ ERRORE: $e');
    exit(1);
  }
}