import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'cubits/jarvis_cubit.dart';
import 'screens/jarvis_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await setupLocator();
  await _requestPermissions();
  await initializeBackgroundService();

  runApp(const JarvisApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.microphone,
    Permission.speech,
    Permission.notification,
  ].request();
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: BlocProvider(
        create: (_) => sl<JarvisCubit>(),
        child: const JarvisScreen(),
      ),
    );
  }
}
