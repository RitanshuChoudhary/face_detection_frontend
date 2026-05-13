import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/splash_screen.dart';
import 'features/device_monitoring/data/native_services/background_service.dart';
import 'features/device_monitoring/presentation/controllers/monitoring_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background data monitoring
  try {
    await initializeBackgroundService();
  } catch (e) {
    debugPrint('Background service init failed: $e');
  }
  
  runApp(const FaceTrackApp());
}

class FaceTrackApp extends StatelessWidget {
  const FaceTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringController()),
      ],
      child: MaterialApp(
        title: 'Face Track',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system, // Dynamically matches iOS and Android theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
