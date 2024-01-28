import 'package:flutter/material.dart';
import 'package:garbage_collecting_system/services/gps_Services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: GpsServices.determinePosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }
          Position position = snapshot.data!;
          print("${position.latitude} lat  , ${position.longitude} lomg");
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14.5,
            ),
            markers: {
              Marker(
                  markerId: const MarkerId("My Location"),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(
                    onTap: () => const Text("My Location"),
                  ))
            },
          );
        },
      ),
    );
  }
}
