import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../widgets/status_card.dart';
import '../auth/login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final APIService _api = APIService();
  bool _isLoading = false;
  Map<String, dynamic>? _attendanceData;

  // Self marking input controllers
  final TextEditingController _leaveReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMyAttendance();
  }

  @override
  void dispose() {
    _leaveReasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/students/me/attendance');
      if (response.statusCode == 200) {
        setState(() {
          _attendanceData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Handle fail quietly
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitSelfMark({required String status, String? reason, File? file}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.uploadMultipart(
        '/attendance/student-self-mark',
        {
          'status': status,
          if (reason != null && reason.isNotEmpty) 'leave_reason': reason,
        },
        file: file,
        fieldName: 'file',
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('Attendance successfully marked as $status!'),
              ],
            ),
            backgroundColor: AppConstants.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchMyAttendance();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(err['detail'] ?? 'Self-marking failed.')),
              ],
            ),
            backgroundColor: AppConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Check connection.'),
            backgroundColor: AppConstants.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsPresent() async {
    final file = await ImageService().captureFromCamera();
    if (file == null) return;
    _submitSelfMark(status: 'present', file: file);
  }

  void _confirmMarkAbsent() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Self-Report Absent', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to self-report as absent for today?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                _submitSelfMark(status: 'absent');
              },
              child: const Text('Report Absent'),
            ),
          ],
        );
      }
    );
  }

  void _openSelfMarkingSheet() {
    bool showLeaveInput = false;
    _leaveReasonController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppConstants.paddingLarge,
                right: AppConstants.paddingLarge,
                top: AppConstants.paddingLarge,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.paddingLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mark Classroom Attendance',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Verification Window: 09:00 AM - 10:00 AM Daily',
                    style: TextStyle(color: AppConstants.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Option 1: Mark Present
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _markAsPresent();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.success.withOpacity(0.08),
                        border: Border.all(color: AppConstants.success.withOpacity(0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppConstants.success.withOpacity(0.2),
                            child: const Icon(Icons.camera_alt, color: AppConstants.success),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Mark Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.success)),
                                SizedBox(height: 4),
                                Text('Requires raw camera face verification', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppConstants.success),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 2: Apply Leave
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withOpacity(0.08),
                      border: Border.all(color: AppConstants.primary.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              showLeaveInput = !showLeaveInput;
                            });
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppConstants.primary.withOpacity(0.2),
                                child: const Icon(Icons.time_to_leave, color: AppConstants.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Register Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primary)),
                                    SizedBox(height: 4),
                                    Text('File a leave justification note', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Icon(showLeaveInput ? Icons.keyboard_arrow_down : Icons.chevron_right, color: AppConstants.primary),
                            ],
                          ),
                        ),
                        if (showLeaveInput) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _leaveReasonController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Enter reason for leave (e.g. medical reason)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              backgroundColor: AppConstants.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_leaveReasonController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a leave reason!'), backgroundColor: AppConstants.warning),
                                );
                                return;
                              }
                              Navigator.pop(context);
                              _submitSelfMark(status: 'leave', reason: _leaveReasonController.text.trim());
                            },
                            child: const Text('Submit Leave Application', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 3: Mark Absent
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _confirmMarkAbsent();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.error.withOpacity(0.08),
                        border: Border.all(color: AppConstants.error.withOpacity(0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppConstants.error.withOpacity(0.2),
                            child: const Icon(Icons.cancel, color: AppConstants.error),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Mark Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.error)),
                                SizedBox(height: 4),
                                Text('Self-report absent status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppConstants.error),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProv = Provider.of<AuthProvider>(context);

    // Parse counts
    final int total = _attendanceData?['total_sessions'] ?? 0;
    final int present = _attendanceData?['present_count'] ?? 0;
    final int absent = _attendanceData?['absent_count'] ?? 0;
    final double percentage = (_attendanceData?['attendance_percentage'] ?? 0.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProv.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyAttendance,
        child: _isLoading && _attendanceData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile card
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppConstants.primary.withOpacity(0.12),
                          child: const Icon(Icons.face, color: AppConstants.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProv.currentUser?.name ?? 'Student Name',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Roll No: ${_attendanceData?['roll_number'] ?? 'Loading...'}',
                              style: const TextStyle(color: AppConstants.textLight, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Attendance circular card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overall Attendance',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textLight),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppConstants.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    percentage >= 75.0
                                        ? 'Meeting eligibility criteria'
                                        : 'Low attendance alert (below 75.0%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: percentage >= 75.0 ? AppConstants.success : AppConstants.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: Stack(
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CircularProgressIndicator(
                                        value: total > 0 ? (present / total) : 0,
                                        strokeWidth: 9,
                                        backgroundColor: AppConstants.primary.withOpacity(0.1),
                                        color: percentage >= 75.0 ? AppConstants.success : AppConstants.error,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.emoji_events_outlined,
                                      color: percentage >= 75.0 ? AppConstants.success : AppConstants.error,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Self Marking Desk Panel
                    Card(
                      elevation: 4,
                      shadowColor: AppConstants.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        side: const BorderSide(color: AppConstants.primary, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppConstants.primary.withOpacity(0.1),
                                  child: const Icon(Icons.today, color: AppConstants.primary),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Daily Attendance Desk',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Mark your classroom attendance or request leave directly from your portal.',
                              style: TextStyle(fontSize: 13, color: AppConstants.textLight, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: const Text('Mark Today Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: _openSelfMarkingSheet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metrics Grid Row
                    Row(
                      children: [
                        Expanded(
                          child: StatusCard(
                            title: 'Present Days',
                            value: present.toString(),
                            icon: Icons.check_circle_outline,
                            color: AppConstants.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatusCard(
                            title: 'Absent Days',
                            value: absent.toString(),
                            icon: Icons.cancel_outlined,
                            color: AppConstants.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StatusCard(
                      title: 'Total Tracked Sessions',
                      value: total.toString(),
                      icon: Icons.analytics_outlined,
                      color: AppConstants.primary,
                    ),
                    const SizedBox(height: 32),

                    // Facial security status banner
                    const Text('Verification Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.padding),
                      decoration: BoxDecoration(
                        color: AppConstants.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppConstants.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: AppConstants.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'AI Facial Recognition',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your classroom attendance is verified in real-time via camera matching. Ensure your face templates are updated by your class teacher.',
                                  style: TextStyle(fontSize: 12, color: AppConstants.textLight, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
