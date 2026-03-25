import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/services/auth_service.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final GoogleSignInAccount user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksState = ref.watch(musicListProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            const Text('Perfil', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF2A2A2A),
                    child: ClipOval(
                      child: user.photoUrl == null
                          ? const Icon(Icons.person, size: 34, color: Colors.white70)
                          : CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.person, size: 34, color: Colors.white70),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName ?? 'Usuario OnSound', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(user.email, style: const TextStyle(color: Color(0xFFB3B3B3))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            tracksState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1ED760))),
              error: (err, _) => Text('Falha ao carregar estatisticas: $err'),
              data: (songs) {
                final offlineCount = songs.where((s) => s.isOffline).length;
                return Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Faixas', value: '${songs.length}')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(title: 'Offline', value: '$offlineCount')),
                    const SizedBox(width: 10),
                    const Expanded(child: _StatCard(title: 'Plano', value: 'Premium')),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _ActionTile(
              icon: Icons.tune,
              title: 'Configuracoes',
              subtitle: 'Qualidade, cache e preferncias',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.sync,
              title: 'Sincronizar biblioteca',
              subtitle: 'Atualizar arquivos do Google Drive',
              onTap: () {
                ref.invalidate(musicListProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biblioteca atualizada.')),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.logout,
              title: 'Sair da conta',
              subtitle: 'Desconectar Google Sign-In',
              danger: true,
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1ED760))),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Color(0xFFB3B3B3))),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: danger ? const Color(0xFFFF6E6E) : const Color(0xFF1ED760)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? const Color(0xFFFFADAD) : Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFFB3B3B3))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFB3B3B3)),
      ),
    );
  }
}
