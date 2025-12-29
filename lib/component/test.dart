// lib/component/test.dart
import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  final String? firedAt;

  const TestScreen({Key? key, this.firedAt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Notification Test Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Opened via notification',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            if (firedAt != null && firedAt!.isNotEmpty)
              Column(
                children: [
                  const Text('Notification fired at:'),
                  Text(
                    firedAt!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}