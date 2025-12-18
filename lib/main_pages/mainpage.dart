import 'dart:math' as math;
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:newastros/Results/results.dart';
import 'package:newastros/attandence/months.dart';
import 'package:newastros/login/auth_gate.dart';

// 🎨 Custom Painter (No changes)
class MultiColorRingPainter extends CustomPainter {
  final double strokeWidth;
  final List<Color> colors;

  MultiColorRingPainter({required this.strokeWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: colors,
    );

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AttendanceStatusWidget extends StatefulWidget {
  const AttendanceStatusWidget({super.key});

  @override
  State<AttendanceStatusWidget> createState() => _AttendanceStatusWidgetState();
}

class _AttendanceStatusWidgetState extends State<AttendanceStatusWidget> {
  // --- All your state variables and methods remain the same ---
  String? _storedPassword;
  String? _fetchedDate;
  String? _attendanceStatus;
  String? _userRole;

  final storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _noticeContent;
  final TextEditingController _noticeController = TextEditingController();
  final DatabaseReference _noticeRef =
      FirebaseDatabase.instance.ref("notice/content");

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      await storage.delete(key: 'PASSWORD');
      await storage.delete(key: 'EMAIL');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthGate()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to sign out: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _noticeRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          _noticeContent = event.snapshot.value.toString();
          _noticeController.text = _noticeContent ?? "";
        });
      }
    });
  }

  Future<void> _initializeData() async {
    String? password = await storage.read(key: 'PASSWORD');
    final dateRef = FirebaseDatabase.instance.ref('result/date');
    final dateSnapshot = await dateRef.get();
    final fetchedDate =
        dateSnapshot.exists ? dateSnapshot.value.toString() : null;

    setState(() {
      _storedPassword = password;
      _fetchedDate = fetchedDate;
    });

    if (_storedPassword != null && _fetchedDate != null) {
      await _fetchAttendanceStatus();
    } else {
      setState(() => _attendanceStatus = "No Data");
    }
    await _fetchUserRole();
  }

  Future<void> _fetchAttendanceStatus() async {
    if (_fetchedDate == null ||
        _storedPassword == null ||
        _fetchedDate == 'NoDate' ||
        _storedPassword == 'NoPassword') {
      setState(() => _attendanceStatus = 'Invalid Path');
      return;
    }
    try {
      final String dynamicPath = 'result/$_fetchedDate/$_storedPassword';
      final DatabaseReference statusRef =
          FirebaseDatabase.instance.ref(dynamicPath);
      final DataSnapshot statusSnapshot = await statusRef.get();
      if (statusSnapshot.exists) {
        final value = statusSnapshot.value;
        setState(() => _attendanceStatus = value.toString());
      } else {
        setState(() => _attendanceStatus = '0');
      }
    } catch (error) {
      setState(() => _attendanceStatus = 'Error');
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final ref = FirebaseDatabase.instance.ref("users/$_storedPassword/role");
      final snapshot = await ref.get();
      setState(() {
        _userRole = snapshot.exists ? snapshot.value.toString() : "user";
      });
    } catch (e) {
      setState(() => _userRole = "user");
    }
  }

  Future<void> _updateNotice() async {
    try {
      await _noticeRef.set(_noticeController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notice updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update notice: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Responsive setup remains the same ---
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double containerWidth = screenWidth * 0.85;
    final double containerHeight = screenHeight * 0.8;
    final double circleDiameter = screenWidth * 0.45;
    final double circleStrokeWidth = circleDiameter * 0.1;
    double rfs(double fontSize) {
      return (fontSize * screenWidth / 390).clamp(fontSize * 0.8, fontSize * 1.5);
    }

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'Assets/photos/img3.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: containerWidth,
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  // ✨ FIX 1: Wrap the Column with a SingleChildScrollView.
                  // This makes the content scrollable if it's too tall for the screen.
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: Column(
                        // ✨ FIX 2: Removed `mainAxisAlignment: spaceEvenly` and
                        // will use SizedBoxes for spacing.
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🔹 Attendance Circle
                          SizedBox(
                            width: circleDiameter,
                            height: circleDiameter,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CustomPaint(
                                    painter: MultiColorRingPainter(
                                      strokeWidth: circleStrokeWidth,
                                      colors: const [
                                        Color(0xFF18FFFF),
                                        Color(0xFF00D1FF),
                                        Color(0xFFB32AFF),
                                        Color(0xFF00D1FF),
                                        Color(0xFF18FFFF),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Month", style: TextStyle(
                                      decoration: TextDecoration.none,
                                      color: Colors.white70,
                                      fontSize: rfs(16),
                                      fontWeight: FontWeight.w500,
                                    )),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text("${_attendanceStatus ?? 'Loading...'} days",
                                      style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: Colors.white,
                                        fontSize: rfs(20),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Add spacing manually
                          SizedBox(height: screenHeight * 0.03),
                          // 🔹 Buttons Row
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(child: _buildButton(
                                  label: "Attendance",
                                  color: const Color.fromARGB(62, 180, 42, 255),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => MonthsListPage()))),
                                ),
                                Flexible(child: _buildButton(
                                  label: "Reports",
                                  color: const Color.fromARGB(62, 0, 208, 255),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => AttendanceReportPage()))),
                                ),
                                if (_userRole == "admin")
                                  Flexible(child: _buildButton(
                                    label: "Admin Panel",
                                    color: const Color.fromARGB(80, 255, 193, 7),
                                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Admin action clicked!"))))),
                                Flexible(child: _buildButton(
                                  label: "Logout",
                                  color: const Color.fromARGB(83, 24, 255, 255),
                                  onTap: _signOut,
                                )),
                              ],
                            ),
                          ),
                          // Add spacing manually
                          SizedBox(height: screenHeight * 0.03),
                          
                          // ✨ FIX 3: Removed the `Expanded` and inner `SingleChildScrollView` widget.
                          // The outer scroll view now handles everything.
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Notice Board", style: TextStyle(
                                    fontSize: rfs(18),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.none)),
                                SizedBox(height: screenHeight * 0.015),
                                if (_userRole == "admin")
                                  Column(
                                    children: [
                                      TextField(
                                        controller: _noticeController,
                                        maxLines: null,
                                        style: TextStyle(color: Colors.white, fontSize: rfs(14)),
                                        decoration: InputDecoration(
                                          hintText: "Write notice here...",
                                          hintStyle: TextStyle(
                                            color: Colors.white54, fontSize: rfs(14)),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.1),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ))),
                                      SizedBox(height: screenHeight * 0.015),
                                      ElevatedButton(
                                        onPressed: _updateNotice,
                                        child: Text("Update Notice", style: TextStyle(fontSize: rfs(14)))),
                                    ],
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      _noticeContent ?? "No notice available.",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: rfs(14),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildButton helper method remains the same ---
  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: screenHeight * 0.055,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: AutoSizeText(
              label,
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: (screenWidth / 390 * 14).clamp(10, 18),
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}