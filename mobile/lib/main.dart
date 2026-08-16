import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SmartEVApp());
}

class SmartEVApp extends StatelessWidget {
  const SmartEVApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const MapScreen(),
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
  final LatLng _center = const LatLng(19.1136, 72.8697); // Andheri area approx
  bool _isListening = false;
  bool _isEmergency = false;
  int _countdown = 9;

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  String _spokenText = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
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
      // TODO: Change this to your laptop's actual IPv4 address!
      final response = await http.post(
        Uri.parse('http://192.168.31.53:8081/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final reply = jsonResponse['response'];
        await _flutterTts.speak(reply);
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
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            markers: _markers,
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
