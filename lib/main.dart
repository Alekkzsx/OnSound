import 'package:flutter/material.dart'; // Importa o SDK do Flutter para UI (Material Design).
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importa o Riverpod para gerenciamento de estado.
import 'package:google_fonts/google_fonts.dart'; // Importa fontes externas do Google Fonts.
import 'package:cached_network_image/cached_network_image.dart';
import 'features/library/library_screen.dart'; // Importa a tela da biblioteca local do projeto.
import 'core/services/auth_service.dart'; // Importa o serviço de autenticação do projeto.
import 'widgets/google_auth_button.dart'; // Botão do Google cross-platform

/// A função [main] é o ponto de partida de qualquer aplicativo Flutter/Dart.
void main() {
  /// [WidgetsFlutterBinding.ensureInitialized] garante que os serviços do Flutter
  /// (como plugins, acesso a arquivos, etc.) estejam prontos antes de chamar código assíncrono.
  WidgetsFlutterBinding.ensureInitialized();
  
  /// [runApp] inicia o ciclo de vida do Flutter e renderiza o widget raiz.
  runApp(
    /// [ProviderScope] é um widget obrigatório do Riverpod. Ele armazena o estado
    /// de todos os "providers" (provedores de dados) criados no aplicativo.
    const ProviderScope(
      child: OnSoundApp(),
    ),
  );
}

/// [OnSoundApp] é o widget raiz de nível superior.
/// Usamos [StatelessWidget] porque as configurações globais do app não mudam após o início.
class OnSoundApp extends StatelessWidget {
  const OnSoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// [MaterialApp] é o "esqueleto" que configura navegação, localização e temas.
    return MaterialApp(
      title: 'OnSound',
      debugShowCheckedModeBanner: false, // Oculta a etiqueta "DEBUG" no canto superior.
      
      /// [ThemeData] define o DNA visual do app (cores, fontes, tamanhos).
      theme: ThemeData(
        brightness: Brightness.dark, // Define que o app usará cores escuras por padrão.
        scaffoldBackgroundColor: Colors.black, // Cor de fundo de cada tela.
        
        /// [ColorScheme] organiza as cores principais (Primária, Secundária, etc).
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Colors.black,
        ),
        
        /// [useMaterial3] ativa as diretrizes de design mais recentes do Google (Android 12/13+).
        useMaterial3: true,
        
        /// [textTheme] define os estilos de texto globais.
        /// Aqui usamos [GoogleFonts.outfitTextTheme] para aplicar a fonte 'Outfit'.
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        
        /// [elevatedButtonTheme] define como os botões de destaque devem se parecer em todo o app.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
      ),
      
      /// [home] define qual é a primeira tela que o usuário verá ao abrir o app.
      home: const MainScreen(),
    );
  }
}

/// [MainScreen] é a tela inicial. Usamos [ConsumerWidget] (comando do Riverpod)
/// para que possamos "consumir" (ler/observar) dados dos nossos serviços.
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  /// O método [build] é chamado sempre que a UI precisa ser desenhada.
  /// O parâmetro [ref] nos permite interagir com os Providers do Riverpod.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// [ref.watch] observa um provider. Se o valor do provider mudar,
    /// o Flutter reconstrói automaticamente esta tela.
    final user = ref.watch(authStateProvider); // Estado da conta Google.
    final isLoading = ref.watch(authLoadingProvider); // Verificando login automático.
    final authService = ref.read(authServiceProvider);

    // Se estiver verificando o login automático, mostra uma tela de splash/carregamento.
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    /// [Scaffold] fornece a estrutura básica de UI (AppBars, Drawers, SnackBar).
    return Scaffold(
      /// [Stack] permite empilhar widgets um em cima do outro (Z-axis).
      body: Stack(
        children: [
          /// Primeiro item do Stack (Fundo): Um gradiente decorativo.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A1A), // Cinza quase preto.
                  Colors.black,
                ],
              ),
            ),
          ),
          
          /// Segundo item do Stack: O conteúdo principal do app.
          /// [SafeArea] evita que o conteúdo fique sob o notch ou barra de status.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente.
                children: [
                  /// [Container] usado para criar o círculo de brilho (Logo).
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40), // Espaço fixo vertical.
                  
                  /// Título do Aplicativo.
                  Text(
                    'ONSOUND',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  /// Slogan.
                  Text(
                    'Sua música em qualquer lugar.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 80),
                  
                  /// LÓGICA DE INTERFACE CONDICIONAL:
                  /// Se o usuário [user] for nulo, mostramos o login.
                  if (user == null)
                    buildGoogleAuthButton(
                      onPressed: () async {
                        final result = await authService.signIn();
                        if (result == null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Falha ao autenticar. Tente novamente.')),
                          );
                        }
                      },
                    )
                  /// Se o usuário estiver logado, mostramos seu perfil e acesso à biblioteca.
                  else
                    Column(
                      children: [
                        /// Círculo com a foto de perfil do Google.
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: user.photoUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.photoUrl!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person, size: 35, color: Colors.black),
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 35,
                                  child: Icon(Icons.person, size: 35, color: Colors.black),
                                ),
                        ),
                        const SizedBox(height: 20),
                        
                        /// Nome de exibição do usuário.
                        Text(
                          'Olá, ${user.displayName}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        /// Botão principal para entrar na biblioteca.
                        ElevatedButton(
                          onPressed: () {
                            /// [Navigator.push] troca a tela atual por uma nova.
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LibraryScreen()),
                            );
                          },
                          child: const Text(
                            'Ver Minha Biblioteca',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        /// Botão discreto para deslogar.
                        TextButton(
                          onPressed: () => authService.signOut(), // Chama função de logout.
                          child: const Text(
                            'Sair da conta',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
