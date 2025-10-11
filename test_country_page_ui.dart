import 'package:flutter/material.dart';
import 'lib/pages/country_matches_page.dart';

void main() {
  runApp(TestCountryPageApp());
}

class TestCountryPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Country Matches Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test Country Matches'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: CountryMatchesPage(),
      ),
      routes: {
        '/followed_matches': (context) => Scaffold(
          appBar: AppBar(title: Text('Partite Seguite')),
          body: Center(child: Text('Pagina Partite Seguite')),
        ),
        '/telegram_config': (context) => Scaffold(
          appBar: AppBar(title: Text('Config Telegram')),
          body: Center(child: Text('Pagina Config Telegram')),
        ),
        '/live_results': (context) => Scaffold(
          appBar: AppBar(title: Text('Risultati Live')),
          body: Center(child: Text('Pagina Risultati Live')),
        ),
        '/favorite_matches': (context) => Scaffold(
          appBar: AppBar(title: Text('Partite Preferite')),
          body: Center(child: Text('Pagina Partite Preferite')),
        ),
      },
    );
  }
}