import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/qr_scanner_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/directions_service.dart';
import 'package:mobile/services/weather_service.dart';
import 'package:mobile/models/nav_step.dart';
import 'package:mobile/widgets/nav_overlay.dart';
import 'package:mobile/widgets/route_info_sheet.dart';

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

// ─────────────────────────────────────────────────────────────
// MAP SCREEN
// ─────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Location
  LatLng _currentCenter = const LatLng(19.1136, 72.8697); // Andheri fallback

  // Voice assistant
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _spokenText = '';

  // Emergency
  bool _isEmergency = false;
  int _countdown = 9;

  // Navigation
  final Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _activeDestination;
  List<NavStep> _steps = [];
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _isMuted = false;
  bool _ttsAnnouncedForCurrentStep = false;
  bool _showRouteInfo = false;
  String _navEta = '';
  String _navTotalDistance = '';

  // Arrival & charging
  bool _showScanButton = false;
  bool _isChargingActive = false;

  // Weather
  String? _weatherWarning;

  // Static demo markers
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('station_1'),
      position: LatLng(19.1150, 72.8700),
      infoWindow: InfoWindow(
        title: 'Station A — MobiLane',
        snippet: '2 Fast Chargers • CCS2 Available',
      ),
    ),
    const Marker(
      markerId: MarkerId('station_2'),
      position: LatLng(19.1120, 72.8680),
      infoWindow: InfoWindow(
        title: 'Station B — Tata Power',
        snippet: '1 Fast Charger • CHAdeMO Available',
      ),
    ),
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-IN');
    _flutterTts.setSpeechRate(0.45);
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────

  Future<void> _determinePosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) await Geolocator.openLocationSettings();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentCenter, 15.0),
      );
    } catch (e) {
      debugPrint('Could not get location: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // ── Navigation ────────────────────────────────────────────

  Future<void> _getDirections(LatLng destination) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Calculating route...',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Fetch weather at destination in parallel
    _checkWeatherAtDestination(destination);

    final result = await DirectionsService.getDirections(
      _currentCenter,
      destination,
    );
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not calculate route. Check your internet connection.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.greenAccent,
          width: 6,
          points: result.polylinePoints,
        ),
      );
      _steps = result.steps;
      _currentStepIndex = 0;
      _activeDestination = destination;
      _navEta = result.totalDuration;
      _navTotalDistance = result.totalDistance;
      _isNavigating = true;
      _ttsAnnouncedForCurrentStep = false;
      _showScanButton = false;
      _isChargingActive = false;
    });

    _startTracking();

    if (!_isMuted && _steps.isNotEmpty) {
      await _flutterTts.speak(
        'Route found. ${result.totalDuration}, ${result.totalDistance}. '
        '${_steps[0].instruction}.',
      );
    }
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        ).listen((Position position) async {
          if (!mounted) return;
          setState(() {
            _currentCenter = LatLng(position.latitude, position.longitude);
          });
          mapController.animateCamera(CameraUpdate.newLatLng(_currentCenter));

          if (_activeDestination == null || _steps.isEmpty) return;

          // Check arrival at final destination
          final distToDest = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _activeDestination!.latitude,
            _activeDestination!.longitude,
          );
          if (distToDest < 50) {
            _onArrived();
            return;
          }

          // Check current step proximity
          if (_currentStepIndex < _steps.length) {
            final step = _steps[_currentStepIndex];
            final distToStepEnd = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              step.endLocation.latitude,
              step.endLocation.longitude,
            );

            // Announce next step when within 80m (pre-turn announcement)
            if (distToStepEnd < 80 && !_ttsAnnouncedForCurrentStep) {
              setState(() => _ttsAnnouncedForCurrentStep = true);
              final nextInstruction = _currentStepIndex + 1 < _steps.length
                  ? _steps[_currentStepIndex + 1].instruction
                  : 'Arrive at destination';
              if (!_isMuted) {
                await _flutterTts.speak(
                  'In ${step.formattedDistance}, $nextInstruction.',
                );
              }
            }

            // Advance to next step when within 20m
            if (distToStepEnd < 20) {
              setState(() {
                _currentStepIndex = (_currentStepIndex + 1).clamp(
                  0,
                  _steps.length - 1,
                );
                _ttsAnnouncedForCurrentStep = false;
              });
            }
          }
        });
  }

  Future<void> _onArrived() async {
    _positionStreamSubscription?.cancel();
    setState(() {
      _polylines.clear();
      _activeDestination = null;
      _isNavigating = false;
      _steps = [];
      _currentStepIndex = 0;
      _showScanButton = true; // Show "Scan to Charge" button
    });
    if (!_isMuted) {
      await _flutterTts.speak(
        'You have arrived at your charging station. Tap the scan button to begin charging.',
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '📍 Arrived! Tap "Scan to Charge" to start your session.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _cancelNavigation() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _polylines.clear();
      _activeDestination = null;
      _isNavigating = false;
      _steps = [];
      _currentStepIndex = 0;
      _showRouteInfo = false;
      _weatherWarning = null;
    });
    _flutterTts.stop();
  }

  // ── Weather ───────────────────────────────────────────────

  Future<void> _checkWeatherAtDestination(LatLng destination) async {
    final warning = await WeatherService.getWeatherWarning(
      destination.latitude,
      destination.longitude,
    );
    if (!mounted) return;
    if (warning != null) {
      setState(() => _weatherWarning = warning);
      if (!_isMuted) await _flutterTts.speak(warning);
    }
  }

  // ── Voice AI ──────────────────────────────────────────────

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('stt status: $val'),
        onError: (val) => debugPrint('stt error: $val'),
      );
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _spokenText = val.recognizedWords;
          }),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission denied.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_spokenText.isNotEmpty) {
        _sendToAI(_spokenText);
        setState(() => _spokenText = '');
      }
    }
  }

  Future<void> _sendToAI(String text) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🤔 Thinking...',
          style: TextStyle(color: Colors.tealAccent),
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Enrich message with GPS context
    final navContext = _isNavigating && _steps.isNotEmpty
        ? ' Currently navigating — ETA: $_navEta, $_navTotalDistance remaining, next turn: ${_steps[_currentStepIndex].instruction}.'
        : '';
    final enrichedMessage =
        'User location: ${_currentCenter.latitude.toStringAsFixed(5)}°N, '
        '${_currentCenter.longitude.toStringAsFixed(5)}°E.$navContext\n'
        'User said: $text';

    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://evchargerloc.onrender.com/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': enrichedMessage}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final reply = jsonResponse['response'] as String;

        if (!_isMuted) await _flutterTts.speak(reply);

        // ── Keyword-triggered actions ──
        final lower = reply.toLowerCase();

        if (lower.contains('navigating to') ||
            lower.contains('routing to') ||
            lower.contains('starting navigation')) {
          _getDirections(const LatLng(19.1150, 72.8700)); // Station A
        }

        if (lower.contains('scan') || lower.contains('qr code')) {
          if (mounted) _openQrScanner();
        }

        if ((lower.contains('emergency') || lower.contains('sos')) &&
            !_isEmergency) {
          _triggerSOS();
        }

        if (lower.contains('cancel route') ||
            lower.contains('stop navigation') ||
            lower.contains('cancel navigation')) {
          _cancelNavigation();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🤖 $reply',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        await _flutterTts.speak('Sorry, I could not connect to the server.');
      }
    } catch (e) {
      await _flutterTts.speak('Network error occurred. Please try again.');
    }
  }

  // ── QR Scanner ────────────────────────────────────────────

  void _openQrScanner() async {
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted) return;
    if (confirmed == true) {
      setState(() {
        _showScanButton = false;
        _isChargingActive = true;
      });
      if (!_isMuted) {
        await _flutterTts.speak(
          'Charging started! Your session has begun. Enjoy your charge!',
        );
      }
    }
  }

  // ── Emergency / SOS ───────────────────────────────────────

  void _triggerSOS() {
    setState(() {
      _isEmergency = true;
      _countdown = 9;
    });
    _runCountdown();
  }

  void _runCountdown() async {
    for (int i = 8; i >= 0; i--) {
      if (!_isEmergency) break;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i);
    }
    if (_isEmergency && mounted) {
      _launchEmergencySms();
    }
  }

  Future<void> _launchEmergencySms() async {
    final lat = _currentCenter.latitude.toStringAsFixed(6);
    final lng = _currentCenter.longitude.toStringAsFixed(6);
    final body = Uri.encodeComponent(
      'EMERGENCY: I need help! My location: https://maps.google.com/?q=$lat,$lng',
    );
    final uri = Uri.parse('sms:?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
    if (mounted) setState(() => _isEmergency = false);
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 1. Google Map ──────────────────────────
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

          // ── 2. Navigation Overlay (replaces top bar) ──
          if (_isNavigating && _steps.isNotEmpty)
            NavOverlay(
              currentStep: _steps[_currentStepIndex],
              stepIndex: _currentStepIndex,
              totalSteps: _steps.length,
              eta: _navEta,
              totalDistance: _navTotalDistance,
              isMuted: _isMuted,
              onMuteToggle: () => setState(() => _isMuted = !_isMuted),
              onCancelRoute: _cancelNavigation,
              onShowRouteInfo: () => setState(() => _showRouteInfo = true),
            ),

          // ── 3. Default Top Bar (when NOT navigating) ──
          if (!_isNavigating)
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
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.electric_car, color: Colors.greenAccent),
                        SizedBox(width: 8),
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

          // ── 4. Weather Warning Banner ──────────────
          if (_weatherWarning != null && !_isEmergency)
            Positioned(
              top: _isNavigating ? null : 120,
              bottom: _isNavigating ? 120 : null,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _weatherWarning!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _weatherWarning = null),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 5. Charging Active Badge ───────────────
          if (_isChargingActive && !_isEmergency)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.greenAccent, size: 30),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ Charging Active',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Session in progress...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.redAccent,
                      ),
                      onPressed: () =>
                          setState(() => _isChargingActive = false),
                    ),
                  ],
                ),
              ),
            ),

          // ── 6. Emergency Overlay ───────────────────
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
                      'Emergency Detected!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sending location via SMS in...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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
                      onPressed: () => setState(() => _isEmergency = false),
                      child: const Text(
                        'I AM SAFE — CANCEL',
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

          // ── 7. Voice Assistant Button ──────────────
          if (!_isEmergency)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Scan to Charge button (shown on arrival)
                  if (_showScanButton && !_isChargingActive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(
                          'Scan to Start Charging',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _openQrScanner,
                      ),
                    ),

                  // Navigate to demo station (shown when not navigating)
                  if (!_isNavigating && !_showScanButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.greenAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.navigation, size: 20),
                        label: const Text('Navigate to Nearest Station'),
                        onPressed: () =>
                            _getDirections(const LatLng(19.1150, 72.8700)),
                      ),
                    ),

                  // Mic button
                  GestureDetector(
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
                ],
              ),
            ),

          // ── 8. Route Info Bottom Sheet ─────────────
          if (_showRouteInfo && _steps.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return RouteInfoSheet(
                  steps: _steps,
                  currentStepIndex: _currentStepIndex,
                  totalDuration: _navEta,
                  totalDistance: _navTotalDistance,
                  onClose: () => setState(() => _showRouteInfo = false),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN (Bottom Nav)
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// BOOKINGS SCREEN (Static demo — do not touch per user request)
// ─────────────────────────────────────────────────────────────

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {
        'station': 'MobiLane Equinox Business Park',
        'power': '15 kWh CCS2',
        'status': 'Confirmed',
        'time': 'Today, 4:00 PM',
      },
      {
        'station': 'Tata Power Receiving Station',
        'power': '50 kWh CHAdeMO',
        'status': 'Completed',
        'time': 'Yesterday, 2:30 PM',
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
                    b['station']!,
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
                        b['power']!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b['time']!,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: b['status'] == 'Confirmed'
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b['status']!,
                          style: TextStyle(
                            color: b['status'] == 'Confirmed'
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
