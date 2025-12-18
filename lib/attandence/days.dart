import 'dart:ui'; // Required for ImageFilter
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// The data model remains the same
class AttendanceEntry {
  final String time;
  final String id;
  String? name; // Name is nullable as it will be fetched separately

  AttendanceEntry({required this.time, required this.id, this.name});
}

class EntriesListPage extends StatefulWidget {
  final String month;
  final String date;
  const EntriesListPage({super.key, required this.month, required this.date});

  @override
  State<EntriesListPage> createState() => _EntriesListPageState();
}

class _EntriesListPageState extends State<EntriesListPage> {
  late DatabaseReference _dbRef;
  List<AttendanceEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref(
      'test/${widget.month}/${widget.date}',
    );
    _fetchEntriesAndNames();
  }

  Future<void> _fetchEntriesAndNames() async {
    try {
      final attendanceSnapshot = await _dbRef.get();
      if (!attendanceSnapshot.exists) {
        if (mounted) {
          setState(() {
            _entries = [];
            _isLoading = false;
          });
        }
        return;
      }

      final data = attendanceSnapshot.value as Map<dynamic, dynamic>;
      final List<AttendanceEntry> tempEntries = [];
      data.forEach((key, value) {
        if (value is Map && key != 'date') {
          tempEntries.add(
            AttendanceEntry(
              time: value['time']?.toString() ?? 'No Time',
              id: value['id']?.toString() ?? 'No ID',
            ),
          );
        }
      });

      // Fetch names for each entry
      final membersRef = FirebaseDatabase.instance.ref('Members');
      for (var entry in tempEntries) {
        if (entry.id != 'No ID') {
          final nameSnapshot = await membersRef
              .child(entry.id)
              .child('name')
              .get();
          if (nameSnapshot.exists) {
            entry.name = nameSnapshot.value.toString();
          } else {
            entry.name = 'Unknown Member';
          }
        } else {
          entry.name = 'Invalid ID';
        }
      }

      if (mounted) {
        setState(() {
          _entries = tempEntries;
          _isLoading = false;
        });
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
        'Entries for ${widget.date}',
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
              : _entries.isEmpty
              ? Center(
                  child: Text(
                    'No entries found for this date.',
                    style: TextStyle(color: Colors.white70, fontSize: rfs(16)),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: listTopPadding, // Responsive top padding
                    bottom: screenHeight * 0.02,
                  ),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];

                    // 3. APPLY RESPONSIVE FROSTED GLASS TO EACH ITEM
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
                                Icons.person_pin_circle_outlined,
                                color: Colors.white,
                              ),
                              title: Text(
                                entry.name ?? 'Loading name...',
                                style: TextStyle(
                                  fontSize: rfs(18), // Responsive font
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                'Time: ${entry.time}',
                                style: TextStyle(
                                  fontSize: rfs(14), // Responsive font
                                  color: Colors.white70,
                                ),
                              ),
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
