import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/shimmer_loading.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchTrackingData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtered items based on search query
    final filteredTeachers = adminProv.trackedTeachers.where((teacher) {
      final name = (teacher['full_name'] ?? "").toString().toLowerCase();
      final email = (teacher['email'] ?? "").toString().toLowerCase();
      final className = (teacher['class_name'] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          className.contains(_searchQuery);
    }).toList();

    final filteredClasses = adminProv.trackedClasses.where((cls) {
      final name = (cls['class_name'] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking Hub'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.badge_outlined), text: 'Teachers Status'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Classes Performance'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: adminProv.isLoading,
        message: 'Synchronizing school metrics...',
        child: Column(
          children: [
            // Search Bar Area
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.cardColorDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search teachers, emails, or classes...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppConstants.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: () => adminProv.fetchTrackingData(),
                    child: adminProv.isTrackingLoading
                        ? ListView.builder(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingLarge,
                            ),
                            itemCount: 4,
                            itemBuilder: (context, index) =>
                                const ShimmerCardSkeleton(),
                          )
                        : filteredTeachers.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.person_off_outlined,
                            title: 'No teachers found',
                            subtitle:
                                'Ensure teachers are assigned classes in the Directory.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingLarge,
                            ),
                            itemCount: filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final item = filteredTeachers[index];
                              final classId = item['class_id'];
                              final className =
                                  item['class_name'] ?? 'Unassigned';
                              final section = item['section'] ?? '';
                              final sessions = item['sessions_conducted'] ?? 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Circle Avatar with initials
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppConstants.primary
                                            .withOpacity(0.1),
                                        child: Text(
                                          (item['full_name'] ?? 'T')[0]
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: AppConstants.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Main Text Fields
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['full_name'] ?? 'Professor',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['email'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Badges row
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                // Classroom Badge
                                                Chip(
                                                  labelPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: -4,
                                                      ),
                                                  avatar: const Icon(
                                                    Icons.school,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    classId != null
                                                        ? '$className - $section'
                                                        : 'Unassigned Class',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      classId != null
                                                      ? AppConstants.primary
                                                      : Colors.grey,
                                                ),
                                                // Sessions Conducted Badge
                                                Chip(
                                                  labelPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: -4,
                                                      ),
                                                  avatar: const Icon(
                                                    Icons.event_note,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    '$sessions Lectures',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      AppConstants.success,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Tab 2: Classes Performance metrics
                  RefreshIndicator(
                    onRefresh: () => adminProv.fetchTrackingData(),
                    child: adminProv.isTrackingLoading
                        ? ListView.builder(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingLarge,
                            ),
                            itemCount: 4,
                            itemBuilder: (context, index) =>
                                const ShimmerCardSkeleton(),
                          )
                        : filteredClasses.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.school_outlined,
                            title: 'No classes discovered',
                            subtitle:
                                'Register classes to monitor tracking summaries.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingLarge,
                            ),
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) {
                              final item = filteredClasses[index];
                              final className = item['class_name'] ?? '';
                              final section = item['section'] ?? '';
                              final studentCount = item['student_count'] ?? 0;
                              final attendancePercentage =
                                  (item['today_attendance_percentage'] ?? 0.0)
                                      as double;
                              final teachers =
                                  item['teachers'] as List<dynamic>? ?? [];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$className ($section)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$studentCount Registered Students',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Circle Attendance percentage
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: attendancePercentage >= 80
                                                  ? AppConstants.success
                                                        .withOpacity(0.1)
                                                  : (attendancePercentage >= 50
                                                        ? AppConstants.warning
                                                              .withOpacity(0.1)
                                                        : Colors.red
                                                              .withOpacity(
                                                                0.1,
                                                              )),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${attendancePercentage.toStringAsFixed(1)}% Present',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    attendancePercentage >= 80
                                                    ? AppConstants.success
                                                    : (attendancePercentage >=
                                                              50
                                                          ? AppConstants.warning
                                                          : Colors.red),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      // Assigned Teachers List
                                      const Text(
                                        'Assigned Instructors:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppConstants.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      teachers.isEmpty
                                          ? const Text(
                                              'None assigned',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: teachers.map((teacher) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.grey[800]
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.person,
                                                        size: 12,
                                                        color: AppConstants
                                                            .primary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        teacher['full_name'] ??
                                                            '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppConstants.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
