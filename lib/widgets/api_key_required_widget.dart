import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApiKeyRequiredWidget extends StatelessWidget {
  final String error;
  
  const ApiKeyRequiredWidget({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazione Richiesta'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.key,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Chiave API LiveScore Richiesta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'L\'app utilizza ESCLUSIVAMENTE le API di LiveScore per fornire dati reali e aggiornati.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Errore:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Passi per configurare:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep(
              '1',
              'Vai su live-score-api.com',
              'Registrati gratuitamente',
              Icons.web,
            ),
            const SizedBox(height: 12),
            _buildStep(
              '2',
              'Ottieni la tua API Key',
              'Dal dashboard copia la chiave',
              Icons.vpn_key,
            ),
            const SizedBox(height: 12),
            _buildStep(
              '3',
              'Configura nel codice',
              'lib/services/livescore_api_service.dart',
              Icons.code,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _copyPath(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copia percorso file'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInstructions(context),
                    icon: const Icon(Icons.help),
                    label: const Text('Istruzioni complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova dopo configurazione'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep(String number, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            radius: 16,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _copyPath(BuildContext context) {
    const path = 'lib/services/livescore_api_service.dart';
    Clipboard.setData(const ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percorso file copiato negli appunti'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _openInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Istruzioni Dettagliate'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Vai su https://live-score-api.com\n\n'
            '2. Clicca "Sign Up" e registrati\n\n'
            '3. Conferma la tua email\n\n'
            '4. Accedi al dashboard\n\n'
            '5. Copia la tua API Key\n\n'
            '6. Apri lib/services/livescore_api_service.dart\n\n'
            '7. Trova la riga:\n'
            'static const String _apiKey = \'YOUR_LIVESCORE_API_KEY_HERE\';\n\n'
            '8. Sostituisci YOUR_LIVESCORE_API_KEY_HERE con la tua chiave\n\n'
            '9. Salva il file e riavvia l\'app',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}