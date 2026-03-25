import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/services/auth_service.dart';
import 'features/dashboard/home_dashboard_screen.dart';
import 'features/library/library_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/search/search_screen.dart';
import 'widgets/google_auth_button.dart';
import 'widgets/mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OnSoundApp()));
}

class OnSoundApp extends StatelessWidget {
  const OnSoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: Colors.white, displayColor: Colors.white);

    return MaterialApp(
      title: 'OnSound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1ED760),
          secondary: Color(0xFFB3B3B3),
          surface: Color(0xFF121212),
        ),
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1ED760),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final authService = ref.read(authServiceProvider);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1ED760))),
      );
    }

    if (user != null) {
      return AppShell(user: user);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF121212), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1ED760).withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1ED760).withValues(alpha: 0.2),
                        blurRadius: 35,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.graphic_eq, color: Color(0xFF1ED760), size: 64),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
                const SizedBox(height: 28),
                Text(
                  'ONSOUND',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
                const SizedBox(height: 10),
                const Text(
                  'Sua biblioteca de musica em qualquer lugar, com vibe de player premium.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 15),
                ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
                const SizedBox(height: 40),
                buildGoogleAuthButton(
                  onPressed: () async {
                    final account = await authService.signIn();
                    if (account == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Falha ao autenticar. Tente novamente.')),
                      );
                    }
                  },
                ).animate().fadeIn(delay: 320.ms, duration: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  final GoogleSignInAccount user;

  const AppShell({super.key, required this.user});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeDashboardScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            NavigationBar(
              height: 70,
              backgroundColor: const Color(0xFF0A0A0A),
              indicatorColor: const Color(0xFF1ED760).withValues(alpha: 0.15),
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.manage_search), label: 'Buscar'),
                NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Biblioteca'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const ProfileAvatar({super.key, required this.photoUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2C2C2C),
        child: Icon(Icons.person, color: Colors.white70, size: radius),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2C2C2C),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Icon(Icons.person, color: Colors.white70, size: radius),
        ),
      ),
    );
  }
}
