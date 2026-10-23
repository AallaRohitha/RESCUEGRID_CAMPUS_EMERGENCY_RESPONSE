import 'dart:math';
import '../models/models.dart';
import 'severity_engine.dart';

class Candidate {
  final Responder responder;
  final double score;
  final double km;
  final int etaMin;
  Candidate(this.responder, this.score, this.km, this.etaMin);
}

class DispatchEngine {
  static List<Candidate> rank(Incident inc, List<Responder> all) {
    // Serious cases: being close matters more than workload.
    final serious = inc.severity.index >= Severity.high.index;
    const wSkill = 0.40;
    final wDist = serious ? 0.35 : 0.25;
    final wLoad = serious ? 0.25 : 0.35;

    final list = <Candidate>[];
    for (final r in all) {
      if (!r.onDuty || r.workload >= 3 || inc.declinedBy.contains(r.id)) {
        continue;
      }
      final km = distanceKm(r.lat, r.lng, inc.lat, inc.lng);
      final skill = r.skills.contains(inc.category) ? 1.0 : 0.0;
      final dist = max(0.0, 1 - km / 2); // 0 km = 1.0, 2 km or more = 0
      final load = 1 - r.workload / 3;
      final score = 100 * (wSkill * skill + wDist * dist + wLoad * load);
      final eta = max(1, (km / 0.5).ceil()); // about 30 km/h on campus
      list.add(Candidate(r, score, km, eta));
    }
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}