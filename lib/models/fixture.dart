class Fixture {
  final int id;
  final String home;
  final String away;
  final DateTime start;
  final int? elapsed; // live minutes
  final int goalsHome;
  final int goalsAway;
  final String league; // nome della lega
  final String country; // nazione

  Fixture({
    required this.id,
    required this.home,
    required this.away,
    required this.start,
    this.elapsed,
    required this.goalsHome,
    required this.goalsAway,
    this.league = 'Unknown League',
    this.country = 'Other',
  });

  factory Fixture.fromJson(Map<String, dynamic> j) {
    try {
      // Controlla se è il formato semplificato del proxy server LiveScore
      if (j.containsKey('home') && j.containsKey('away') && !j.containsKey('fixture')) {
        return _fromLiveScoreFormat(j);
      }
      
      // Formato API-Football originale
      return _fromApiFootballFormat(j);
    } catch (e) {
      print('Errore durante il parsing di Fixture: $e');
      print('JSON problematico: $j');
      
      // Crea un oggetto Fixture con valori predefiniti in caso di errore
      return Fixture(
        id: _extractId(j) ?? 0,
        home: _extractString(j, ['teams', 'home', 'name']) ?? 
              j['home'] as String? ?? 'Squadra Casa',
        away: _extractString(j, ['teams', 'away', 'name']) ?? 
              j['away'] as String? ?? 'Squadra Ospite',
        start: DateTime.now(),
        elapsed: 0,
        goalsHome: 0,
        goalsAway: 0,
        league: j['league'] as String? ?? 'Unknown League',
        country: j['country'] as String? ?? 'Other',
      );
    }
  }

  // Parsing per formato LiveScore semplificato
  static Fixture _fromLiveScoreFormat(Map<String, dynamic> j) {
    // Estrai l'ID
    int id;
    try {
      final rawId = j['id'];
      if (rawId is int) {
        id = rawId;
      } else if (rawId is String) {
        id = int.tryParse(rawId) ?? 0;
      } else {
        id = 0;
      }
    } catch (_) {
      id = 0;
    }

    // Estrai i nomi delle squadre (già nel formato corretto)
    final home = j['home'] as String? ?? 'Squadra Casa';
    final away = j['away'] as String? ?? 'Squadra Ospite';

    // Estrai la data di inizio
    DateTime start;
    try {
      final dateStr = j['start'] as String?;
      print('🔍 DEBUG Fixture - Parsing start time for $home vs $away');
      print('🔍 DEBUG Fixture - Raw start string: "$dateStr"');
      
      if (dateStr != null && dateStr.isNotEmpty) {
        // Gestisci formati di data problematici
        String cleanDateStr = dateStr;
        if (dateStr.contains('45+:00Z')) {
          cleanDateStr = dateStr.replaceAll('45+:00Z', '15:00:00Z');
        } else if (dateStr.contains('FT:00Z')) {
          cleanDateStr = dateStr.replaceAll('FT:00Z', '15:00:00Z');
        }
        // Parse direttamente - LiveScore fornisce già orari nel formato corretto
        final parsedDateTime = DateTime.parse(cleanDateStr);
        start = parsedDateTime;
        print('🔍 DEBUG Fixture - Raw start string: "$dateStr"');
        print('🔍 DEBUG Fixture - Parsed DateTime: $parsedDateTime');
        print('🔍 DEBUG Fixture - Hour: ${start.hour}, Minute: ${start.minute}');
      } else {
        print('🔍 DEBUG Fixture - Empty start string, using DateTime.now()');
        start = DateTime.now();
      }
    } catch (e) {
      print('🔍 DEBUG Fixture - Error parsing start time: $e');
      start = DateTime.now();
    }

    // Estrai i minuti trascorsi
    int? elapsed;
    try {
      final rawElapsed = j['elapsed'];
      if (rawElapsed is int) {
        elapsed = rawElapsed;
      } else if (rawElapsed is String) {
        elapsed = int.tryParse(rawElapsed);
      } else {
        elapsed = null;
      }
    } catch (_) {
      elapsed = null;
    }

    // Estrai i gol
    int goalsHome;
    try {
      final rawGoalsHome = j['goalsHome'];
      if (rawGoalsHome is int) {
        goalsHome = rawGoalsHome;
      } else if (rawGoalsHome is String) {
        goalsHome = int.tryParse(rawGoalsHome) ?? 0;
      } else {
        goalsHome = 0;
      }
    } catch (_) {
      goalsHome = 0;
    }

    int goalsAway;
    try {
      final rawGoalsAway = j['goalsAway'];
      if (rawGoalsAway is int) {
        goalsAway = rawGoalsAway;
      } else if (rawGoalsAway is String) {
        goalsAway = int.tryParse(rawGoalsAway) ?? 0;
      } else {
        goalsAway = 0;
      }
    } catch (_) {
      goalsAway = 0;
    }

    // Estrai lega e paese
    final league = j['league'] as String? ?? 'Unknown League';
    final country = j['country'] as String? ?? 'Other';

    return Fixture(
      id: id,
      home: home,
      away: away,
      start: start,
      elapsed: elapsed,
      goalsHome: goalsHome,
      goalsAway: goalsAway,
      league: league,
      country: country,
    );
  }

  // Parsing per formato API-Football originale
  static Fixture _fromApiFootballFormat(Map<String, dynamic> j) {
    // Estrai i valori con controlli di sicurezza
    final fixtureData = j['fixture'] as Map<String, dynamic>? ?? {};
    final teamsData = j['teams'] as Map<String, dynamic>? ?? {};
    final goalsData = j['goals'] as Map<String, dynamic>? ?? {};
    final statusData = fixtureData['status'] as Map<String, dynamic>? ?? {};
    final leagueData = j['league'] as Map<String, dynamic>? ?? {};
    
    // Estrai l'ID con controllo di tipo
    int id;
    try {
      final rawId = fixtureData['id'];
      if (rawId is int) {
        id = rawId;
      } else if (rawId is String) {
        id = int.tryParse(rawId) ?? 0;
      } else {
        id = 0;
      }
    } catch (_) {
      id = 0;
    }
    
    // Estrai i nomi delle squadre
    final homeTeamData = teamsData['home'] as Map<String, dynamic>? ?? {};
    final awayTeamData = teamsData['away'] as Map<String, dynamic>? ?? {};
    
    final home = homeTeamData['name'] as String? ?? 'Squadra Casa';
    final away = awayTeamData['name'] as String? ?? 'Squadra Ospite';
    
    // Estrai la data di inizio
    DateTime start;
    try {
      final dateStr = fixtureData['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        start = DateTime.parse(dateStr);
      } else {
        start = DateTime.now();
      }
    } catch (_) {
      start = DateTime.now();
    }
    
    // Estrai i minuti trascorsi
    int? elapsed;
    try {
      final rawElapsed = statusData['elapsed'];
      if (rawElapsed is int) {
        elapsed = rawElapsed;
      } else if (rawElapsed is String) {
        elapsed = int.tryParse(rawElapsed);
      } else {
        elapsed = null;
      }
    } catch (_) {
      elapsed = null;
    }
    
    // Estrai i gol
    int goalsHome;
    try {
      final rawGoalsHome = goalsData['home'];
      if (rawGoalsHome is int) {
        goalsHome = rawGoalsHome;
      } else if (rawGoalsHome is String) {
        goalsHome = int.tryParse(rawGoalsHome) ?? 0;
      } else {
        goalsHome = 0;
      }
    } catch (_) {
      goalsHome = 0;
    }
    
    int goalsAway;
    try {
      final rawGoalsAway = goalsData['away'];
      if (rawGoalsAway is int) {
        goalsAway = rawGoalsAway;
      } else if (rawGoalsAway is String) {
        goalsAway = int.tryParse(rawGoalsAway) ?? 0;
      } else {
        goalsAway = 0;
      }
    } catch (_) {
      goalsAway = 0;
    }

    // Estrai lega e paese
    final league = leagueData['name'] as String? ?? 'Unknown League';
    final country = leagueData['country'] as String? ?? 'Other';
    
    return Fixture(
      id: id,
      home: home,
      away: away,
      start: start,
      elapsed: elapsed,
      goalsHome: goalsHome,
      goalsAway: goalsAway,
      league: league,
      country: country,
    );
  }
  
  // Metodi di utilità per estrarre valori in modo sicuro
  static int? _extractId(Map<String, dynamic> json) {
    try {
      if (json.containsKey('fixture') && json['fixture'] is Map) {
        final fixture = json['fixture'] as Map<String, dynamic>;
        if (fixture.containsKey('id')) {
          final id = fixture['id'];
          if (id is int) return id;
          if (id is String) return int.tryParse(id);
        }
      } else if (json.containsKey('id')) {
        final id = json['id'];
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
      }
    } catch (_) {}
    return null;
  }
  
  static String? _extractString(Map<String, dynamic> json, List<String> path) {
    try {
      dynamic current = json;
      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }
      if (current is String) return current;
    } catch (_) {}
    return null;
  }
  
  @override
  String toString() {
    return 'Fixture(id: $id, $home vs $away, elapsed: $elapsed, score: $goalsHome-$goalsAway, league: $league, country: $country)';
  }
  
  // Metodo copyWith per creare una copia con valori modificati
  Fixture copyWith({
    int? id,
    String? home,
    String? away,
    DateTime? start,
    int? elapsed,
    int? goalsHome,
    int? goalsAway,
    String? league,
    String? country,
  }) {
    return Fixture(
      id: id ?? this.id,
      home: home ?? this.home,
      away: away ?? this.away,
      start: start ?? this.start,
      elapsed: elapsed ?? this.elapsed,
      goalsHome: goalsHome ?? this.goalsHome,
      goalsAway: goalsAway ?? this.goalsAway,
      league: league ?? this.league,
      country: country ?? this.country,
    );
  }
}
