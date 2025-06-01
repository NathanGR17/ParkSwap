import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';
import 'package:parkswap/screens/home_screen.dart';
import 'package:parkswap/screens/startup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_provider.dart';
import 'auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://joelfrapfycnsilvmtpg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvZWxmcmFwZnljbnNpbHZtdHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwNTcyNTgsImV4cCI6MjA2MjYzMzI1OH0.AyoabNLDCiLbXMPHAaZJnzawqdalUAVOdbWxtWsD9gE',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkSwap',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StartupScreen(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}