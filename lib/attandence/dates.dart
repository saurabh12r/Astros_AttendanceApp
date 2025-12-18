import 'dart:ui';
import 'package:newastros/attandence/days.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DatesListPage extends StatefulWidget {
  final String month;
  const DatesListPage({super.key, required this.month});

  @override
  State<DatesListPage> createState() => _DatesListPageState();
}

class _DatesListPageState extends State<DatesListPage> {
  late DatabaseReference _dbRef;
  List<String> _dates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref('test/${widget.month}');
    _fetchDates();
  }

  Future<void> _fetchDates() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Sort dates chronologically before displaying
        final dateKeys =
            data.keys.cast<String>().where((key) => key != 'month').toList()
              ..sort((a, b) {
                try {
                  return int.parse(a).compareTo(int.parse(b));
                } catch (e) {
                  return a.compareTo(b); // Fallback for non-numeric date keys
                }
              });

        if (mounted) {
          setState(() {
            _dates = dateKeys;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _dates = [];
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

    // Helper for responsive font sizes
    double rfs(double fontSize) {
      return (fontSize * screenWidth / 390).clamp(
        fontSize * 0.85,
        fontSize * 1.4,
      );
    }

    // Define AppBar once to calculate its height
    final appBar = AppBar(
      title: Text(
        'Dates in ${widget.month}',
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
              : _dates.isEmpty
              ? Center(
                  child: Text(
                    'No dates found for ${widget.month}',
                    style: TextStyle(color: Colors.white, fontSize: rfs(16)),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: listTopPadding, // Responsive top padding
                    bottom: screenHeight * 0.02,
                  ),
                  itemCount: _dates.length,
                  itemBuilder: (context, index) {
                    final date = _dates[index];

                    // 3. APPLY RESPONSIVE FROSTED GLASS TO EACH ITEM
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
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              title: Text(
                                date,
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
                                    builder: (context) => EntriesListPage(
                                      month: widget.month,
                                      date: date,
                                    ),
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
