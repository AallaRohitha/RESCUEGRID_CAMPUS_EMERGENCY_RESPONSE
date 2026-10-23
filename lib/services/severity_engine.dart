import 'dart:math';
import '../models/models.dart';

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a = pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(sqrt(a));
}

class SeverityResult {
  final int score;
  final Severity level;
  final List<String> reasons;
  SeverityResult(this.score, this.level, this.reasons);
}

class SeverityEngine {
  // Placeholder coordinates: change them to your real campus places.
  static const zones = [
    Zone('Hostel', 16.7612, 80.6305, 8),
    Zone('Chemistry Lab', 16.7620, 80.6312, 9),
    Zone('Canteen', 16.7608, 80.6298, 6),
    Zone('Main Gate', 16.7600, 80.6290, 5),
    Zone('Sports Ground', 16.7625, 80.6320, 5),
    Zone('Library', 16.7615, 80.6308, 3),
  ];

  static const _base = {
    Category.medical: 40,
    Category.fire: 50,
    Category.accident: 35,
    Category.security: 25,
    Category.harassment: 30,
  };

  static const _keywords = [
    'unconscious', 'bleeding', 'fire', 'smoke', 'breathing',
    'chest', 'weapon', 'trapped', 'blast',
  ];

  static Zone nearestZone(double lat, double lng) {
    return zones.reduce((a, b) =>
        distanceKm(lat, lng, a.lat, a.lng) <= distanceKm(lat, lng, b.lat, b.lng)
            ? a
            : b);
  }

  static SeverityResult assess({
    required Category category,
    required String description,
    required int people,
    required double lat,
    required double lng,
    DateTime? now,
  }) {
    final reasons = <String>[];
    var score = _base[category]!;
    reasons.add('${category.name} +$score');

    // 1. Keywords in the description (max +25)
    final text = description.toLowerCase();
    final hits = _keywords.where(text.contains).length;
    if (hits > 0) {
      final add = min(25, hits * 10);
      score += add;
      reasons.add('danger words +$add');
    }

    // 2. Number of people affected (max +20)
    if (people > 1) {
      final add = min(5, people - 1) * 4;
      score += add;
      reasons.add('$people people +$add');
    }

    // 3. Night time
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 22 || hour < 6) {
      score += 8;
      reasons.add('night time +8');
    }

    // 4. Risky location
    final zone = nearestZone(lat, lng);
    score += zone.risk;
    reasons.add('${zone.name} +${zone.risk}');

    score = score.clamp(0, 100);
    final level = score >= 75
        ? Severity.critical
        : score >= 55
            ? Severity.high
            : score >= 35
                ? Severity.medium
                : Severity.low;
    return SeverityResult(score, level, reasons);
  }
}