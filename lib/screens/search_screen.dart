import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              '搜索内容',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
