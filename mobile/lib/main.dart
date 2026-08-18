import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  runApp(const SmartEVApp());
}

class SmartEVApp extends StatefulWidget {
  const SmartEVApp({super.key});

  @override
  State<SmartEVApp> createState() => _SmartEVAppState();
}

class _SmartEVAppState extends State<SmartEVApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final token = await AuthService.getToken();
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF121212),
          body: Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Smart EV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.greenAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: _isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentCenter = const LatLng(
    19.1136,
    72.8697,
  ); // Andheri area approx (Fallback)
  bool _isListening = false;
  bool _isEmergency = false;
  int _countdown = 9;

  final Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _activeDestination;

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  String _spokenText = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission;

    // 1. Ask for permission first!
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return; // Fallback to Andheri
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return; // Fallback to Andheri
    }

    // 2. Once we have permission, check if GPS is actually turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS is off. Prompt user to turn it on by opening settings!
      await Geolocator.openLocationSettings();

      // We can try to get the position anyway, but it might fail or use cached.
      // We'll let it proceed, but if it throws, we catch it.
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCenter, 15.0),
      );
    } catch (e) {
      // If it fails (e.g. they didn't turn on GPS in time), just fallback gracefully
      debugPrint("Could not get location: $e");
    }
  }

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('station_1'),
      position: LatLng(19.1150, 72.8700),
      infoWindow: InfoWindow(
        title: 'Station A',
        snippet: '2 Fast Chargers Available',
      ),
    ),
    const Marker(
      markerId: MarkerId('station_2'),
      position: LatLng(19.1120, 72.8680),
      infoWindow: InfoWindow(
        title: 'Station B',
        snippet: '1 Fast Charger Available',
      ),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _getDirections(LatLng destination) async {
    String apiKey = "AIzaSyAbeI-P_j1sXfgOomAH6tMGUbwuW5OwwPs";
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${_currentCenter.latitude},${_currentCenter.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPoly = data['routes'][0]['overview_polyline']['points'];
          List<PointLatLng> points = polylinePoints.decodePolyline(encodedPoly);

          List<LatLng> polylineCoordinates = points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          Polyline polyline = Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.greenAccent,
            width: 5,
            points: polylineCoordinates,
          );

          setState(() {
            _polylines.add(polyline);
            _activeDestination = destination;
          });
          _startTracking();
        }
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (_activeDestination == null) return;

          setState(() {
            _currentCenter = LatLng(position.latitude, position.longitude);
          });

          // Keep map centered on user
          mapController.animateCamera(CameraUpdate.newLatLng(_currentCenter));

          // Check distance
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _activeDestination!.latitude,
            _activeDestination!.longitude,
          );

          if (distance < 50) {
            // Within 50 meters
            _positionStreamSubscription?.cancel();
            setState(() {
              _polylines.clear();
              _activeDestination = null;
            });
            _flutterTts.speak("You have arrived at your charging station.");
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Location Reached! Charger is ready.",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _spokenText = val.recognizedWords;
          }),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI Assistant Listening...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission denied.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_spokenText.isNotEmpty) {
        _sendToAI(_spokenText);
      }
    }
  }

  void _sendToAI(String text) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thinking...',
          style: TextStyle(color: Colors.tealAccent),
        ),
      ),
    );
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://evchargerloc.onrender.com/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': text}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final reply = jsonResponse['response'];
        await _flutterTts.speak(reply);

        // Demo trigger route if AI says booking is confirmed
        if (reply.toLowerCase().contains("booked") ||
            reply.toLowerCase().contains("confirmed")) {
          _getDirections(
            const LatLng(19.1150, 72.8700),
          ); // Demo destination Station A
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI: $reply',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        );
      } else {
        await _flutterTts.speak("Sorry, I could not connect to the server.");
      }
    } catch (e) {
      await _flutterTts.speak("Network error occurred.");
    }
  }

  void _triggerSOS() {
    setState(() {
      _isEmergency = true;
      _countdown = 9;
    });

    _simulateCountdown();
  }

  void _simulateCountdown() async {
    for (int i = 8; i >= 0; i--) {
      if (!_isEmergency) break;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. The Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 15.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Top Bar (Logo & SOS)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electric_car, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Smart EV',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'sos_btn',
                  onPressed: _triggerSOS,
                  backgroundColor: Colors.redAccent,
                  mini: true,
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
              ],
            ),
          ),

          // 3. Emergency Overlay
          if (_isEmergency)
            Container(
              color: Colors.redAccent.withValues(alpha: 0.95),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Possible accident detected.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isEmergency = false;
                        });
                      },
                      child: const Text(
                        'I AM SAFE - CANCEL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Voice Assistant Bottom Bar
          if (!_isEmergency)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isListening ? 100 : 80,
                    width: _isListening ? 100 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.black : Colors.black87,
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.8)
                              : Colors.greenAccent.withValues(alpha: 0.6),
                          blurRadius: _isListening ? 40 : 20,
                          spreadRadius: _isListening ? 15 : 5,
                        ),
                      ],
                      border: Border.all(
                        color: _isListening
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const MapScreen(), const BookingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {
        "station": "MobiLane Equinox Business Park",
        "power": "15 kWh CCS2",
        "status": "Confirmed",
        "time": "Today, 4:00 PM",
      },
      {
        "station": "Tata Power Receiving Station",
        "power": "50 kWh CHAdeMO",
        "status": "Completed",
        "time": "Yesterday, 2:30 PM",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b["station"]!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.ev_station,
                        color: Colors.tealAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b["power"]!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b["time"]!,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: b["status"] == "Confirmed"
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b["status"]!,
                          style: TextStyle(
                            color: b["status"] == "Confirmed"
                                ? Colors.greenAccent
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
