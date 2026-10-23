import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Category;
import '../models/models.dart';
import '../services/dispatch_engine.dart';
import '../services/severity_engine.dart';

class IncidentProvider extends ChangeNotifier {
  static const acceptSeconds = 20; // time to accept before escalation
  static const maxAttempts = 3;

  final List<Incident> incidents = [];
  final List<AppNotice> notices = [];
  final Map<String, Timer> _timers = {};

  // Placeholder responders: change names and positions.
  final List<Responder> responders = [
    Responder(id: 'R1', name: 'Ravi (Medic)', skills: {Category.medical, Category.accident}, lat: 16.7611, lng: 80.6303),
    Responder(id: 'R2', name: 'Anil (Fire Safety)', skills: {Category.fire}, lat: 16.7622, lng: 80.6315),
    Responder(id: 'R3', name: 'Suresh (Security)', skills: {Category.security, Category.harassment, Category.accident}, lat: 16.7601, lng: 80.6292),
    Responder(id: 'R4', name: 'Divya (Nurse)', skills: {Category.medical}, lat: 16.7616, lng: 80.6309),
    Responder(id: 'R5', name: 'Kiran (Security)', skills: {Category.security, Category.fire}, lat: 16.7626, lng: 80.6321),
  ];

  Responder? responderById(String? id) {
    for (final r in responders) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Incident> forResponder(String id) =>
      incidents.where((i) => i.responderId == id && i.status != Status.resolved).toList();

  List<AppNotice> noticesFor(String to) => notices.where((n) => n.to == to).toList();

  // ---------- Student ----------
  Incident report({
    required Category category,
    required String description,
    required int people,
    required double lat,
    required double lng,
    String? photoPath,
  }) {
    final result = SeverityEngine.assess(
      category: category, description: description,
      people: people, lat: lat, lng: lng,
    );
    final inc = Incident(
      id: 'INC${incidents.length + 1}',
      category: category, description: description,
      lat: lat, lng: lng, people: people, photoPath: photoPath,
    );
    inc.severity = result.level;
    inc.score = result.score;
    _log(inc, 'Reported by student');
    _log(inc, 'Severity ${result.level.name.toUpperCase()} (${result.score}/100): ${result.reasons.join(', ')}');
    incidents.insert(0, inc);
    _assign(inc);
    notifyListeners();
    return inc;
  }

  // ---------- Dispatch ----------
  void _assign(Incident inc) {
    _timers[inc.id]?.cancel();
    final ranked = DispatchEngine.rank(inc, responders);
    if (ranked.isEmpty || inc.attempts >= maxAttempts) {
      inc.status = Status.reported;
      inc.responderId = null;
      _log(inc, 'No responder available - command center alerted');
      _notify('admin', '${inc.id} needs manual assignment');
      return;
    }
    final best = ranked.first;
    inc.attempts++;
    inc.responderId = best.responder.id;
    inc.status = Status.assigned;
    best.responder.workload++;
    _log(inc, 'Auto-assigned to ${best.responder.name} '
        '(score ${best.score.toStringAsFixed(0)}, ETA ${best.etaMin} min)');
    _notify(best.responder.id, 'New ${inc.severity.name} incident ${inc.id}');
    _timers[inc.id] = Timer(const Duration(seconds: acceptSeconds), () => _escalate(inc));
  }

  void _escalate(Incident inc) {
    if (inc.status != Status.assigned) return;
    _log(inc, 'Not accepted in ${acceptSeconds}s - escalating to next candidate');
    _release(inc);
    _notify('admin', '${inc.id} escalated (no response)');
    _assign(inc);
    notifyListeners();
  }

  void _release(Incident inc) {
    final r = responderById(inc.responderId);
    if (r != null) {
      r.workload = max(0, r.workload - 1);
      inc.declinedBy.add(r.id);
    }
    inc.responderId = null;
  }

  // ---------- Responder ----------
  void accept(Incident inc) {
    _timers[inc.id]?.cancel();
    inc.status = Status.accepted;
    _log(inc, '${responderById(inc.responderId)?.name} accepted');
    notifyListeners();
  }

  void decline(Incident inc) {
    final name = responderById(inc.responderId)?.name;
    _log(inc, '$name declined');
    _release(inc);
    _assign(inc);
    notifyListeners();
  }

  void setStatus(Incident inc, Status s) {
    inc.status = s;
    _log(inc, 'Status: ${s.name}');
    if (s == Status.resolved) {
      final r = responderById(inc.responderId);
      if (r != null) r.workload = max(0, r.workload - 1);
      _notify('admin', '${inc.id} resolved');
    }
    notifyListeners();
  }

  void requestBackup(Incident inc) {
    _log(inc, 'Backup requested');
    _notify('admin', '${inc.id}: backup requested');
    notifyListeners();
  }
    void toggleDuty(Responder r) {
    r.onDuty = !r.onDuty;
    notifyListeners();
  }

  // ---------- Admin ----------
  void manualAssign(Incident inc, Responder r) {
    _timers[inc.id]?.cancel();
    if (inc.responderId != null) _release(inc);
    inc.responderId = r.id;
    inc.status = Status.assigned;
    r.workload++;
    _log(inc, 'Admin manually assigned to ${r.name}');
    _notify(r.id, 'Admin assigned you ${inc.id}');
    notifyListeners();
  }

  int get total => incidents.length;
  int get active => incidents.where((i) => i.status != Status.resolved).length;
  int get resolved => total - active;
  int countSeverity(Severity s) => incidents.where((i) => i.severity == s).length;

  // ---------- Helpers ----------
  void _log(Incident inc, String text) => inc.timeline.add(TimelineEvent(text));
  void _notify(String to, String text) => notices.insert(0, AppNotice(to, text));

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}