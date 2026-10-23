import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/incident_provider.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Severity? filter;
  Incident? selected;

  Widget stat(String label, int v, Color c) => Expanded(
        child: Card(
          color: c.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text('$v',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: c)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  void assignDialog(Incident inc) {
    final p = context.read<IncidentProvider>();
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Assign ${inc.id} manually'),
        children: p.responders
            .map((r) => SimpleDialogOption(
                  onPressed: () {
                    p.manualAssign(inc, r);
                    Navigator.pop(context);
                  },
                  child: Text('${r.name}  (workload ${r.workload})'),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final list = p.incidents
        .where((i) => filter == null || i.severity == filter)
        .toList();
    final wide = MediaQuery.of(context).size.width > 800;

    final listPane = Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          stat('Total', p.total, Colors.blue),
          stat('Active', p.active, Colors.orange),
          stat('Resolved', p.resolved, Colors.green),
          stat('Critical', p.countSeverity(Severity.critical), Colors.red),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          ChoiceChip(
              label: const Text('All'),
              selected: filter == null,
              onSelected: (_) => setState(() => filter = null)),
          ...Severity.values.map((s) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(s.name),
                  selected: filter == s,
                  onSelected: (_) => setState(() => filter = s),
                ),
              )),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? const Center(child: Text('No incidents'))
            : ListView(
                children: list
                    .map((i) => IncidentCard(
                          i,
                          trailing: IconButton(
                            icon: const Icon(Icons.person_add),
                            tooltip: 'Manual assign',
                            onPressed: () => assignDialog(i),
                          ),
                          onTap: () => wide
                              ? setState(() => selected = i)
                              : Navigator.pushNamed(context, '/detail',
                                  arguments: i),
                        ))
                    .toList(),
              ),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center'),
        actions: const [NoticeBell('admin')],
      ),
      body: wide
          ? Row(children: [
              Expanded(flex: 2, child: listPane),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: selected == null
                    ? const Center(child: Text('Select an incident'))
                    : IncidentDetailBody(selected!),
              ),
            ])
          : listPane,
    );
  }
}