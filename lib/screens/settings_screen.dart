import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  int _interval = 1;
  bool _useSampleData = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _interval = prefs.getInt('interval_min') ?? 1;
      _useSampleData = prefs.getBool('use_sample_data') ?? false;
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Errore durante il caricamento delle impostazioni: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('interval_min', _interval);
      await prefs.setBool('use_sample_data', _useSampleData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impostazioni salvate'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Errore durante il salvataggio delle impostazioni: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  

  
  void _resetToDefault() {
    setState(() {
      _interval = 1;
      _useSampleData = false; // Forziamo a false per usare dati reali
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefault,
            tooltip: 'Ripristina valori predefiniti',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informazioni su LiveScore
                    const Text(
                      'Fonte dati',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dati forniti da LiveScore',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'L\'app utilizza LiveScore come unica fonte di dati per le partite di calcio in tempo reale.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Intervallo di monitoraggio
                    const Text(
                      'Intervallo di monitoraggio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Intervallo (minuti): '),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _interval,
                          items: const [1, 2, 3, 5, 10]
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _interval = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Intervallo tra i controlli delle partite in corso. Un intervallo più breve fornisce aggiornamenti più frequenti ma consuma più batteria e dati.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Notifiche Telegram
                    const Text(
                      'Notifiche Telegram',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ricevi notifiche su Telegram',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Configura il tuo Chat ID Telegram per ricevere notifiche in tempo reale sulle partite.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/telegram_config');
                              },
                              icon: const Icon(Icons.telegram),
                              label: const Text('Configura Telegram'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Modalità dati
                    const Text(
                      'Modalità dati',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Usa dati di esempio: '),
                        Switch(
                          value: _useSampleData,
                          onChanged: (value) {
                            setState(() {
                              _useSampleData = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _useSampleData ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _useSampleData ? Colors.orange.shade200 : Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _useSampleData 
                                ? 'Modalità dati di esempio attiva'
                                : 'Modalità dati reali attiva',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _useSampleData
                                ? 'L\'app utilizza dati di esempio per mostrare le partite.'
                                : 'L\'app tenta di recuperare partite reali da LiveScore.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Pulsante salva
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Salva impostazioni'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
