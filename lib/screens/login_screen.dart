import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Widget _btn(BuildContext c, String text, IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 280,
        height: 52,
        child: FilledButton.icon(
          icon: Icon(icon),
          label: Text(text),
          onPressed: () => Navigator.pushNamed(c, route),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.crisis_alert, size: 72, color: Colors.red),
              const Text('RescueGrid',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Campus emergency response'),
              const SizedBox(height: 8),
              const Text('Campus Login (demo)',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              _btn(context, 'Student', Icons.school, '/student'),
              _btn(context, 'Responder', Icons.health_and_safety, '/responder'),
              _btn(context, 'Command Center (Admin)',
                  Icons.admin_panel_settings, '/admin'),
            ],
          ),
        ),
      ),
    );
  }
}