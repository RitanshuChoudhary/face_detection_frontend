import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/attendance_provider.dart';
import '../../services/image_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  final ImageService _imageService = ImageService();
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _refreshReport();
  }

  void _startTimer() {
    final active = Provider.of<AttendanceProvider>(context, listen: false).activeSession;
    if (active != null) {
      _elapsed = DateTime.now().difference(active.startTime);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = _elapsed + const Duration(seconds: 1);
      });
    });
  }

  Future<void> _refreshReport() async {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    if (attProv.activeSession != null) {
      await attProv.fetchSessionReport(attProv.activeSession!.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Scan single student face
  Future<void> _scanSingleStudentFace() async {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    if (attProv.activeSession == null) return;

    final File? image = await _imageService.captureFromCamera();
    if (image == null) return;

    // Trigger api match
    final res = await attProv.markSingleFace(attProv.activeSession!.id, image);
    
    if (!mounted) return;

    if (res['matched'] == true) {
      final name = res['full_name'] ?? 'Student';
      final confidence = ((res['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppConstants.success, size: 28),
                SizedBox(width: 8),
                Text('Face Matched!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.success.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.person, color: AppConstants.success, size: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Student: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Roll No: ${res['roll_number'] ?? ''}'),
                Text('Confidence: $confidence%'),
                if (res['duplicate'] == true) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Already marked present!',
                    style: TextStyle(color: AppConstants.warning, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: AppConstants.error, size: 28),
                SizedBox(width: 8),
                Text('Match Failed', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(res['message'] ?? 'Could not recognize face in active student registry.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
      );
    }
  }

  // Scan entire classroom snapshot
  Future<void> _scanClassroomSnapshot() async {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    if (attProv.activeSession == null) return;

    final File? image = await _imageService.captureFromCamera();
    if (image == null) return;

    final res = await attProv.markClassroomGroup(attProv.activeSession!.id, image);
    
    if (!mounted) return;

    final detected = res['faces_detected'] ?? 0;
    final matched = res['matched_count'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.camera, color: AppConstants.primary, size: 28),
              SizedBox(width: 8),
              Text('Classroom Results', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Faces Detected in Snapshot: $detected', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Students Verified and Marked: $matched', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.success)),
              const SizedBox(height: 12),
              const Text('The students roster has been successfully updated.', style: TextStyle(fontSize: 13, color: AppConstants.textLight)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attProv = Provider.of<AttendanceProvider>(context);
    final active = attProv.activeSession;

    final records = attProv.sessionRecords;
    final int total = records.length;
    final int present = records.where((r) => r.status == 'present').length;
    final int absent = total - present;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReport,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: attProv.isLoading,
        message: 'Analyzing facial features with AI...',
        child: Column(
          children: [
            // Header Session Info & Timer Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.cardColorDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    active?.subjectName ?? 'Attendance Session',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    active?.className ?? 'Classroom',
                    style: const TextStyle(color: AppConstants.textLight, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Elapsed Session Timer Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, color: AppConstants.primary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Counts metrics row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniCount('PRESENT', present, AppConstants.success),
                      _buildVerticalDivider(isDark),
                      _buildMiniCount('ABSENT', absent, AppConstants.error),
                      _buildVerticalDivider(isDark),
                      _buildMiniCount('TOTAL', total, AppConstants.textDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Camera Trigger Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.person, size: 20),
                      label: const Text('Scan Single'),
                      onPressed: _scanSingleStudentFace,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.group, size: 20),
                      label: const Text('Scan Room'),
                      onPressed: _scanClassroomSnapshot,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Students attendance manual override list view
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Presence Roster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: records.isEmpty
                          ? const Center(child: Text('No students assigned to this classroom.', style: TextStyle(color: AppConstants.textLight)))
                          : ListView.builder(
                              itemCount: records.length,
                              itemBuilder: (context, idx) {
                                final r = records[idx];
                                final isPresent = r.status == 'present';
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPresent ? AppConstants.success.withOpacity(0.12) : AppConstants.error.withOpacity(0.12),
                                      child: Icon(
                                        isPresent ? Icons.check : Icons.close,
                                        color: isPresent ? AppConstants.success : AppConstants.error,
                                      ),
                                    ),
                                    title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Roll No: ${r.rollNumber}'),
                                    trailing: Switch(
                                      activeColor: AppConstants.success,
                                      value: isPresent,
                                      onChanged: (val) async {
                                        final targetStatus = val ? 'present' : 'absent';
                                        await attProv.markManualOverride(r.studentId, active!.id, targetStatus);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // End Session control button
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: CustomButton(
                text: 'End and Close Session',
                color: AppConstants.error,
                onPressed: () async {
                  final ok = await attProv.endActiveSession();
                  if (ok && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attendance session completed & saved!'), backgroundColor: AppConstants.success),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 35,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black12,
    );
  }

  Widget _buildMiniCount(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          val.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color == AppConstants.textDark ? null : color),
        ),
      ],
    );
  }
}
