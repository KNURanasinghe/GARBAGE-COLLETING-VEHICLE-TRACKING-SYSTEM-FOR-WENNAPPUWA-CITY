import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GoogleMapsApiService {
  final String apiKey;

  GoogleMapsApiService(this.apiKey);

  Future<int> getDistance(LatLng origin, LatLng destination) async {
    String apiUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    String originString = '${origin.latitude},${origin.longitude}';
    String destinationString = '${destination.latitude},${destination.longitude}';

    String requestUrl =
        '$apiUrl?origins=$originString&destinations=$destinationString&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Extract the distance from the response
        int distanceInMeters = decoded['rows'][0]['elements'][0]['distance']['value'];
        return distanceInMeters;
      } else {
        throw Exception('Failed to load distance information');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

// Usage example:
// GoogleMapsApiService apiService = GoogleMapsApiService('YOUR_API_KEY');
// LatLng origin = LatLng(37.7749, -122.4194); // San Francisco
// LatLng destination = LatLng(34.0522, -118.2437); // Los Angeles
// int distance = await apiService.getDistance(origin, destination);
// print('Distance: $distance meters');
