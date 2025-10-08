import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_service.dart';

class TelegramConfigPage extends StatefulWidget {
  const TelegramConfigPage({super.key});

  @override
  State<TelegramConfigPage> createState() => _TelegramConfigPageState();
}

class _TelegramConfigPageState extends State<TelegramConfigPage> {
  final TextEditingController _chatIdController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  final TelegramService _telegramService = TelegramService();
  bool _isLoading = false;
  String? _savedChatId;
  String? _savedBotToken;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedChatId = prefs.getString('telegram_chat_id');
      _savedBotToken = prefs.getString('telegram_bot_token');
      
      if (_savedChatId != null) {
        _chatIdController.text = _savedChatId!;
      }
      if (_savedBotToken != null) {
        _botTokenController.text = _savedBotToken!;
      }
    });
  }

  Future<void> _saveConfig() async {
    if (_chatIdController.text.trim().isEmpty) {
      _showError('Inserisci il tuo Chat ID Telegram');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('telegram_chat_id', _chatIdController.text.trim());
      
      if (_botTokenController.text.trim().isNotEmpty) {
        await prefs.setString('telegram_bot_token', _botTokenController.text.trim());
      }

      setState(() {
        _savedChatId = _chatIdController.text.trim();
        _savedBotToken = _botTokenController.text.trim();
      });

      _showSuccess('Configurazione salvata con successo!');
    } catch (e) {
      _showError('Errore nel salvataggio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    if (_savedChatId == null || _savedChatId!.isEmpty) {
      _showError('Prima salva la configurazione');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _telegramService.sendNotification(
        chatId: _savedChatId!,
        message: '''
🤖 TEST NOTIFICA

Ciao! Questo è un messaggio di test dal tuo Bot Football Live.

✅ La configurazione funziona correttamente!
⚽ Ora riceverai notifiche per le partite che selezioni.

Buon divertimento! 🎉
        ''',
      );

      if (success) {
        _showSuccess('Notifica di test inviata! Controlla Telegram.');
      } else {
        _showError('Errore nell\'invio della notifica di test');
      }
    } catch (e) {
      _showError('Errore nel test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazione Telegram'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Istruzioni
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Come configurare Telegram',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Apri Telegram e cerca @BotFather\n'
                      '2. Crea un nuovo bot con /newbot\n'
                      '3. Copia il token del bot (opzionale)\n'
                      '4. Cerca @userinfobot per ottenere il tuo Chat ID\n'
                      '5. Inserisci il Chat ID qui sotto',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Chat ID
            TextField(
              controller: _chatIdController,
              decoration: InputDecoration(
                labelText: 'Chat ID Telegram *',
                hintText: 'Es: 123456789',
                prefixIcon: const Icon(Icons.chat),
                border: const OutlineInputBorder(),
                helperText: 'Il tuo ID utente Telegram (obbligatorio)',
                suffixIcon: _savedChatId != null 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Bot Token (opzionale)
            TextField(
              controller: _botTokenController,
              decoration: InputDecoration(
                labelText: 'Bot Token (opzionale)',
                hintText: 'Es: 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                helperText: 'Token del tuo bot personalizzato (opzionale)',
                suffixIcon: _savedBotToken != null 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              ),
              obscureText: true,
            ),
            
            const SizedBox(height: 24),
            
            // Pulsanti
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveConfig,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                    label: const Text('Salva Configurazione'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Test
            if (_savedChatId != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testNotification,
                      icon: const Icon(Icons.send),
                      label: const Text('Invia Notifica di Test'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 32),
            
            // Stato attuale
            Card(
              color: _savedChatId != null ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _savedChatId != null ? Icons.check_circle : Icons.warning,
                          color: _savedChatId != null ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stato Configurazione',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _savedChatId != null ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _savedChatId != null 
                        ? '✅ Configurazione completata\n✅ Chat ID: $_savedChatId\n${_savedBotToken != null ? '✅ Bot personalizzato configurato' : '⚠️ Usando bot predefinito'}'
                        : '⚠️ Configurazione incompleta\n❌ Chat ID mancante',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Note aggiuntive
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Suggerimenti',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Il Chat ID è un numero che identifica il tuo account Telegram\n'
                      '• Puoi ottenere il tuo Chat ID scrivendo a @userinfobot\n'
                      '• Il Bot Token è opzionale - se non lo inserisci, useremo il bot predefinito\n'
                      '• Testa sempre la configurazione prima di usarla\n'
                      '• Le notifiche arriveranno in tempo reale durante le partite',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatIdController.dispose();
    _botTokenController.dispose();
    super.dispose();
  }
}