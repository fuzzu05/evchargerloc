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

import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/screens/bookings_screen.dart';
import 'package:mobile/screens/voice_assistant_overlay.dart';
import 'package:mobile/screens/route_results_screen.dart';
import 'package:mobile/screens/slot_booking_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/models/station.dart';
import 'package:mobile/services/station_service.dart';

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
        primaryColor: const Color(0xFF00FF88),
        scaffoldBackgroundColor: const Color(0xFF090A0C),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF7A9BFF),
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
  final Function(bool)? onNavigatingChange;

  const MapScreen({super.key, this.onNavigatingChange});

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
  String _aiResponseText = '';

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

  String _navEta = '';
  String _navTotalDistance = '';

  // Arrival & charging
  bool _showScanButton = false;
  bool _isChargingActive = false;

  // Weather
  String? _weatherWarning;

  // Live Stations
  List<ChargingStation> _stations = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-IN');
    _flutterTts.setSpeechRate(0.45);
    _requestPermissionsAndInit();
    _fetchLiveStations();
  }

  Future<void> _fetchLiveStations() async {
    try {
      final stations = await StationService.getStations();
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _markers = stations
            .map(
              (s) => Marker(
                markerId: MarkerId(s.id),
                position: LatLng(s.latitude, s.longitude),
                infoWindow: InfoWindow(
                  title: s.name,
                  snippet: '₹${s.pricePerKwh}/kWh • ${s.gridPower}',
                ),
              ),
            )
            .toSet();
      });
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    }
  }

  Future<void> _requestPermissionsAndInit() async {
    await [
      Permission.location,
      Permission.microphone,
      Permission.camera,
    ].request();

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
          color: const Color(0xFF00FF88),
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

    widget.onNavigatingChange?.call(true);

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

          if (_currentStepIndex < _steps.length) {
            final step = _steps[_currentStepIndex];
            final distToStepEnd = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              step.endLocation.latitude,
              step.endLocation.longitude,
            );

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
      _showScanButton = true;
    });

    widget.onNavigatingChange?.call(false);

    if (!_isMuted) {
      await _flutterTts.speak(
        'You have arrived at your charging station. Tap the scan button to begin charging.',
      );
    }
  }

  void _cancelNavigation() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _polylines.clear();
      _activeDestination = null;
      _isNavigating = false;
      _steps = [];
      _currentStepIndex = 0;

      _weatherWarning = null;
    });

    widget.onNavigatingChange?.call(false);

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

  // Accessed by MainScreen via GlobalKey to open the overlay
  void _openVoiceOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateOverlay) {
            return VoiceAssistantOverlay(
              isListening: _isListening,
              userSpokenText: _spokenText,
              aiResponseText: _aiResponseText,
              onToggleListening: () async {
                if (!_isListening) {
                  bool available = await _speech.initialize(
                    onStatus: (val) => debugPrint('stt status: $val'),
                    onError: (val) => debugPrint('stt error: $val'),
                  );
                  if (available) {
                    setState(() => _isListening = true);
                    setStateOverlay(() => _isListening = true);
                    _speech.listen(
                      onResult: (val) {
                        setState(() => _spokenText = val.recognizedWords);
                        setStateOverlay(
                          () => _spokenText = val.recognizedWords,
                        );
                      },
                    );
                  }
                } else {
                  setState(() => _isListening = false);
                  setStateOverlay(() => _isListening = false);
                  _speech.stop();
                  if (_spokenText.isNotEmpty) {
                    _sendToAI(_spokenText, setStateOverlay);
                  }
                }
              },
            );
          },
        );
      },
    ).then((_) {
      // When closed, stop listening if active
      if (_isListening) {
        setState(() => _isListening = false);
        _speech.stop();
      }
    });
  }

  Future<void> _sendToAI(String text, StateSetter setStateOverlay) async {
    setState(() => _aiResponseText = '🤔 Thinking...');
    setStateOverlay(() => _aiResponseText = '🤔 Thinking...');

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

        setState(() => _aiResponseText = reply);
        setStateOverlay(() => _aiResponseText = reply);

        if (!_isMuted) await _flutterTts.speak(reply);

        final lower = reply.toLowerCase();

        if (lower.contains('navigating to') ||
            lower.contains('routing to') ||
            lower.contains('starting navigation')) {
          _getDirections(const LatLng(19.1150, 72.8700)); // Station A
        }

        if (lower.contains('scan') || lower.contains('qr code')) {
          if (!mounted) return;
          Navigator.pop(context); // Close overlay first
          if (mounted) _openQrScanner();
        }

        if ((lower.contains('emergency') || lower.contains('sos')) &&
            !_isEmergency) {
          if (!mounted) return;
          Navigator.pop(context); // Close overlay
          _triggerSOS();
        }

        if (lower.contains('cancel route') ||
            lower.contains('stop navigation') ||
            lower.contains('cancel navigation')) {
          _cancelNavigation();
        }
      } else {
        setState(
          () => _aiResponseText = 'Sorry, I could not connect to the server.',
        );
        setStateOverlay(
          () => _aiResponseText = 'Sorry, I could not connect to the server.',
        );
        await _flutterTts.speak('Sorry, I could not connect to the server.');
      }
    } catch (e) {
      setState(
        () => _aiResponseText = 'Network error occurred. Please try again.',
      );
      setStateOverlay(
        () => _aiResponseText = 'Network error occurred. Please try again.',
      );
      await _flutterTts.speak('Network error occurred. Please try again.');
    }
  }

  // ── QR Scanner ────────────────────────────────────────────

  void _openQrScanner() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF14161C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Camera Permission Needed',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
            content: Text(
              'We need camera access so you can scan the QR code.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                child: Text(
                  'Open Settings',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00FF88),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    if (!mounted) return;
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
      backgroundColor: const Color(0xFF090A0C),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 1. Google Map Card ──────────────────────────
            Positioned(
              top: _isNavigating ? 0 : 80,
              bottom: _isNavigating
                  ? 0
                  : 220, // Leaves space for bottom sheet UI
              left: _isNavigating ? 0 : 16,
              right: _isNavigating ? 0 : 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isNavigating ? 0 : 24),
                child: GoogleMap(
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
              ),
            ),

            // ── 2. Top Header (Volt Style) ──────────────────
            if (!_isNavigating)
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Equinox\nBusiness Park',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        // Battery pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14161C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.battery_charging_full,
                                color: Color(0xFF00FF88),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '42%',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // SOS
                        GestureDetector(
                          onTap: _triggerSOS,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sos,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── 3. Bottom List (Nearby Chargers Mock) ────────
            if (!_isNavigating && !_isEmergency && !_isChargingActive)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Nearby chargers',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: _stations.isEmpty
                          ? Center(
                              child: Text(
                                'No stations found nearby.',
                                style: GoogleFonts.inter(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _stations.length,
                              itemBuilder: (ctx, idx) {
                                final s = _stations[idx];
                                return _buildChargerCard(
                                  title: s.name,
                                  price: '₹${s.pricePerKwh}/kWh',
                                  type: s.gridPower,
                                  dist: '1.2 km', // Mock distance for now
                                  context: context,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SlotBookingScreen(station: s),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

            // ── 4. Navigation Overlay ────────────────────────
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
                onShowRouteInfo: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RouteResultsScreen(),
                    ),
                  );
                },
              ),

            // ── 5. Weather Warning Banner ────────────────────
            if (_weatherWarning != null && !_isEmergency)
              Positioned(
                top: _isNavigating ? null : 100,
                bottom: _isNavigating ? 120 : null,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Color(0xFF090A0C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _weatherWarning!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF090A0C),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _weatherWarning = null),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF090A0C),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── 6. Emergency Overlay ─────────────────────────
            if (_isEmergency)
              Container(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Emergency Detected!',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sending location via SMS in...',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$_countdown',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF6B6B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => setState(() => _isEmergency = false),
                        child: Text(
                          'I AM SAFE — CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── 7. Scan To Charge Overlay ────────────────────
            if (_showScanButton && !_isChargingActive && !_isEmergency)
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: const Color(0xFF090A0C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(
                    'Scan to Start Charging',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _openQrScanner,
                ),
              ),

            if (_isChargingActive && !_isEmergency)
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14161C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFF00FF88),
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Charging Active',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00FF88),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Session in progress...',
                              style: GoogleFonts.inter(
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
                          color: Color(0xFFFF6B6B),
                          size: 32,
                        ),
                        onPressed: () =>
                            setState(() => _isChargingActive = false),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargerCard({
    required String title,
    required String price,
    required String type,
    required String dist,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14161C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF00FF88),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF7A9BFF),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  dist,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  bool _isMapNavigating = false;
  final GlobalKey<_MapScreenState> _mapKey = GlobalKey<_MapScreenState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MapScreen(
        key: _mapKey,
        onNavigatingChange: (isNavigating) {
          setState(() {
            _isMapNavigating = isNavigating;
            if (isNavigating) {
              _currentIndex = 0; // Switch to Map screen when navigating
            }
          });
        },
      ),
      const BookingsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Voice Tab triggers overlay
      if (_mapKey.currentState != null) {
        _mapKey.currentState!._openVoiceOverlay();
      }
    } else {
      int actualIndex = index;
      if (index > 1) {
        actualIndex = index - 1; // Map index to _screens
      }
      setState(() => _currentIndex = actualIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _isMapNavigating
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex >= 1
                    ? _currentIndex + 1
                    : _currentIndex,
                onTap: _onItemTapped,
                backgroundColor: const Color(0xFF090A0C),
                selectedItemColor: const Color(0xFF00FF88),
                unselectedItemColor: Colors.white54,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    activeIcon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.mic_none),
                    label: 'Voice',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt),
                    label: 'Bookings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
    );
  }
}
