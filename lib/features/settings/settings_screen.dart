import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = ChangeNotifierProvider((ref) => SettingsNotifier());

class SettingsNotifier extends ChangeNotifier {
  int _trackLimit = 200;
  String _quality = 'Normal';

  int get trackLimit => _trackLimit;
  String get quality => _quality;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _trackLimit = prefs.getInt('track_limit') ?? 200;
    _quality = prefs.getString('quality') ?? 'Normal';
    notifyListeners();
  }

  Future<void> setTrackLimit(int limit) async {
    _trackLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('track_limit', limit);
    notifyListeners();
  }

  Future<void> setQuality(String quality) async {
    _quality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality', quality);
    notifyListeners();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Limite de Faixas Offline'),
            subtitle: Text('${settings.trackLimit} músicas'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final newLimit = await _showLimitDialog(context, settings.trackLimit);
              if (newLimit != null) {
                ref.read(settingsProvider).setTrackLimit(newLimit);
              }
            },
          ),
          ListTile(
            title: const Text('Qualidade do Áudio'),
            subtitle: Text(settings.quality),
            trailing: const Icon(Icons.high_quality),
            onTap: () async {
              final newQuality = await _showQualityDialog(context, settings.quality);
              if (newQuality != null) {
                ref.read(settingsProvider).setQuality(newQuality);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<int?> _showLimitDialog(BuildContext context, int current) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        int val = current;
        return AlertDialog(
          title: const Text('Definir limite de faixas'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Ex: 500'),
            onChanged: (v) => val = int.tryParse(v) ?? current,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, val), child: const Text('Salvar')),
          ],
        );
      },
    );
  }

  Future<String?> _showQualityDialog(BuildContext context, String current) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Qualidade do áudio'),
          children: ['Baixa', 'Normal', 'Alta', 'Original'].map((q) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, q),
              child: Text(q),
            );
          }).toList(),
        );
      },
    );
  }
}
