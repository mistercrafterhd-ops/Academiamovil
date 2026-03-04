import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/dashboard_screen.dart'; // ajusta si tu pantalla inicial es otra

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ayabvbhemahpawgjqrcg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5YWJ2YmhlbWFocGF3Z2pxcmNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NDU3MjUsImV4cCI6MjA4ODAyMTcyNX0.Fy-R8w6SzZKDdrYrpkfiye32bEv_I0GcQvcfXtqqzz4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Test rápido (ver consola)
    final supabase = Supabase.instance.client;
    // ignore: avoid_print
    print("Conectado a Supabase: ${supabase.auth.currentSession != null}");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduControl',
      theme: ThemeData(useMaterial3: true),
      home: const DashboardScreen(),
    );
  }
}