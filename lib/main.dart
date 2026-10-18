import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(LaserAlignmentApp());
}

class LaserAlignmentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laser Alignment Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF090D16),
        primaryColor: Color(0xFF38bdf8),
        fontFamily: 'Roboto',
      ),
      home: AlignmentHomePage(),
    );
  }
}

enum AlignmentMode { smartTarget, precisionDiagnostics }

class AlignmentHomePage extends StatefulWidget {
  @override
  _AlignmentHomePageState createState() => _AlignmentHomePageState();
}

class _AlignmentHomePageState extends State<AlignmentHomePage> {
  AlignmentMode _currentMode = AlignmentMode.smartTarget;
  
  // Flask Backend Endpoints
  final String streamUrl = "http://127.0.0.1:5000/latest_frame";
  final String telemetryUrl = "http://127.0.0.1:5000/telemetry";
  final String radiusUrl = "http://127.0.0.1:5000/set_radius";

  // Live Telemetry State Variables
  double dx = 0.0;
  double dy = 0.0;
  double distance = 0.0;
  double d4sX = 0.0;
  double d4sY = 0.0;
  double healthScore = 1.0;
  double forbiddenRadius = 27.0;

  Timer? _telemetryTimer;

  @override
  void initState() {
    super.initState();
    _startTelemetryPolling();
  }

  // Poll Flask backend for live JSON telemetry (~5 times per second)
  void _startTelemetryPolling() {
    _telemetryTimer = Timer.periodic(Duration(milliseconds: 200), (timer) async {
      try {
        final response = await http.get(Uri.parse(telemetryUrl));
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          setState(() {
            dx = (data['dx'] as num).toDouble();
            dy = (data['dy'] as num).toDouble();
            distance = (data['dist'] as num).toDouble();
            d4sX = (data['d4s_x'] as num).toDouble();
            d4sY = (data['d4s_y'] as num).toDouble();
            healthScore = (data['health_score'] as num).toDouble();
          });
        }
      } catch (e) {
        // Silently catch network blips during polling
      }
    });
  }

  // Send updated forbidden radius to Python backend
  Future<void> _updateForbiddenRadius(double val) async {
    setState(() {
      forbiddenRadius = val;
    });
    try {
      await http.post(
        Uri.parse(radiusUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"radius": val.toInt()}),
      );
    } catch (e) {
      print("Error updating radius: $e");
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF38bdf8), size: 20),
            SizedBox(width: 6),
            Text("ELI-NP // Live Telemetry HUD", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SegmentedButton<AlignmentMode>(
                segments: const [
                  ButtonSegment(
                    value: AlignmentMode.smartTarget,
                    label: Text('Target', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.gps_fixed, size: 14),
                  ),
                  ButtonSegment(
                    value: AlignmentMode.precisionDiagnostics,
                    label: Text('Advanced', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.analytics, size: 14),
                  ),
                ],
                selected: {_currentMode},
                onSelectionChanged: (Set<AlignmentMode> newSelection) {
                  setState(() {
                    _currentMode = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected) 
                        ? Color(0xFF38bdf8).withOpacity(0.2) 
                        : Color(0xFF1E293B);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentMode) {
      case AlignmentMode.smartTarget:
        return _buildSmartTargetView();
      case AlignmentMode.precisionDiagnostics:
        return _buildPrecisionDiagnosticsView();
    }
  }

  // --- VIEW 1: Simplified "Smart Target" Mode ---
  Widget _buildSmartTargetView() {
    bool isAligned = distance <= 15.0; // threshold for target acquisition

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF1E293B), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LiveCameraStreamWidget(url: streamUrl),
                
                // Targeting reticle overlay
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAligned ? Colors.greenAccent : Color(0xFF38bdf8).withOpacity(0.6),
                      width: 2.0,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned ? Colors.greenAccent : Color(0xFF38bdf8),
                  ),
                ),
                Positioned(
                  top: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "// SMART TARGET MODE",
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isAligned ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAligned ? Colors.greenAccent : Colors.amberAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAligned ? Icons.check_circle_outline : Icons.near_me,
                      color: isAligned ? Colors.greenAccent : Colors.amberAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      isAligned ? "TARGET ACQUIRED (${distance.toStringAsFixed(1)} px)" : "ALIGNING... (${distance.toStringAsFixed(1)} px OFF)",
                      style: TextStyle(
                        color: isAligned ? Colors.greenAccent : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- VIEW 2: Advanced "Precision Diagnostics" Mode ---
  Widget _buildPrecisionDiagnosticsView() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF1E293B), width: 2),
            ),
            child: LiveCameraStreamWidget(url: streamUrl),
          ),
        ),
        
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("// SPATIAL ALIGNMENT & METRICS", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(child: _buildHudCard("Offset DX", "${dx > 0 ? '+' : ''}$dx px", Icons.swap_horiz)),
                    SizedBox(width: 8),
                    Expanded(child: _buildHudCard("Offset DY", "${dy > 0 ? '+' : ''}$dy px", Icons.swap_vert)),
                    SizedBox(width: 8),
                    Expanded(child: _buildHudCard("Distance", "${distance.toStringAsFixed(1)} px", Icons.near_me, highlight: true)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildHudCard("D4σ Width X", "${d4sX.toStringAsFixed(1)} px", Icons.width_wide)),
                    SizedBox(width: 8),
                    Expanded(child: _buildHudCard("D4σ Width Y", "${d4sY.toStringAsFixed(1)} px", Icons.height)),
                    SizedBox(width: 8),
                    Expanded(child: _buildHudCard("Health (Hₖ)", "${healthScore.toStringAsFixed(3)}", Icons.health_and_safety)),
                  ],
                ),
                SizedBox(height: 8),
                
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Text("Radius (R): ${forbiddenRadius.toInt()} px", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: forbiddenRadius,
                          min: 5,
                          max: 100,
                          activeColor: Color(0xFF38BDF8),
                          inactiveColor: Color(0xFF334155),
                          onChanged: (val) => _updateForbiddenRadius(val),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHudCard(String label, String value, IconData icon, {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? Color(0xFF38bdf8).withOpacity(0.5) : Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: Color(0xFF64748B)),
              SizedBox(width: 4),
              Text(label, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w500)),
            ],
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: highlight ? Color(0xFF38bdf8) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// Dedicated Widget to fetch and stream individual JPEG frames efficiently via http bytes
class LiveCameraStreamWidget extends StatefulWidget {
  final String url;
  const LiveCameraStreamWidget({required this.url});

  @override
  _LiveCameraStreamWidgetState createState() => _LiveCameraStreamWidgetState();
}

class _LiveCameraStreamWidgetState extends State<LiveCameraStreamWidget> {
  Uint8List? _imageBytes;
  Timer? _timer;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(milliseconds: 33), (timer) async {
      try {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200 && mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _hasError = false;
          });
        } else {
          if (mounted) setState(() => _hasError = true);
        }
      } catch (e) {
        if (mounted) setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _imageBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageBytes == null 
                ? CircularProgressIndicator(color: Color(0xFF38bdf8), strokeWidth: 2)
                : Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 36),
            SizedBox(height: 8),
            Text(
              _imageBytes == null ? "Connecting to Backend..." : "Backend Offline", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}