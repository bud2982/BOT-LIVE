import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyCtrl = TextEditingController();
  int _interval = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKeyCtrl.text = prefs.getString('api_key') ?? '';
    _interval = prefs.getInt('interval_min') ?? 1;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _apiKeyCtrl.text.trim());
    await prefs.setInt('interval_min', _interval);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _apiKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'RapidAPI Key (API-Football)',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Inserisci la tua API Key'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Intervallo (min): '),
                  DropdownButton<int>(
                    value: _interval,
                    items: const [1, 2, 3, 5]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text('\\'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _interval = v);
                    },
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salva'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
