import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class GeoPage extends StatefulWidget {
  const GeoPage({super.key});

  @override
  State<GeoPage> createState() => _GeoPageState();
}

class _GeoPageState extends State<GeoPage> {
  String _locationMessage = 'Ubicación no obtenida';
  String? _googleMapsUrl;

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Los servicios de ubicación están desactivados.';
        _googleMapsUrl = null;
      });
      return;
    }

    // Verifica permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Permisos de ubicación denegados';
          _googleMapsUrl = null;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
            'Permisos permanentemente denegados. No se puede acceder a la ubicación.';
        _googleMapsUrl = null;
      });
      return;
    }

    // Obtiene la ubicación
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final lat = position.latitude;
    final lon = position.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';

    setState(() {
      _locationMessage = 'Latitud: $lat, Longitud: $lon';
      _googleMapsUrl = url;
    });
  }

  void _abrirEnlace() async {
    if (_googleMapsUrl != null) {
      final uri = Uri.parse(_googleMapsUrl!);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo abrir el enlace de Google Maps"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geolocalización')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_locationMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Obtener ubicación'),
            ),
            const SizedBox(height: 20),
            if (_googleMapsUrl != null)
              Column(
                children: [
                  Text(_googleMapsUrl!),
                  TextButton(
                    onPressed: _abrirEnlace,
                    child: const Text(
                      'Ver en Google Maps',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
