class Fixture {
  final int id;
  final String home;
  final String away;
  final DateTime start;
  final int? elapsed; // live minutes
  final int goalsHome;
  final int goalsAway;

  Fixture({
    required this.id,
    required this.home,
    required this.away,
    required this.start,
    this.elapsed,
    required this.goalsHome,
    required this.goalsAway,
  });

  factory Fixture.fromJson(Map<String, dynamic> j) {
    return Fixture(
      id: j['fixture']['id'] as int,
      home: j['teams']['home']['name'] as String,
      away: j['teams']['away']['name'] as String,
      start: DateTime.parse(j['fixture']['date'] as String),
      elapsed: j['fixture']['status']['elapsed'] as int?,
      goalsHome: (j['goals']['home'] ?? 0) as int,
      goalsAway: (j['goals']['away'] ?? 0) as int,
    );
  }
}
