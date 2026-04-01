import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'add_food_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Set<Marker> markers = {};

  GoogleMapController? mapController;
  LatLng? currentPosition;

  String selectedRole = "Volunteer";

  int mealsSaved = 0;

  @override
  void initState() {
    super.initState();
    listenToMarkers();
    getUserLocation();
  }

  Future<void> getUserLocation() async {
    var permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    currentPosition = LatLng(position.latitude, position.longitude);

    setState(() {});
  }

  void listenToMarkers() {
    _db.collection('issues').snapshots().listen((snapshot) {
      Set<Marker> tempMarkers = {};
      int tempMeals = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['status'] == 'delivered') {
          tempMeals += (data['quantity'] ?? 0) as int;
        }

        if (data['status'] == 'available') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🚨 New food: ${data['foodName']}"),
              ),
            );
          });
        }

        tempMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['lat'], data['lng']),
            infoWindow: InfoWindow(
              title: data['foodName'] ?? data['type'],
              snippet: data['status'],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "🍱 ${data['foodName'] ?? data['type']}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("Quantity: ${data['quantity'] ?? 0}"),
                        Text("Status: ${data['status']}"),

                        // 🔥 UPDATED TIMER (ONLY CHANGE)
                        if (data['time'] != null &&
                            data['expiryMinutes'] != null)
                          Builder(
                            builder: (_) {
                              final createdTime =
                                  (data['time'] as Timestamp).toDate();

                              final expiryMinutes =
                                  data['expiryMinutes'] ?? 60;

                              final expiryTime = createdTime.add(
                                Duration(minutes: expiryMinutes),
                              );

                              final remaining =
                                  expiryTime.difference(DateTime.now());

                              if (remaining.isNegative) {
                                return const Text(
                                  "❌ Expired",
                                  style: TextStyle(color: Colors.red),
                                );
                              }

                              final minutes = remaining.inMinutes;
                              final seconds =
                                  remaining.inSeconds % 60;

                              return Text(
                                "⏳ ${minutes}m ${seconds}s remaining",
                                style: const TextStyle(
                                    color: Colors.orange),
                              );
                            },
                          ),

                        if (data['volunteer'] != null)
                          Text("Volunteer: ${data['volunteer']}"),

                        if (data['ngoStatus'] != null)
                          Text("NGO Status: ${data['ngoStatus']}"),

                        const SizedBox(height: 15),

                        if (selectedRole == "Volunteer") ...[
                          ElevatedButton(
                            onPressed: () {
                              _db.collection('issues').doc(doc.id).update({
                                'status': 'accepted',
                                'volunteer': 'Rahul',
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Accept Pickup"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _db.collection('issues').doc(doc.id).update({
                                'status': 'picked',
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Picked Up"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _db.collection('issues').doc(doc.id).update({
                                'status': 'delivered',
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Delivered"),
                          ),
                        ],

                        if (selectedRole == "NGO") ...[
                          const Text("🏢 NGO Actions"),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              _db.collection('issues').doc(doc.id).update({
                                'ngoStatus': 'accepted_by_ngo',
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Accepted by NGO"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _db.collection('issues').doc(doc.id).update({
                                'ngoStatus': 'picked_by_ngo',
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Picked by NGO"),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      }

      setState(() {
        markers = tempMarkers;
        mealsSaved = tempMeals;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🍱 Food Rescue System"),
            Text("🍽 Meals Saved: $mealsSaved",
                style: const TextStyle(fontSize: 14)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              items: ["Donor", "Volunteer", "NGO"]
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition ?? const LatLng(12.9716, 77.5946),
          zoom: 14,
        ),
        markers: markers,
      ),
      floatingActionButton: selectedRole == "Donor"
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}