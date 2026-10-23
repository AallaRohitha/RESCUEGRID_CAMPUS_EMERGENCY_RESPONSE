import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/incident_provider.dart';
import 'screens/login_screen.dart';
import 'screens/student_screen.dart';
import 'screens/responder_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/incident_detail_screen.dart';
import 'models/models.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => IncidentProvider(),
    child: const RescueGridApp(),
  ));
}

class RescueGridApp extends StatelessWidget {
  const RescueGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RescueGrid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (c) => const LoginScreen(),
        '/student': (c) => const StudentScreen(),
        '/responder': (c) => const ResponderScreen(),
        '/admin': (c) => const AdminScreen(),
        '/detail': (c) => IncidentDetailScreen(
            ModalRoute.of(c)!.settings.arguments as Incident),
      },
    );
  }
}