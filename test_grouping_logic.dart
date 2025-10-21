class TestFixture {
  final int id;
  final String home;
  final String away;
  final String league;
  final String country;
  
  TestFixture({
    required this.id,
    required this.home,
    required this.away,
    required this.league,
    required this.country,
  });
}

String getCountryFromLeague(String league) {
  final leagueLower = league.toLowerCase();
  
  // Leghe italiane
  if (leagueLower.contains('serie a') || 
      leagueLower.contains('serie b') || 
      leagueLower.contains('serie c') ||
      leagueLower.contains('coppa italia') ||
      leagueLower.contains('supercoppa italiana')) {
    return 'Italy';
  }
  
  // Leghe inglesi
  if (leagueLower.contains('premier league') || 
      leagueLower.contains('championship') ||
      leagueLower.contains('league one') ||
      leagueLower.contains('league two') ||
      leagueLower.contains('fa cup') ||
      leagueLower.contains('carabao cup') ||
      leagueLower.contains('community shield')) {
    return 'England';
  }
  
  // Leghe spagnole
  if (leagueLower.contains('la liga') || 
      leagueLower.contains('segunda division') ||
      leagueLower.contains('copa del rey') ||
      leagueLower.contains('supercopa de españa')) {
    return 'Spain';
  }
  
  // Leghe tedesche
  if (leagueLower.contains('bundesliga') || 
      leagueLower.contains('2. bundesliga') ||
      leagueLower.contains('dfb-pokal') ||
      leagueLower.contains('dfl-supercup')) {
    return 'Germany';
  }
  
  // Leghe francesi
  if (leagueLower.contains('ligue 1') || 
      leagueLower.contains('ligue 2') ||
      leagueLower.contains('coupe de france') ||
      leagueLower.contains('trophée des champions')) {
    return 'France';
  }
  
  return 'Other';
}

void main() {
  print('🧪 TEST LOGICA RAGGRUPPAMENTO PAESI');
  print('=====================================');
  
  // Dati di test che simulano quelli del server proxy
  final testFixtures = [
    TestFixture(id: 1, home: 'Juventus', away: 'Milan', league: 'Serie A', country: 'Italy'),
    TestFixture(id: 2, home: 'Barcelona', away: 'Real Madrid', league: 'La Liga', country: 'Spain'),
    TestFixture(id: 3, home: 'Manchester United', away: 'Liverpool', league: 'Premier League', country: 'England'),
    TestFixture(id: 4, home: 'Bayern Munich', away: 'Borussia Dortmund', league: 'Bundesliga', country: 'Germany'),
    TestFixture(id: 5, home: 'PSG', away: 'Marseille', league: 'Ligue 1', country: 'France'),
    TestFixture(id: 6, home: 'Team A', away: 'Team B', league: 'Unknown League', country: 'Other'),
    TestFixture(id: 7, home: 'Team C', away: 'Team D', league: 'Another Serie A', country: 'Other'), // Questo dovrebbe essere dedotto come Italy
  ];
  
  print('🌍 INIZIO RAGGRUPPAMENTO: ${testFixtures.length} partite da raggruppare');
  
  final Map<String, List<TestFixture>> groupedFixtures = {};
  
  for (final fixture in testFixtures) {
    String country = fixture.country;
    print('   🏟️ Partita: ${fixture.home} vs ${fixture.away}');
    print('      Paese originale: "$country"');
    print('      League: "${fixture.league}"');
    
    // Se il paese è vuoto, sconosciuto o generico, prova a dedurlo dalla lega
    if (country.isEmpty || 
        country == 'Paese Sconosciuto' || 
        country == 'Other' || 
        country == 'Unknown' ||
        country == 'N/A') {
      final deducedCountry = getCountryFromLeague(fixture.league);
      print('      Paese dedotto dalla league: "$deducedCountry"');
      country = deducedCountry;
    }
    
    // Se ancora non abbiamo un paese valido, usa 'Internazionale'
    if (country.isEmpty || 
        country == 'Paese Sconosciuto' || 
        country == 'Other' || 
        country == 'Unknown' ||
        country == 'N/A') {
      country = 'Internazionale';
    }
    
    print('      Paese finale: "$country"');
    groupedFixtures.putIfAbsent(country, () => []).add(fixture);
    print('      ---');
  }
  
  // Ordina i paesi alfabeticamente, ma metti 'Internazionale' alla fine
  final sortedCountries = groupedFixtures.keys.toList()..sort((a, b) {
    if (a == 'Internazionale') return 1;
    if (b == 'Internazionale') return -1;
    return a.compareTo(b);
  });
  
  print('🌍 RAGGRUPPAMENTO COMPLETATO: ${sortedCountries.length} paesi trovati: $sortedCountries');
  print('');
  
  // Mostra il risultato del raggruppamento
  for (final country in sortedCountries) {
    final matches = groupedFixtures[country]!;
    print('🏴 $country (${matches.length} partite):');
    for (final match in matches) {
      print('   • ${match.home} vs ${match.away} [${match.league}]');
    }
    print('');
  }
  
  print('✅ Test completato! Il raggruppamento dovrebbe funzionare nell\'app Flutter.');
}