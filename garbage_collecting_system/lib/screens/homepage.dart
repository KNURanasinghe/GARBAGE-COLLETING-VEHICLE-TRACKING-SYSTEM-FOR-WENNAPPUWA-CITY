import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:garbage_collecting_system/services/gps_Services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../services/direction_Matrix.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  GoogleMapsApiService apiService =
      GoogleMapsApiService('AIzaSyBoGERTsP5zZAxAoqquJGKQcGHimn-ybbs');

  LatLng dest = const LatLng(8.648013, 81.201729);

  List<LatLng> polilinecoordinate = [];
  LocationData? currentlocation1;
  int distance = 0;

  void getPolyPoints(Position currentPosition) async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyBoGERTsP5zZAxAoqquJGKQcGHimn-ybbs",
      PointLatLng(currentPosition.latitude, currentPosition.longitude),
      PointLatLng(dest.latitude, dest.longitude),
    );

    if (result.points.isNotEmpty) {
      for (var element in result.points) {
        polilinecoordinate.add(LatLng(element.latitude, element.longitude));
      }
    }
  }

  // This is to get the current location of the garbage truck
  void currentLocation() async {
    Location location = Location();

    location.getLocation().then((location) {
      currentlocation1 = location;
    });

    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen((event) {
      currentlocation1 = event;

      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(event.latitude!, event.longitude!)),
        ),
      );
      setState(() {});
    });
  }

  //handle local notification

  @override
  void initState() {
    currentLocation();

    super.initState();
    LocalNotification.initialize(flutterLocalNotificationsPlugin);
    // Use Future.delayed to wait for the initial build to complete
    Future.delayed(Duration.zero, () async {
      // Get the current position
      Position? position = await GpsServices.determinePosition();

      // Call getPolyPoints with the current position
      if (position != null) {
        getPolyPoints(position);
        // Get the distance between the current location and destination
        distance = await apiService.getDistance(
          LatLng(position.latitude, position.longitude),
          LatLng(dest.latitude, dest.longitude),
        );
        setState(() {
          if (distance <= 1000) {
            LocalNotification.showBigTextNotification(
                title: "The vehicle is coming!",
                body:
                    "the vehical comming zoom to your place be ready with garbage",
                fln: flutterLocalNotificationsPlugin);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Garbage Collection System",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          foregroundColor: Colors.blue,
          backgroundColor: Colors.blue,
        ),
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

            return GoogleMap(
              mapType: MapType.hybrid,
              circles: {
                Circle(
                  circleId: const CircleId("My Location"),
                  radius: 425,
                  center: LatLng(position.latitude, position.longitude),
                  strokeWidth: 2,
                  fillColor: const Color(0xFF006491).withOpacity(0.2),
                ),
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14.5,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId("routes"),
                  points: polilinecoordinate,
                  color: Colors.blue,
                  width: 6,
                )
              },
              markers: {
                Marker(
                  markerId: const MarkerId("My Location"),
                  position: LatLng(position.latitude, position.longitude),
                  icon: BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(
                    onTap: () => const Text("My Location"),
                  ),
                ),
                Marker(
                  markerId: const MarkerId("My des"),
                  position: dest,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: InfoWindow(
                    onTap: () => const Text("My destination"),
                  ),
                ),
              },
              onMapCreated: (mapController) {
                _controller.complete(mapController);
              },
            );
          },
        ),
      ),
    );
  }
}
