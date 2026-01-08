import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/home_screen.dart';
import 'providers/app_state.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/retry_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  AppConfig(
    environment: Environment.development,
    enableOfflineMode: true,
    syncInterval: const Duration(minutes: 15),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (_) => ApiService(
            baseUrl: AppConfig.instance.apiBaseUrl,
            retryConfig: const RetryConfig(
              maxAttempts: 3,
              initialDelay: Duration(milliseconds: 500),
              maxDelay: Duration(seconds: 10),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(
            apiService: context.read<ApiService>(),
          ),
        ),
        StreamProvider<ConnectivityResult>(
          initialData: ConnectivityResult.none,
          create: (_) => Connectivity().onConnectivityChanged,
          updateShouldNotify: (previous, current) => true,
        ),
      ],
      child: Consumer<ConnectivityResult>(
        builder: (context, connectivity, child) {
          // Update offline status in AppState
          final appState = context.read<AppState>();
          final isOffline = connectivity == ConnectivityResult.none;
          appState.setOfflineStatus(isOffline);

          return MaterialApp(
            title: 'Visual AI',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}