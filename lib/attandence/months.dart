import 'dart:ui'; // Required for ImageFilter
import 'package:newastros/attandence/dates.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MonthsListPage extends StatefulWidget {
  const MonthsListPage({super.key});

  @override
  State<MonthsListPage> createState() => _MonthsListPageState();
}

class _MonthsListPageState extends State<MonthsListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('test');
  List<String> _months = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonths();
  }

  Future<void> _fetchMonths() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            _months = data.keys.cast<String>().toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _months = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 🚀 RESPONSIVE SETUP 🚀 ---
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final topSafeArea = MediaQuery.of(context).padding.top;

    // Helper for responsive font sizes, clamped to avoid extreme sizes
    double rfs(double fontSize) {
      // 390 is a common reference screen width for scaling.
      return (fontSize * screenWidth / 390).clamp(
        fontSize * 0.85,
        fontSize * 1.4,
      );
    }

    // Define AppBar once to calculate its height for dynamic padding
    final appBar = AppBar(
      title: Text(
        'Select a Month',
        style: TextStyle(fontSize: rfs(20), fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      elevation: 0,
    );

    // Calculate padding to place content correctly below the transparent AppBar
    final listTopPadding = appBar.preferredSize.height + topSafeArea + 10;

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

          // 2. YOUR CONTENT
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _months.isEmpty
              ? Center(
                  child: Text(
                    'No months found.',
                    style: TextStyle(color: Colors.white70, fontSize: rfs(16)),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: listTopPadding, // Responsive top padding
                    bottom: screenHeight * 0.02,
                  ),
                  itemCount: _months.length,
                  itemBuilder: (context, index) {
                    final month = _months[index];

                    // 3. RESPONSIVE FROSTED GLASS ITEM WIDGET
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            screenWidth * 0.04, // Responsive horizontal padding
                        vertical:
                            screenHeight * 0.007, // Responsive vertical padding
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
                                month,
                                style: TextStyle(
                                  fontSize: rfs(18), // Responsive font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white70,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DatesListPage(month: month),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
