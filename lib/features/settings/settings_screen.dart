import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provedor para o estado das configurações, utilizando [ChangeNotifierProvider].
final settingsProvider = ChangeNotifierProvider((ref) => SettingsNotifier());

/// Gerenciador de estado para as configurações do aplicativo.
/// Lida com o carregamento e salvamento de preferências no armazenamento local.
class SettingsNotifier extends ChangeNotifier {
  int _trackLimit = 200; // Limite padrão de músicas offline
  String _quality = 'Normal'; // Qualidade padrão de áudio

  int get trackLimit => _trackLimit;
  String get quality => _quality;

  SettingsNotifier() {
    _loadSettings();
  }

  /// Carrega as configurações salvas anteriormente via SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _trackLimit = prefs.getInt('track_limit') ?? 200;
    _quality = prefs.getString('quality') ?? 'Normal';
    notifyListeners(); // Notifica a UI para reconstruir com os valores carregados
  }

  /// Define um novo limite máximo de músicas para download e persiste a escolha.
  Future<void> setTrackLimit(int limit) async {
    _trackLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('track_limit', limit);
    notifyListeners();
  }

  /// Define a qualidade de reprodução (influencia no streaming no futuro) e persiste a escolha.
  Future<void> setQuality(String quality) async {
    _quality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality', quality);
    notifyListeners();
  }
}

/// Tela de Configurações onde o usuário pode gerenciar preferências do aplicativo.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
            // Opção para configurar o limite de cache offline.
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
          // Opção para alterar a qualidade sonora.
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

  /// Exibe um diálogo simples para entrada numérica do limite de faixas.
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

  /// Exibe uma lista de opções para escolha da qualidade de áudio.
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
