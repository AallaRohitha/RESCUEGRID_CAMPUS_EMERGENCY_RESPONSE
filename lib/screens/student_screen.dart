import 'package:flutter/material.dart' hide Category;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/incident_provider.dart';
import '../services/severity_engine.dart';
import '../widgets/common.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  Category cat = Category.medical;
  final desc = TextEditingController();
  int people = 1;
  Zone zone = SeverityEngine.zones.first;
  double? gpsLat, gpsLng;
  String? photo;

  double get lat => gpsLat ?? zone.lat;
  double get lng => gpsLng ?? zone.lng;

  Future<void> useGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'denied';
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        gpsLat = pos.latitude;
        gpsLng = pos.longitude;
      });
      _msg('GPS location captured');
    } catch (_) {
      _msg('GPS not available, using selected campus place');
    }
  }

  Future<void> pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera);
    if (x != null) setState(() => photo = x.path);
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void sendSos() {
    final inc = context.read<IncidentProvider>().report(
          category: cat,
          description: desc.text,
          people: people,
          lat: lat,
          lng: lng,
          photoPath: photo,
        );
    desc.clear();
    setState(() {
      photo = null;
      people = 1;
      gpsLat = null;
      gpsLng = null;
    });
    _msg('SOS sent! ${inc.id} - ${inc.severity.name.toUpperCase()}');
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<IncidentProvider>().incidents;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('What happened?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: Category.values
                    .map((c) => ChoiceChip(
                          avatar: Icon(categoryIcon(c), size: 18),
                          label: Text(c.name),
                          selected: cat == c,
                          onSelected: (_) => setState(() => cat = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desc,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('People affected:'),
                IconButton(
                    onPressed: () =>
                        setState(() => people = people > 1 ? people - 1 : 1),
                    icon: const Icon(Icons.remove_circle_outline)),
                Text('$people', style: const TextStyle(fontSize: 18)),
                IconButton(
                    onPressed: () => setState(() => people++),
                    icon: const Icon(Icons.add_circle_outline)),
              ]),
              DropdownButtonFormField<Zone>(
                value: zone,
                decoration: const InputDecoration(
                    labelText: 'Campus place', border: OutlineInputBorder()),
                items: SeverityEngine.zones
                    .map((z) =>
                        DropdownMenuItem(value: z, child: Text(z.name)))
                    .toList(),
                onChanged: (z) => setState(() {
                  zone = z!;
                  gpsLat = null;
                  gpsLng = null;
                }),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: useGps,
                    icon: const Icon(Icons.my_location),
                    label: Text(gpsLat == null ? 'Use my GPS' : 'GPS captured'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(photo == null ? 'Add photo' : 'Photo added'),
                  ),
                ),
              ]),
              if (photo != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: photoView(photo!)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: sendSos,
                  icon: const Icon(Icons.sos, size: 32),
                  label: const Text('SEND SOS',
                      style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Live tracking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (list.isEmpty) const Text('No reports yet.'),
              ...list.map((i) => IncidentCard(i,
                  onTap: () =>
                      Navigator.pushNamed(context, '/detail', arguments: i))),
            ],
          ),
        ),
      ),
    );
  }
}