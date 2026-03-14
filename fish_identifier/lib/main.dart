import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/di/injection.dart';
import 'features/detection/presentation/bloc/detection_bloc.dart';
import 'features/detection/presentation/bloc/detection_event.dart';
import 'features/detection/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupDependencyInjection();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FishIdentifierApp());
}

class FishIdentifierApp extends StatelessWidget {
  const FishIdentifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Identifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D77), // Deep Teal
          primary: const Color(0xFF006D77),
          secondary: const Color(0xFF83C5BE), // Mint
          tertiary: const Color(0xFFE29578), // Earthy Terra Cotta
          background: const Color(0xFFF1FAEE), // Soft White
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.teal.withOpacity(0.1)),
          ),
          color: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF006D77),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: BlocProvider(
        create: (context) {
          final bloc = getIt<DetectionBloc>();
          bloc.add(const InitializeModel());
          return bloc;
        },
        child: const HomePage(),
      ),
    );
  }
}
