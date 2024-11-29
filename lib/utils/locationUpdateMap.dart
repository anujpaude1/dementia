import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/utils/globals.dart' as Globals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:projects/model/models.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';

class UpdateHomePage extends StatefulWidget {
  final Patient patient; // Receive the patient object

  UpdateHomePage({required this.patient});

  @override
  _UpdateHomePageState createState() => _UpdateHomePageState();
}

class _UpdateHomePageState extends State<UpdateHomePage>
    with TickerProviderStateMixin {
  // Map and location state
  late LatLng centerLocation;
  late double radius;

  // Controllers for input fields
  final TextEditingController placeController = TextEditingController();
  final TextEditingController radiusController = TextEditingController();

  // Mapbox Access Token
  final String mapboxAccessToken =
      'pk.eyJ1IjoiYWJoaXlhbjEyMTIiLCJhIjoiY20zNnQwNWJnMGFsbzJqc2wxMTh2a2JjaCJ9.QY9Xj_GfNoO9yu9nkiMb1g';

  @override
  void initState() {
    super.initState();
    centerLocation = LatLng(widget.patient.centerCoordinatesLat ?? 0.0,
        widget.patient.centerCoordinatesLong ?? 0.0);
    radius = widget.patient.radius;
    radiusController.text = radius.toString();
  }

  // Function to search for a place using the Mapbox Geocoding API
  Future<void> searchPlace(String placeName) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$placeName.json?access_token=$mapboxAccessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0]; // Get the first result
          final List coordinates = feature['geometry']['coordinates'];

          setState(() {
            centerLocation = LatLng(coordinates[1], coordinates[0]);
          });

          // Update placeController with formatted place name
          placeController.text = feature['place_name'];

          // Fly to the new location with animation
          mapController.animatedMapMove(centerLocation, 13.0, this);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Place not found.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch location.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    }
  }

  // Function to update location via API
  Future<void> updateLocation() async {
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    patientProvider.updatePatientLocation(widget.patient.id,
        centerLocation.latitude, centerLocation.longitude, radius);
    await patientProvider.updateOnServer(widget.patient.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location updated successfully!")),
    );

    Navigator.pop(context); // Navigate back to the previous page
  }

  late MapController mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Map View
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: centerLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    centerLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken',
                  userAgentPackageName: 'com.example.app',
                ),
                DragMarkers(markers: [
                  DragMarker(
                    point: centerLocation,
                    size: const Size.square(75),
                    offset: const Offset(0, -20),
                    dragOffset: const Offset(0, -35),
                    builder: (_, __, isDragging) {
                      return Icon(
                        isDragging ? Icons.home : Icons.home,
                        color: const Color.fromARGB(255, 243, 33, 33),
                        size: 40,
                      );
                    },
                    onDragEnd: (details, point) {
                      setState(() {
                        centerLocation = point;
                      });
                    },
                  )
                ]),
              ],
            ),
          ),

          // Input Fields for Location Update
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(
                    labelText: "Search Place",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => searchPlace(placeController.text),
                    ),
                  ),
                ),
                SizedBox(
                    height: 16.0), // Add margin between search place and radius
                TextField(
                  controller: radiusController,
                  decoration: InputDecoration(labelText: "Radius (km)"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      radius = double.tryParse(value) ?? radius;
                    });
                  },
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: updateLocation,
        child: Icon(Icons.save),
      ),
    );
  }
}

extension AnimatedMapController on MapController {
  void animatedMapMove(
      LatLng destLocation, double destZoom, TickerProvider vsync) {
    final latTween = Tween<double>(
        begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    var controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: vsync);
    var animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      move(LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
