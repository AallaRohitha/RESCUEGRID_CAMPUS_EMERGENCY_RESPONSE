import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/incident_provider.dart';
import '../widgets/common.dart';

class ResponderScreen extends StatefulWidget {
  const ResponderScreen({super.key});
  @override
  State<ResponderScreen> createState() => _ResponderScreenState();
}

class _ResponderScreenState extends State<ResponderScreen> {
  String rid = 'R1';

  Future<void> navigate(Incident i) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${i.lat},${i.lng}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget actions(IncidentProvider p, Incident i) {
    final buttons = <Widget>[];
    switch (i.status) {
      case Status.assigned:
        buttons.addAll([
          FilledButton(onPressed: () => p.accept(i), child: const Text('Accept')),
          OutlinedButton(
              onPressed: () => p.decline(i), child: const Text('Decline')),
        ]);
      case Status.accepted:
        buttons.add(FilledButton(
            onPressed: () => p.setStatus(i, Status.enRoute),
            child: const Text('I am on the way')));
      case Status.enRoute:
        buttons.add(FilledButton(
            onPressed: () => p.setStatus(i, Status.arrived),
            child: const Text('I have arrived')));
      case Status.arrived:
        buttons.add(FilledButton(
            onPressed: () => p.setStatus(i, Status.resolved),
            child: const Text('Mark resolved')));
      default:
    }
    if (i.status != Status.assigned) {
      buttons.addAll([
        OutlinedButton.icon(
            onPressed: () => navigate(i),
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate')),
        OutlinedButton.icon(
            onPressed: () => p.requestBackup(i),
            icon: const Icon(Icons.group_add),
            label: const Text('Backup')),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(spacing: 8, children: buttons),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final r = p.responderById(rid)!;
    final list = p.forResponder(rid);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responder'),
        actions: [NoticeBell(rid)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: rid,
                    isExpanded: true,
                    items: p.responders
                        .map((x) => DropdownMenuItem(
                            value: x.id, child: Text(x.name)))
                        .toList(),
                    onChanged: (v) => setState(() => rid = v!),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('On duty'),
                Switch(value: r.onDuty, onChanged: (_) => p.toggleDuty(r)),
              ]),
              Text('Workload: ${r.workload}/3 active cases'),
              const Divider(),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No active assignments')),
                ),
              ...list.map((i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IncidentCard(i,
                          onTap: () => Navigator.pushNamed(context, '/detail',
                              arguments: i)),
                      actions(p, i),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}