import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:garbage_collecting_system/services/myLocation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final token;
  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => MapSampleState();
}

class MapSampleState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LatLng? destination;
  LatLng? previousDestination;
  Position? position;
  double distance = 0.0;
  late Timer timer;

  Future<LatLng?> getLatLng() async {
    var response = await http.post(
      Uri.parse("http://192.168.8.111:3000/vehical/get"),
      headers: {"Content-type": "application/json"},
    );
    var jsonResponse = jsonDecode(response.body);
    print('responce body $jsonResponse');
    if (jsonResponse['status'] == true) {
      var data = jsonResponse['data'][0];
      var vehicalLat = double.parse(data['lat']);
      var vehicalLng = double.parse(data['lan']);
      destination = LatLng(vehicalLat, vehicalLng);
      print('destination $destination');
    }

    return destination;
  }

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

    // Initialize the timer
    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      print('Timer callback executed');
      if (mounted) {
        getLatLng().then((value) {
          setState(() {
            destination = value;
            print("Updated dest ${destination?.latitude}");

            if (destination != null && position != null) {
              // Check if the destination has changed
              if (destination != previousDestination) {
                distance = Geolocator.distanceBetween(
                  position!.latitude,
                  position!.longitude,
                  destination!.latitude,
                  destination!.longitude,
                );

                // Check if the distance is less than or equal to 1000 meters
                if (distance <= 1000) {
                  print(
                      'Distance is less than or equal to 1000 meters. Sending notification.');
                  _sendNotification();
                } else {
                  print('Distance is greater than 1000 meters.');
                }

                // Update the previous destination
                previousDestination = destination;
              }
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'Distance Alert',
        body: 'Garbage Truck within 1 KM of your Location!',
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

          position =
              snapshot.data as Position; // Update the class-level variable

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(position!.latitude, position!.longitude),
                    zoom: 15.5,
                  ),
                  markers: destination != null
                      ? {
                          Marker(
                            markerId: const MarkerId("my location"),
                            icon: BitmapDescriptor.defaultMarker,
                            position:
                                LatLng(position!.latitude, position!.longitude),
                          ),
                          Marker(
                            markerId: const MarkerId("destination"),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueMagenta,
                            ),
                            infoWindow:
                                const InfoWindow(title: "Garbage Truck"),
                            position: LatLng(
                                destination!.latitude, destination!.longitude),
                          )
                        }
                      : {
                          Marker(
                            markerId: const MarkerId("my location"),
                            icon: BitmapDescriptor.defaultMarker,
                            position:
                                LatLng(position!.latitude, position!.longitude),
                          ),
                        },
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
