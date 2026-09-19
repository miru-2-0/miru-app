import 'package:flutter/material.dart';

class ExtensionScreen extends StatelessWidget {
  const ExtensionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扩展'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '扩展内容',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
