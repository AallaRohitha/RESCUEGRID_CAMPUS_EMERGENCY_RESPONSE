import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/incident_provider.dart';
import '../services/severity_engine.dart';

Color severityColor(Severity s) => switch (s) {
      Severity.low => Colors.green,
      Severity.medium => Colors.orange,
      Severity.high => Colors.deepOrange,
      Severity.critical => Colors.red,
    };

String statusText(Status s) => switch (s) {
      Status.reported => 'Reported',
      Status.assigned => 'Waiting for responder',
      Status.accepted => 'Accepted',
      Status.enRoute => 'On the way',
      Status.arrived => 'Arrived',
      Status.resolved => 'Resolved',
    };

IconData categoryIcon(Category c) => switch (c) {
      Category.medical => Icons.medical_services,
      Category.fire => Icons.local_fire_department,
      Category.accident => Icons.car_crash,
      Category.security => Icons.shield,
      Category.harassment => Icons.report,
    };

String two(int n) => n.toString().padLeft(2, '0');

Widget photoView(String path) => kIsWeb
    ? Image.network(path, height: 160, fit: BoxFit.cover)
    : Image.file(File(path), height: 160, fit: BoxFit.cover);

// ---------- Incident card ----------
class IncidentCard extends StatelessWidget {
  final Incident inc;
  final VoidCallback? onTap;
  final Widget? trailing;
  const IncidentCard(this.inc, {super.key, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<IncidentProvider>().responderById(inc.responderId);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor(inc.severity),
          child: Icon(categoryIcon(inc.category), color: Colors.white),
        ),
        title: Text('${inc.id} - ${inc.category.name.toUpperCase()}'),
        subtitle: Text(
            '${statusText(inc.status)}${r != null ? ' - ${r.name}' : ''}\n'
            'Severity: ${inc.severity.name.toUpperCase()} (${inc.score}/100)'),
        isThreeLine: true,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// ---------- Timeline ----------
class TimelineView extends StatelessWidget {
  final Incident inc;
  const TimelineView(this.inc, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: inc.timeline.map((e) {
        final t = e.time;
        return ListTile(
          dense: true,
          leading: const Icon(Icons.circle, size: 10),
          title: Text(e.text),
          subtitle: Text('${two(t.hour)}:${two(t.minute)}:${two(t.second)}'),
        );
      }).toList(),
    );
  }
}

// ---------- Notification bell ----------
class NoticeBell extends StatelessWidget {
  final String target; // 'admin' or responder id
  const NoticeBell(this.target, {super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<IncidentProvider>().noticesFor(target);
    return IconButton(
      icon: Badge(
        isLabelVisible: list.isNotEmpty,
        label: Text('${list.length}'),
        child: const Icon(Icons.notifications),
      ),
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (_) => list.isEmpty
            ? const Center(child: Text('No notifications'))
            : ListView(
                children: list
                    .map((n) => ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(n.text),
                          subtitle: Text(
                              '${two(n.time.hour)}:${two(n.time.minute)}:${two(n.time.second)}'),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

// ---------- Offline campus map ----------
class CampusMap extends StatelessWidget {
  final Incident inc;
  const CampusMap(this.inc, {super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<IncidentProvider>().responderById(inc.responderId);
    return AspectRatio(
      aspectRatio: 1.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(painter: _MapPainter(inc, r)),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Incident inc;
  final Responder? r;
  _MapPainter(this.inc, this.r);

  // Change these to the corners of YOUR campus.
  static const minLat = 16.7595, maxLat = 16.7632;
  static const minLng = 80.6285, maxLng = 80.6327;

  Offset pos(double lat, double lng, Size s) => Offset(
        (lng - minLng) / (maxLng - minLng) * s.width,
        (1 - (lat - minLat) / (maxLat - minLat)) * s.height,
      );

  void label(Canvas c, String t, Offset o, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 10, color: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o + const Offset(8, -5));
  }

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE8F5E9));
    for (final z in SeverityEngine.zones) {
      final o = pos(z.lat, z.lng, s);
      c.drawCircle(o, 5, Paint()..color = Colors.blueGrey.shade300);
      label(c, z.name, o, Colors.blueGrey.shade700);
    }
    final i = pos(inc.lat, inc.lng, s);
    if (r != null) {
      final ro = pos(r!.lat, r!.lng, s);
      c.drawLine(
          ro, i, Paint()..color = Colors.blue..strokeWidth = 2);
      c.drawCircle(ro, 8, Paint()..color = Colors.blue);
      label(c, r!.name, ro, Colors.blue.shade900);
    }
    c.drawCircle(i, 10, Paint()..color = Colors.red);
    c.drawCircle(i, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ---------- Detail body (used by detail screen and admin wide view) ----------
class IncidentDetailBody extends StatelessWidget {
  final Incident inc;
  const IncidentDetailBody(this.inc, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final r = p.responderById(inc.responderId);
    String eta = '-';
    if (r != null) {
      final km = distanceKm(r.lat, r.lng, inc.lat, inc.lng);
      eta = '${(km / 0.5).ceil().clamp(1, 999)} min (${km.toStringAsFixed(2)} km)';
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampusMap(inc),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            Chip(
              label: Text(inc.severity.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: severityColor(inc.severity),
            ),
            Chip(label: Text(statusText(inc.status))),
            Chip(label: Text('${inc.people} people')),
          ]),
          if (inc.description.isNotEmpty) Text('Description: ${inc.description}'),
          Text('Responder: ${r?.name ?? 'Not assigned'}'),
          Text('ETA: $eta'),
          if (inc.photoPath != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photoView(inc.photoPath!)),
          ],
          const Divider(),
          const Text('Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TimelineView(inc),
        ],
      ),
    );
  }
}