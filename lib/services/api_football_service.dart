import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fixture.dart';

class ApiFootballService {
  final String apiKey;
  ApiFootballService(this.apiKey);

  Map<String, String> get _headers => {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'api-football-v1.p.rapidapi.com',
      };

  Future<List<Fixture>> getFixturesToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final url = Uri.parse(
        'https://api-football-v1.p.rapidapi.com/v3/fixtures?date=');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('API error: \\ \\');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    return list.map((e) => Fixture.fromJson(e)).toList();
  }

  Future<List<Fixture>> getLiveByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final url = Uri.parse(
        'https://api-football-v1.p.rapidapi.com/v3/fixtures?ids=\\');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('API error: \\ \\');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['response'] as List).cast<Map<String, dynamic>>();
    return list.map((e) => Fixture.fromJson(e)).toList();
  }
}
