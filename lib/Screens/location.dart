import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationScreen extends StatefulWidget{
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
   final TextEditingController _controller = TextEditingController();
  MapController _mapController = MapController();
  LatLng _currentLatLng = LatLng(17.3850, 78.4867); // Default to Hyderabad

  void _searchLocation() async {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${_controller.text}&format=json&addressdetails=1&limit=1'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data.isNotEmpty) {
        double lat = double.parse(data[0]['lat']);
        double lon = double.parse(data[0]['lon']);
        setState(() {
          _currentLatLng = LatLng(lat, lon);
        });
        _mapController.move(_currentLatLng, 15.0);
      }
    }
  }
   void      _openInGoogleMaps() async {
     final lat = _currentLatLng.latitude;
     final lon = _currentLatLng.longitude;

     final Uri googleMapsUrl = Uri.parse("geo:$lat,$lon?q=$lat,$lon");

     if (await canLaunchUrl(googleMapsUrl)) {
       await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
     } else {
       final fallbackUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
       if (await canLaunchUrl(fallbackUrl)) {
         await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text("Could not open map."),
         ));
       }
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search location',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLatLng,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(

                        width: 80.0,
                        height: 80.0,
                        point: _currentLatLng,
                        child:  Container(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              children: [

              ],
            ),
            ElevatedButton(
              onPressed: _searchLocation,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(String location) {
    return GestureDetector(
      onTap: () {
        _controller.text = location;
        _searchLocation();
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.grey[300],
        child: Text(location),
      ),
    );
  }
}