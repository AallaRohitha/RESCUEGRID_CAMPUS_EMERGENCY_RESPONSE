enum Category { medical, fire, accident, security, harassment }
enum Severity { low, medium, high, critical }
enum Status { reported, assigned, accepted, enRoute, arrived, resolved }

class Zone {
  final String name;
  final double lat, lng;
  final int risk; // 0-10, how risky this place is
  const Zone(this.name, this.lat, this.lng, this.risk);
}

class TimelineEvent {
  final DateTime time = DateTime.now();
  final String text;
  TimelineEvent(this.text);
}

class AppNotice {
  final String to; // 'admin' or a responder id
  final String text;
  final DateTime time = DateTime.now();
  AppNotice(this.to, this.text);
}

class Responder {
  final String id, name;
  final Set<Category> skills;
  double lat, lng;
  bool onDuty;
  int workload;
  Responder({
    required this.id,
    required this.name,
    required this.skills,
    required this.lat,
    required this.lng,
    this.onDuty = true,
    this.workload = 0,
  });
}

class Incident {
  final String id;
  final Category category;
  final String description;
  final double lat, lng;
  final int people;
  final String? photoPath;
  final DateTime createdAt = DateTime.now();

  Severity severity = Severity.low;
  int score = 0;
  Status status = Status.reported;
  String? responderId;
  int attempts = 0;
  final Set<String> declinedBy = {};
  final List<TimelineEvent> timeline = [];

  Incident({
    required this.id,
    required this.category,
    required this.description,
    required this.lat,
    required this.lng,
    required this.people,
    this.photoPath,
  });
}