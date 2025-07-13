import 'package:flutter/material.dart';

class PublisherPublicationsPage extends StatelessWidget {
  const PublisherPublicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 22, 36, 62),
        foregroundColor: Colors.white,
        title: const Text("Publicaciones propias"),
      ),
    );
  }
}