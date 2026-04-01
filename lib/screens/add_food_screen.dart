import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedFoodType = "Veg";

  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  // 🔥 NEW: Expiry controller
  final TextEditingController expiryController = TextEditingController();

  Future<void> submitFood() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission required")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await FirebaseFirestore.instance.collection('issues').add({
        'foodName': foodNameController.text.isEmpty
            ? selectedFoodType
            : foodNameController.text,
        'quantity': int.tryParse(quantityController.text) ?? 0,

        // ⚠️ keeping your existing fixed location (not touching)
        'lat': 12.9237,
        'lng': 77.4980,

        'status': 'available',
        'time': FieldValue.serverTimestamp(),

        // 🔥 NEW FIELD
        'expiryMinutes': int.tryParse(expiryController.text) ?? 60,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food reported successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🍱 Report Food")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 FOOD NAME INPUT
            TextField(
              controller: foodNameController,
              decoration: const InputDecoration(
                labelText: "Food Name (e.g., Rice, Biryani)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // 🔥 QUANTITY INPUT
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity (number of plates)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // 🔥 NEW: EXPIRY INPUT
            TextField(
              controller: expiryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Expiry Time (in minutes)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // EXISTING DROPDOWN (UNCHANGED)
            DropdownButton<String>(
              value: selectedFoodType,
              isExpanded: true,
              items: ["Veg", "Non-Veg"].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFoodType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: submitFood,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Report Food"),
            ),
          ],
        ),
      ),
    );
  }
}