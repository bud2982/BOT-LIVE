import 'package:flutter/material.dart';
import 'package:live_bot/pages/country_matches_page.dart';

void main() {
  runApp(const TestCountryApp());
}

class TestCountryApp extends StatelessWidget {
  const TestCountryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Country Matches Page',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CountryMatchesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}