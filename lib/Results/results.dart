import 'dart:ui'; // Required for ImageFilter
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Data model for clarity
class UserAttendance {
  final String month;
  final int count;
  UserAttendance({required this.month, required this.count});
}

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});
  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  final storage = const FlutterSecureStorage();
  String? _userId;
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdFromStorage();
  }

  Future<void> _loadUserIdFromStorage() async {
    final id = await storage.read(key: 'PASSWORD');
    if (mounted) {
      setState(() {
        _userId = id;
        _isLoadingId = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 🚀 RESPONSIVE SETUP 🚀 ---
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Helper for responsive font sizes
    double rfs(double fontSize) {
      return (fontSize * screenWidth / 390).clamp(
        fontSize * 0.85,
        fontSize * 1.4,
      );
    }

    // Define the AppBar to calculate its height for padding later
    final appBar = AppBar(
      title: Text(
        'Monthly Attendance Report',
        style: TextStyle(fontSize: rfs(20), fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE (Unchanged)
          Image.asset(
            'Assets/photos/img4.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // 2. YOUR CONTENT BODY
          _buildBody(appBar), // Pass appBar to calculate padding
        ],
      ),
      // --- ✨ ADDED FLOATING ACTION BUTTON ✨ ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // The StreamBuilder is already listening for live updates.
          // This button provides user feedback that a check is happening.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checking for latest updates...'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // You can optionally force a state rebuild if other logic requires it.
          setState(() {});
        },
        tooltip: 'Refresh Data',
        backgroundColor: Colors.black.withOpacity(
          0.4,
        ), // Style to match the theme
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody(AppBar appBar) {
    // --- 🚀 RESPONSIVE SETUP for the body content 🚀 ---
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final topSafeArea = MediaQuery.of(context).padding.top;

    // Calculate padding to place content correctly below the transparent AppBar
    final listTopPadding = appBar.preferredSize.height + topSafeArea + 10;

    // Helper for responsive font sizes
    double rfs(double fontSize) {
      return (fontSize * screenWidth / 390).clamp(
        fontSize * 0.85,
        fontSize * 1.4,
      );
    }

    if (_isLoadingId) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing
            Text(
              "Loading user data...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: rfs(14),
              ), // Responsive font
            ),
          ],
        ),
      );
    }
    if (_userId == null) {
      return Center(
        child: Text(
          "User ID not found in storage.",
          style: TextStyle(
            color: Colors.white,
            fontSize: rfs(16),
          ), // Responsive font
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('result').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Stream Error: ${snapshot.error}",
              style: TextStyle(color: Colors.yellow, fontSize: rfs(16)),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Text(
              "No data found.",
              style: TextStyle(color: Colors.white70, fontSize: rfs(16)),
            ),
          );
        }

        final allData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final List<UserAttendance> userAttendanceList = [];

        allData.forEach((monthKey, monthData) {
          if (monthData is Map && monthData.containsKey(_userId)) {
            final dynamic rawCount = monthData[_userId];
            int count = int.tryParse(rawCount.toString()) ?? 0;
            userAttendanceList.add(
              UserAttendance(
                month: monthKey.replaceAll('_', ' '),
                count: count,
              ),
            );
          }
        });

        if (userAttendanceList.isEmpty) {
          return Center(
            child: Text(
              "No attendance records found for this user.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: rfs(16),
              ), // Responsive font
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: listTopPadding,
            bottom: screenHeight * 0.1,
          ), // Adjusted bottom padding for FAB
          itemCount: userAttendanceList.length,
          itemBuilder: (context, index) {
            final attendance = userAttendanceList[index];
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // Responsive padding
                vertical: screenHeight * 0.007, // Responsive padding
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  screenWidth * 0.04,
                ), // Responsive radius
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        screenWidth * 0.04,
                      ), // Responsive radius
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                      ),
                      title: Text(
                        "Month: ${attendance.month}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: rfs(18), // Responsive font
                          color: Colors.white,
                        ),
                      ),
                      trailing: Text(
                        "${attendance.count} Days",
                        style: TextStyle(
                          fontSize: rfs(16), // Responsive font
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
