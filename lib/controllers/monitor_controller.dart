import 'dart:async';
import '../services/api_football_service.dart';
import '../services/local_notif_service.dart';

class MonitorController {
  final ApiFootballService api;
  final LocalNotifService notif;
  final Set<int> selected; // fixture IDs
  final Set<int> notified = {};
  Timer? _timer;

  MonitorController({
    required this.api,
    required this.notif,
    required this.selected,
  });

  void start() {
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void stop() => _timer?.cancel();

  Future<void> _tick() async {
    if (selected.isEmpty) return;
    try {
      final fixtures = await api.getLiveByIds(selected.toList());
      for (final f in fixtures) {
        final elapsed = f.elapsed ?? 0;
        final isZeroZero = f.goalsHome == 0 && f.goalsAway == 0;
        if (isZeroZero && elapsed >= 8 && !notified.contains(f.id)) {
          await notif.showAlert(
            id: f.id,
            title: '\\ - \\',
            body: 'Ancora 0-0 al minuto \\ ? Over 2.5',
          );
          notified.add(f.id);
        }
      }
    } catch (_) {
      // Silently ignore for MVP
    }
  }
}
