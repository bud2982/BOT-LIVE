// Script per verificare lo stato dell'app e del server
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🔍 VERIFICA STATO SISTEMA');
  print('========================');
  
  // 1. Verifica server proxy
  print('1️⃣ Verifica server proxy...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3001/api/test'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('   ✅ Server proxy: ATTIVO');
    } else {
      print('   ❌ Server proxy: ERRORE ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('   ❌ Server proxy: NON RAGGIUNGIBILE ($e)');
  }
  
  // 2. Verifica dati di test
  print('2️⃣ Verifica dati di test...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3001/api/livescore'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      
      if (data['success'] == true && data['matches'] != null) {
        final matches = data['matches'] as List;
        print('   ✅ Dati di test: ${matches.length} partite disponibili');
        
        // Conta i paesi
        final countries = <String>{};
        for (final match in matches) {
          final country = match['country'] ?? 'Other';
          countries.add(country);
        }
        print('   📊 Paesi nei dati: ${countries.join(", ")}');
      } else {
        print('   ❌ Dati di test: FORMATO NON VALIDO');
      }
    } else {
      print('   ❌ Dati di test: ERRORE ${response.statusCode}');
    }
    client.close();
  } catch (e) {
    print('   ❌ Dati di test: ERRORE ($e)');
  }
  
  // 3. Verifica processi Flutter
  print('3️⃣ Verifica processi Flutter...');
  try {
    final result = await Process.run('powershell', [
      '-Command', 
      'Get-Process | Where-Object {\$_.ProcessName -like "*dart*"} | Measure-Object | Select-Object -ExpandProperty Count'
    ]);
    
    if (result.exitCode == 0) {
      final count = int.tryParse(result.stdout.toString().trim()) ?? 0;
      if (count > 0) {
        print('   ✅ Flutter: $count processi Dart attivi');
      } else {
        print('   ❌ Flutter: Nessun processo attivo');
      }
    }
  } catch (e) {
    print('   ⚠️ Flutter: Impossibile verificare processi');
  }
  
  print('');
  print('🎯 ISTRUZIONI PER IL TEST:');
  print('==========================');
  print('1. Apri Chrome e vai su http://localhost:XXXX (porta mostrata da Flutter)');
  print('2. Nell\'app, vai alla schermata principale (Home)');
  print('3. Dovresti vedere le partite raggruppate per paese:');
  print('   • England (1 partita)');
  print('   • France (1 partita)');
  print('   • Germany (1 partita)');
  print('   • Italy (2 partite)');
  print('   • Spain (1 partita)');
  print('   • Internazionale (1 partita)');
  print('4. Ogni sezione dovrebbe essere espandibile (ExpansionTile)');
  print('');
  print('Se vedi una lista semplice invece del raggruppamento,');
  print('controlla la console del browser per eventuali errori.');
}