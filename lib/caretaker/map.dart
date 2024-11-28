import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:projects/utils/locationPermission.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:projects/utils/globals.dart' as Globals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../provider/UserProvider.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage> {
  @override
  bool get wantKeepAlive => true; // Keeps the state alive

  List<dynamic>? tours;
  double latitude = 0.0;
  double longitude = 0.0;
  double _bearing = 1.0;
  double activePatientLatitude = 0.0;
  double activePaitentLongitude = 0.0;
  double activePatientRadius = 0.0;
  double centerLatitude = 0.0;
  double centerLongitude = 0.0;
  bool _locationFetched = false;
  double scale = 1.0;
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _addMapEventListener();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await getCurrentPosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      _locationFetched = true;
    });
    print('Current location: $latitude, $longitude');
    final baseURL = Globals.baseURL;
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    final patient = patientProvider.selectedPatient;

    if (patient == null) {
      print("No patient selected");
      return;
    }
    // url to get patient location patient/<int:patient_id>/location/
    final response = await http.get(
      Uri.parse('$baseURL/api/users/patient/${patient.id}/location/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        activePatientLatitude = data['current_coordinates_lat'];
        activePaitentLongitude = data['current_coordinates_long'];
        activePatientRadius = data['radius'];
        centerLatitude = data['center_coordinates_lat'];
        centerLongitude = data['center_coordinates_long'];
      });
    } else {
      // Handle error
      Logger().e('Failed to fetch patient location');
    }
    print(
        'Active patient location: $activePatientLatitude, $activePaitentLongitude');
  }

  // Listener to detect map movements and changes
  void _addMapEventListener() {
    mapController.mapEventStream.listen((event) {
      setState(() {
        if (event is MapEventRotate) {
          _bearing = mapController.camera.rotation;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    final patient = patientProvider.selectedPatient;

    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          if (_locationFetched)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiYWJoaXlhbjEyMTIiLCJhIjoiY20zNnQwNWJnMGFsbzJqc2wxMTh2a2JjaCJ9.QY9Xj_GfNoO9yu9nkiMb1g',
                  userAgentPackageName: 'com.example.app',
                ),
                Positioned(
                  top: 70,
                  right: 20,
                  child: GestureDetector(
                      onTap: () {
                        // Handle on tap action here
                        mapController.rotate(0);
                      },
                      child: CompassWidget(
                        bearing: _bearing,
                      )),
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      mapController.move(LatLng(latitude, longitude),
                          mapController.camera.zoom);
                    },
                    child: Icon(Icons.my_location),
                  ),
                ),
                CurrentLocationLayer(),
                if (patient != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                          points: [
                            LatLng(
                                activePatientLatitude, activePaitentLongitude),
                            LatLng(centerLatitude, centerLongitude),
                          ],
                          color: Colors.red,
                          strokeWidth: 3.0,
                          strokeCap: StrokeCap.round,
                          pattern: StrokePattern.dotted()),
                    ],
                  ),
                if (patient != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(centerLatitude, centerLongitude),
                        color: Colors.red.withOpacity(0.3),
                        borderStrokeWidth: 2,
                        useRadiusInMeter: true,
                        borderColor: Colors.red,
                        radius:
                            activePatientRadius * 1000, // Convert km to meters
                      ),
                    ],
                  ),
                if (patient != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50.0,
                        height: 50.0,
                        point: LatLng(
                            activePatientLatitude, activePaitentLongitude),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 3.0,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: patient.photo.isNotEmpty
                                    ? NetworkImage(patient.photo)
                                    : AssetImage(
                                            'assets/images/default_avatar.png')
                                        as ImageProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: LatLng(centerLatitude, centerLongitude),
                        child: Icon(
                          Icons.home,
                          color: const Color.fromARGB(255, 243, 33, 33),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            )
          else
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class CompassWidget extends StatelessWidget {
  final double bearing;

  const CompassWidget({super.key, required this.bearing});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearing * (3.14159265359 / 180), // Convert bearing to radians
      child: const Icon(Icons.navigation,
          color: Color.fromARGB(255, 172, 38, 40), size: 50.0),
    );
  }
}
