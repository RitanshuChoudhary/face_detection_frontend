import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/status_card.dart';
import '../attendance/live_session_screen.dart';
import 'manage_teachers_screen.dart';
import 'manage_classes_screen.dart';
import 'manage_subjects_screen.dart';
import 'manage_students_screen.dart';
import 'session_reports_screen.dart';
import 'admin_tracking_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _selectedClassId;
  int? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    
    await adminProv.fetchDashboardStats();
    await adminProv.fetchClasses();
    await adminProv.fetchSubjects();
    await attProv.fetchSessions(activeOnly: true);
  }

  void _triggerStartSession() {
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    if (adminProv.classes.isEmpty || adminProv.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register Classes and Subjects first!')),
      );
      return;
    }

    _selectedClassId = adminProv.classes.first.id;
    _selectedSubjectId = adminProv.subjects.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final classes = adminProv.classes;
            final subjects = adminProv.subjects;

            return Padding(
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
                        'Launch Attendance Session',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Class Dropdown
                  const Text('Select Classroom', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                    items: classes.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) {
                      setModalState(() => _selectedClassId = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Subject Dropdown
                  const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                    items: subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.code})'),
                    )).toList(),
                    onChanged: (val) {
                      setModalState(() => _selectedSubjectId = val);
                    },
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      if (_selectedClassId == null || _selectedSubjectId == null) return;
                      
                      Navigator.pop(context); // Close sheet
                      
                      final attProv = Provider.of<AttendanceProvider>(context, listen: false);
                      final ok = await attProv.startSession(_selectedClassId!, _selectedSubjectId!);
                      if (ok && mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LiveSessionScreen()),
                        );
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(attProv.errorMessage ?? 'Failed to start session')),
                          );
                        }
                      }
                    },
                    child: const Text('Start Live Attendance Session'),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProv = Provider.of<AuthProvider>(context);
    final adminProv = Provider.of<AdminProvider>(context);
    final attProv = Provider.of<AttendanceProvider>(context);

    final stats = adminProv.dashboardStats;
    final String studentCount = (stats['total_students'] ?? 0).toString();
    final String teacherCount = (stats['total_teachers'] ?? 0).toString();
    final String classCount = (stats['total_classes'] ?? 0).toString();
    final String avgAttendance = '${(stats['average_attendance_percentage'] ?? 0.0).toStringAsFixed(1)}%';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppConstants.primary.withOpacity(0.15),
                    child: const Icon(Icons.school, color: AppConstants.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${authProv.currentUser?.name ?? 'Teacher'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Role: ${authProv.currentUser?.role.toUpperCase() ?? 'TEACHER'}',
                        style: const TextStyle(fontSize: 13, color: AppConstants.textLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Active Session Alert Card (If running)
              if (attProv.activeSession != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppConstants.primary, AppConstants.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Session Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Class: ${attProv.activeSession?.className ?? ''} • Sub: ${attProv.activeSession?.subjectName ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const LiveSessionScreen()),
                          );
                        },
                        child: const Text('Resume'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Main Stats Overview Chart & Metrics Row
              Text(
                'Attendance Analytics',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              
              // Analytics circular display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Attendance Rate',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.textLight),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              avgAttendance,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Target Benchmark: 85.0%',
                              style: TextStyle(fontSize: 12, color: AppConstants.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Custom Circle Progress
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
                                  value: (stats['average_attendance_percentage'] ?? 0.0) / 100.0,
                                  strokeWidth: 10,
                                  backgroundColor: AppConstants.primary.withOpacity(0.1),
                                  color: AppConstants.primary,
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.trending_up,
                                color: AppConstants.primary,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Cards Grid
              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      title: 'Total Students',
                      value: studentCount,
                      icon: Icons.people,
                      color: AppConstants.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatusCard(
                      title: 'Registered Classes',
                      value: classCount,
                      icon: Icons.class_outlined,
                      color: AppConstants.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      title: 'Staff Faculty',
                      value: teacherCount,
                      icon: Icons.person_add_alt_1,
                      color: AppConstants.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatusCard(
                      title: 'Today Sessions',
                      value: (stats['today_sessions'] ?? 0).toString(),
                      icon: Icons.calendar_today,
                      color: AppConstants.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Interactive Navigation Center
              Text(
                'Management Center',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              
              // Menu Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildMenuCard(
                    context,
                    title: 'Live Session',
                    icon: Icons.add_circle,
                    color: AppConstants.primary,
                    onTap: _triggerStartSession,
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Students & Faces',
                    icon: Icons.face,
                    color: AppConstants.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageStudentsScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Classes List',
                    icon: Icons.home_work_outlined,
                    color: AppConstants.success,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageClassesScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Subjects List',
                    icon: Icons.book_outlined,
                    color: AppConstants.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Teachers Directory',
                    icon: Icons.badge,
                    color: Colors.purple,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Logs & Exports',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SessionReportsScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    title: 'Live Tracking Hub',
                    icon: Icons.analytics,
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminTrackingScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
