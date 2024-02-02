import 'dart:async';
import 'package:flutter/material.dart';
import 'package:garbage_collecting_system/services/myLocation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => MapSampleState();
}

class MapSampleState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LatLng destination = const LatLng(8.650414,81.211639);

  double distance = 0.0;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
      ),
    ]);
  }

  Future<void> _sendNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'Distance Alert',
        body: 'You are within 1000 meters of your destination!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: ApiService.determinePosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }
          Position position = snapshot.data!;

          // Calculate distance between current location and destination
          distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destination.latitude,
            destination.longitude,
          );

          if (distance <= 1000) {
            _sendNotification();
          }

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 13.5,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("my location"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: LatLng(position.latitude, position.longitude),
                    ),
                    Marker(
                      markerId: const MarkerId("my location"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueMagenta,
                      ),
                      position: destination,
                    )
                  },
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Distance to destination: ${distance.toStringAsFixed(2)} meters',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
