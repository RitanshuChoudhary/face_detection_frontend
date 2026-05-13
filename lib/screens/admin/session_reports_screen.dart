import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/loading_overlay.dart';

class SessionReportsScreen extends StatefulWidget {
  const SessionReportsScreen({super.key});

  @override
  State<SessionReportsScreen> createState() => _SessionReportsScreenState();
}

class _SessionReportsScreenState extends State<SessionReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchSessions();
    });
  }

  void _viewSessionDetails(dynamic session) async {
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    await attProv.fetchSessionReport(session.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadius)),
      ),
      builder: (context) {
        return Consumer<AttendanceProvider>(
          builder: (context, prov, child) {
            final report = prov.currentReport;
            final records = prov.sessionRecords;
            final int present = records.where((r) => r.status == 'present').length;
            final int absent = records.length - present;
            final String pct = records.isNotEmpty
                ? '${(present / records.length * 100).toStringAsFixed(1)}%'
                : '0%';

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return LoadingOverlay(
                  isLoading: prov.isLoading,
                  message: 'Generating exported file...',
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.subjectName,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    session.className,
                                    style: const TextStyle(color: AppConstants.textLight, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                pct,
                                style: const TextStyle(color: AppConstants.primary, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date: ${DateFormat('yMMMMd').add_jm().format(session.startTime)}',
                          style: const TextStyle(color: AppConstants.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 32),

                        // Stats counters Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('PRESENT', present, AppConstants.success),
                            _buildStatItem('ABSENT', absent, AppConstants.error),
                            _buildStatItem('TOTAL', records.length, AppConstants.textDark),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Download Export options
                        const Text('Export and Share Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildExportButton('PDF', Icons.picture_as_pdf, Colors.red, () async {
                              await prov.exportAndShareReport(session.id, 'pdf');
                            }),
                            const SizedBox(width: 12),
                            _buildExportButton('Excel', Icons.grid_on_rounded, Colors.green, () async {
                              await prov.exportAndShareReport(session.id, 'excel');
                            }),
                            const SizedBox(width: 12),
                            _buildExportButton('CSV', Icons.insert_drive_file_outlined, Colors.blue, () async {
                              await prov.exportAndShareReport(session.id, 'csv');
                            }),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Students presence summary list
                        const Text('Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final r = records[index];
                            final isPresent = r.status == 'present';
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.black.withOpacity(0.01),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isPresent ? AppConstants.success.withOpacity(0.1) : AppConstants.error.withOpacity(0.1),
                                  child: Icon(
                                    isPresent ? Icons.check : Icons.close,
                                    size: 16,
                                    color: isPresent ? AppConstants.success : AppConstants.error,
                                  ),
                                ),
                                title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('Roll: ${r.rollNumber}', style: const TextStyle(fontSize: 12)),
                                trailing: Text(
                                  isPresent ? 'PRESENT' : 'ABSENT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? AppConstants.success : AppConstants.error,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attProv = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports Center')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Previous Attendance Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: attProv.sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 48, color: AppConstants.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text('No attendance sessions found.', style: TextStyle(color: AppConstants.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: attProv.sessions.length,
                      itemBuilder: (context, index) {
                        final session = attProv.sessions[index];
                        final timeString = DateFormat('yMMMMd').add_jm().format(session.startTime);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primary.withOpacity(0.1),
                              child: const Icon(Icons.receipt_long, color: AppConstants.primary),
                            ),
                            title: Text(
                              session.subjectName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Class: ${session.className}\nStarted: $timeString'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () => _viewSessionDetails(session),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int val, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(val.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color == AppConstants.textDark ? null : color)),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
