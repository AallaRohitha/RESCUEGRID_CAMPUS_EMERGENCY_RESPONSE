import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class IncidentDetailScreen extends StatelessWidget {
  final Incident inc;
  const IncidentDetailScreen(this.inc, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Incident ${inc.id}')),
      body: IncidentDetailBody(inc),
    );
  }
}