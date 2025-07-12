import 'package:flutter/material.dart';

class PublisherPublicationsPage extends StatelessWidget {
  const PublisherPublicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 225, 31, 28),
        title: const Text("Publicaciones propias"),
      ),
    );
  }
}